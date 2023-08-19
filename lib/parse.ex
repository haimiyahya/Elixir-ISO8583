defmodule ElixirISO8583.Parse do

  @type bitmap_pos() :: 1..128

  def parse_msg(message, scheme, master_spec) do
    {:ok, list_of_pos, msg_data} = parse_bmp(scheme, message)

    spec = list_of_pos |> Enum.sort |> get_msg_field_spec(master_spec) |> Enum.reverse # from the map, get the list of pos, then get the list of spec, the end result is: [{2, 2, :num, 19}, {42, 0, :alphanum, 15}]

    list_of_spec_not_defined = spec |> Enum.filter(fn {result, _position, _spec} -> result == :error end) |> Enum.map(fn {_result, position, _spec} -> position end)

    if length(list_of_spec_not_defined) > 0 do
      {:error, "this fields spec was not defined #{list_of_spec_not_defined}"}
    else
      spec = spec |> Enum.map(fn {_result, _position, spec} -> spec end)
      parse_fields(:ok, msg_data, scheme, spec, %{})
    end

  end

  def parse_fields({:error, field_number, error, error_msg, spec, msg, success_parsed}, _msg, _scheme, _spec, output) do
    {{:error, field_number, error, error_msg, spec, msg, Base.encode16(msg), success_parsed}, output}
  end

  def parse_fields(:ok, _msg, _scheme, [], output) do
    {:ok, output} # return the parsed msg
  end

  def parse_fields(:ok, msg, scheme, spec, output) do
    [{pos, head_size, data_type, max} | rest_of_spec] = spec

    {result, output, rest_of_msg} =
      case field(msg, scheme, head_size, data_type, max) do
        {:ok, data, rest_of_msg} -> {:ok, Map.put(output, pos, data), rest_of_msg}
        {:error, error, error_msg, _rest_of_msg} -> {{:error, pos, error, error_msg, spec, msg, output}, %{}, <<>>}
      end

      # todo, if result supplied as :error dont proceed
      parse_fields(result, rest_of_msg, scheme, rest_of_spec, output) # call itself with the next list of field spec

  end

  def field(msg, scheme, head_size, data_type, max)
    when head_size in [0, 1, 2, 3, 4] do

    {data_length, rest} = head(msg, scheme, head_size)
    data_length = data_length(data_length, max) # either use head size of fixed length (use max)
    body(rest, scheme, data_type, data_length) # get body value

  end

  # binary head
  def head(<<a::4, b::4, rest::binary>>, :bin, 2) # 2 digits is 1 byte, each number represented with half byte
    when a >= 0 and a <= 9 and b >= 0 and b <= 9 do
    data_length = a*10 + b
    {data_length, rest}
  end

  def head(<<a::4, b::4, c::4, d::4, rest::binary>>, :bin, 3) # 3 digits is 2 bytes, first nible is ignored
    when b >= 0 and b <= 9 and c >= 0 and c <= 9 and d >= 0 and d <= 9 do

      if a > 0 do
        IO.inspect "Error: Invalid header format, the first nibble value should be 0, found #{a}"
      end

      data_length = b*100 + c*10 + d
      {data_length, rest}
  end

  # ascii head
  def head(<<_::4, a::4, _::4, b::4, rest::binary>>, :ascii, 2) # 2 digits is 2 bytes, each number represented with 1 byte, ignore the first nible for each byte (refer to ASCII spec)
    when a >= 0 and a <= 9 and b >= 0 and b <= 9 do
    data_length = a*10 + b
    {data_length, rest}
  end

  def head(<<_::4, a::4, _::4, b::4, _::4, c::4, rest::binary>>, :ascii, 3) # 3 digits is 3 bytes
    when a >= 0 and a <= 9 and b >= 0 and b <= 9 and c >= 0 and c <= 9 do
    data_length = a*100 + b*10 + c
    {data_length, rest}
  end

  def head(msg, _scheme, 0) do # 0 if fixed length
    {0, msg}
  end

  ## parse body
  def body(msg, _scheme, _data_type = :alphanum, data_length)
    when byte_size(msg) >= data_length do # alphanum always 1 byte for any scheme

    <<data::binary-size(data_length), rest::binary>> = msg

    {:ok, data, rest}
  end

  def body(msg, _scheme, _data_type = :alphanum, data_length) when byte_size(msg) < data_length do
    {:error, :insufficient_data, "Insufficient data to parse, required: #{data_length}, available data: #{byte_size(msg)}", msg}
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

end
