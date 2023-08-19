defmodule ElixirISO8583.Parse do

  @type bitmap_pos() :: 1..128

  def parse_msg(message, scheme, iso_spec_config) do

    # validate ISO spec config

    with {:ok, list_of_elements, data_sections} <- parse_bmp(scheme, message),
         {:ok, iso_element_specs} <- get_and_validate_iso_element_spec(list_of_elements, iso_spec_config) do

      parse_elements(data_sections, scheme, iso_element_specs)
    else
      err -> err
    end

  end

  def parse_elements(data_sections, scheme, iso_element_specs) do
    parse_element(:ok, nil, {data_sections, scheme, iso_element_specs}, %{})
  end

  def parse_element(:error, parse_status, _parse_input, _parsed_elements) do
    {:error, parse_status}
  end

  def parse_element(:ok, _parse_status, {_data_sections, _scheme, []}, parsed_elements) do
    {:ok, parsed_elements} # return the parsed msg
  end

  def parse_element(:ok, _parse_status, {data_sections, scheme, iso_element_specs}, parsed_elements) do
    [{element_pos, head_size, data_type, max} | rest_of_iso_element_specs] = iso_element_specs

    parse_result =
      with {:ok, data, rest_of_data_sections} <- field(data_sections, scheme, head_size, data_type, max) do

        {:ok, nil, Map.put(parsed_elements, element_pos, data), rest_of_data_sections}

      else
        {:error, status_detail} ->
          {:error, status_detail, %{}, nil}
      end

    {parse_status, parse_detail, parsed_elements, rest_of_data_sections} = parse_result

    parse_element(parse_status, parse_detail, {rest_of_data_sections, scheme, rest_of_iso_element_specs}, parsed_elements) # call itself with the next list of field spec

  end

  def field(msg, scheme, head_size, data_type, max)
    when head_size in [0, 1, 2, 3, 4] do

    with {:ok, data_length, rest} <- head(msg, scheme, head_size) do
      data_length = data_length(data_length, max) # either use head size of fixed length (use max)
      parse_body_result = body(rest, scheme, data_type, data_length) # get body value
      parse_body_result
    else
      error -> error
    end

  end

  def field(_msg, _scheme, head_size, _data_type, _max) do
    {:error, "Invalid head size, expected 0-4 but having #{head_size}"}
  end

  # binary head
  def head(<<a::4, b::4, rest::binary>>, :bin, 2) # 2 digits is 1 byte, each number represented with half byte
    when a >= 0 and a <= 9 and b >= 0 and b <= 9 do
    data_length = a*10 + b
    {:ok, data_length, rest}
  end

  def head(<<a::4, b::4, rest::binary>>, :bin, 2) do
    {:error, "Invalid binary header format, expected first and second nibble between 0-9 found a = #{a} and b = #{b}"}
  end

  def head(<<a::4, b::4, c::4, d::4, rest::binary>>, :bin, 3) # 3 digits is 2 bytes, first nible is ignored
    when b >= 0 and b <= 9 and c >= 0 and c <= 9 and d >= 0 and d <= 9 do

      if a > 0 do
        {:error, "Error: Invalid header format, the first nibble value should be 0, found #{a}"}
      else
        data_length = b*100 + c*10 + d
        {:ok, data_length, rest}
      end

  end

  def head(<<a::4, b::4, c::4, d::4, rest::binary>>, :bin, 3) do
    {:error, "Invalid binary header format, expected first and second and third nibble between 0-9 found b = #{b} and c = #{c} and d = #{d}"}
  end

  # ascii head
  def head(<<_::4, a::4, _::4, b::4, rest::binary>>, :ascii, 2) # 2 digits is 2 bytes, each number represented with 1 byte, ignore the first nible for each byte (refer to ASCII spec)
    when a >= 0 and a <= 9 and b >= 0 and b <= 9 do
    data_length = a*10 + b
    {:ok, data_length, rest}
  end

  def head(<<_::4, a::4, _::4, b::4, rest::binary>>, :ascii, 2) do
    {:error, "Invalid binary header format, expected first and second nibble between 0-9 found a = #{a} and b = #{b}"}
  end

  def head(<<_::4, a::4, _::4, b::4, _::4, c::4, rest::binary>>, :ascii, 3) # 3 digits is 3 bytes
    when a >= 0 and a <= 9 and b >= 0 and b <= 9 and c >= 0 and c <= 9 do
    data_length = a*100 + b*10 + c
    {:ok, data_length, rest}
  end

  def head(<<_::4, a::4, _::4, b::4, _::4, c::4, rest::binary>>, :ascii, 3) do
    {:error, "Invalid binary header format, expected first and second and third nibble between 0-9 found a = #{a} and b = #{b} and c = #{c}"}
  end

  def head(msg, _scheme, 0) do # 0 if fixed length
    {:ok, 0, msg}
  end

  ## parse body
  def body(msg, _scheme, _data_type = :alphanum, data_length)
    when byte_size(msg) >= data_length do # alphanum always 1 byte for any scheme

    <<data::binary-size(data_length), rest::binary>> = msg

    {:ok, data, rest}
  end

  def body(msg, _scheme, _data_type = :alphanum, data_length) when byte_size(msg) < data_length do
    {:error, {:insufficient_data, "Insufficient data to parse, required: #{data_length}, available data: #{byte_size(msg)}", msg}}
  end

  def body(msg, _scheme = :bin, data_type, data_length)
    when byte_size(msg) >= div(data_length + rem(data_length, 2), 2) and data_type in [:num, :z] do

    byte_length = data_length + rem(data_length, 2) |> div(2)

    <<data::binary-size(byte_length), rest::binary>> = msg
    data = Base.encode16(data) |> truncate(data_length)

    {:ok, data, rest}
  end

  def body(msg, _scheme = :bin, _data_type = :b, data_length)
    when byte_size(msg) >= data_length do # scheme binary, binary data represented as raw binary
    <<data::binary-size(data_length), rest::binary>> = msg
    {:ok, data, rest}
  end

  def body(msg, _scheme = :ascii, data_type, data_length)
    when byte_size(msg) >= data_length # scheme ascii, numeric and track2 for each digit is represented with 1 byte
    and data_type in [:num, :z] do

    <<data::binary-size(data_length), rest::binary>> = msg
    {:ok, data, rest}
  end

  def body(msg, _scheme = :ascii, _data_type = :b, data_length)
    when byte_size(msg) >= data_length*2 do # scheme ascii, binary data represented as hex in ascii

    data_length = data_length*2

    <<data::binary-size(data_length), rest::binary>> = msg
    data = Base.decode16!(data)
    {:ok, data, rest}
  end

  def body(msg, _scheme = :ascii, _data_type = :br, data_length)
    when byte_size(msg) >= data_length do # scheme ascii, raw binary data represented as raw binary

    data_length = data_length

    <<data::binary-size(data_length), rest::binary>> = msg
    {:ok, data, rest}
  end

  def body(_msg, _scheme, _data_type, _data_length) do
    {:error, :general_error, "Failed to parse ISO message"}
  end

  # utilities
  def truncate(data, max) when byte_size(data) > max do
    <<data::binary-size(max), _::binary>> = data
    data
  end

  def truncate(data, _max) do
    data
  end

  def data_length(0, max_length) do
    max_length
  end

  def data_length(data_length, _) do
    data_length
  end



  @doc """
  Parse the bitmap according to the encoding scheme which is binary (the bitmap represented as 8 byte if the first bit is not set or 16 byte if the first bit is set)
  or ascii (the bitmap represented as 16 byte if the first bit is not set or 32 byte if the first bit is set).

  For the ascii encoding scheme, each 4 bit is represented as an ascii character in hex (between '0' to 'F')

  Returns `{:ok, list}` if the bitmap is valid

  ## Examples

      iex> ElixirISO8583.Parse.parse_bmp("58020C0001C00400000000000072800062600220132003838353032393032303030303031303238393032393034003330313A50313A3030303532353A563A30313033353439303030373238303130363D002630323A3030303030303030303732383A303137373437343730330006303030303031")
      {:ok, "58020C0001C00400000000000072800062600220132003838353032393032303030303031303238393032393034003330313A50313A3030303532353A563A30313033353439303030373238303130363D002630323A3030303030303030303732383A303137373437343730330006303030303031"}

  """
  def parse_bmp(:ascii, msg = <<first_char::8, _rest::binary>>)
    when first_char > ?0 and first_char < ?8 do # if the first bit is not set, the message only contains first bmp

    <<bitmap::binary-size(16), data_sections::binary>> = msg

    if String.match?(bitmap, ~r/^[0-9A-F]{16}$/) == true do
      <<_::1, bmp::63>> = Base.decode16!(bitmap)
      list_of_elements = bitmap_to_list(<<0::1, bmp::63>>)
      {:ok, list_of_elements, data_sections}
    else
      {:error, "Error: Bitmap contains character other than 0-9 and A-F"}
    end

  end

  def parse_bmp(:ascii, msg) do

    <<bitmap::binary-size(32), data_sections::binary>> = msg # the msg contains both bitmap

    if String.match?(bitmap, ~r/^[0-9A-F]{32}$/) == true do
      <<_::1, bmp::127>> = Base.decode16!(bitmap)
      list_of_elements = bitmap_to_list(<<0::1, bmp::127>>)
      {:ok, list_of_elements, data_sections}
    else
      {:error, "Error: Bitmap contains character other than 0-9 and A-F"}
    end

  end

  def parse_bmp(:bin, <<0::1, bmp::63, data_sections::binary>>) do
    list_of_elements = bitmap_to_list(<<0::1, bmp::63>>)
    {:ok, list_of_elements, data_sections}
  end

  def parse_bmp(:bin, <<1::1, bmp::127, data_sections::binary>>) do
    list_of_elements = bitmap_to_list(<<0::1, bmp::127>>)
    {:ok, list_of_elements, data_sections}
  end

  def bitmap_to_list(bitmap) do # conver the bmp binary to a list
    for(<<r::1 <- bitmap>>, do: r)
    |> Enum.with_index(1)
    |> Enum.map(fn {a, b} -> {b, a} end)
    |> Enum.filter(fn {_, b} -> b == 1 end)
    |> Enum.map(fn {a, _} -> a end)
  end

  def get_msg_field_spec(pos_list, master_list) do
    get_msg_field_spec(pos_list, master_list, [])
  end

  def get_msg_field_spec([], _master_list, output) do
    output
  end

  def get_msg_field_spec(pos_list, master_list, output) do

    [head | tail] = pos_list

    spec = Enum.find(master_list, fn {x, _, _, _} -> x == head end)

    find_spec_result = case spec do
      nil -> {:error, head, nil}
      spec -> {:ok, head, spec}
    end

    get_msg_field_spec(tail, master_list, [find_spec_result | output])

  end

  def get_and_validate_iso_element_spec(list_of_elements, iso_spec_config) do
    iso_element_specs =
      list_of_elements
      |> Enum.sort
      |> get_msg_field_spec(iso_spec_config)
      |> Enum.reverse

    not_defined_iso_element_specs =
      iso_element_specs
      |> Enum.filter(fn {result, _position, _spec} -> result == :error end)
      |> Enum.map(fn {_result, position, _spec} -> position end)

    if length(not_defined_iso_element_specs) > 0 do
      {:error, "this fields spec was not defined #{not_defined_iso_element_specs}"}
    else
      iso_element_specs =
        iso_element_specs
        |> Enum.map(fn {_result, _position, element_spec} -> element_spec end)

      #parse_fields(data_sections, scheme, iso_element_specs)
      {:ok, iso_element_specs}
    end
  end

end
