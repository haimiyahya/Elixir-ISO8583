defmodule ElixirISO8583.Parse do

  def parse_msg(msg, scheme, master_spec) do
    spec = bmp(scheme, msg) |> Enum.sort |> get_msg_field_spec(master_spec) |> Enum.reverse # from the map, get the list of pos, then get the list of spec, the end result is: [{2, 2, :num, 19}, {42, 0, :alphanum, 15}]

    parse_fields(msg, scheme, spec, <<>>)
  end

  def parse_fields(_msg, _scheme, [], output) do
    output # return the parsed msg
  end

  def parse_fields(msg, scheme, spec, output) do
    [{pos, head_size, data_type, max} | rest_of_spec] = spec
    {data, rest_of_msg} = field(msg, scheme, head_size, data_type, max)
    output = Map.put(output, pos, data)
    parse_fields(rest_of_msg, scheme, rest_of_spec, output) # call itself with the next list of field spec

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

  def head(<<_a::4, b::4, c::4, d::4, rest::binary>>, :bin, 3) # 3 digits is 2 bytes, first nible is ignored
    when b >= 0 and b <= 9 and c >= 0 and c <= 9 and d >= 0 and d <= 9 do
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
  def body(msg, _scheme, _data_type = :alphanum, data_length) do # alphanum always 1 byte for any scheme
    <<data::binary-size(data_length), rest::binary>> = msg
    {data, rest}
  end

  def body(msg, _scheme = :bin, data_type, data_length) # scheme binary, numeric and track2 for each digit is represented with half byte
    when data_type in [:num, :z] do
    byte_length = data_length + rem(data_length, 2) |> div(2)

    <<data::binary-size(byte_length), rest::binary>> = msg
    data = Base.encode16(data) |> truncate(data_length)
    {data, rest}
  end

  def body(msg, _scheme = :bin, _data_type = :b, data_length) do # scheme binary, binary data represented as raw binary
    <<data::binary-size(data_length), rest::binary>> = msg
    {data, rest}
  end

  def body(msg, _scheme = :ascii, data_type, data_length) # scheme ascii, numeric and track2 for each digit is represented with 1 byte
   when data_type in [:num, :z] do
    <<data::binary-size(data_length), rest::binary>> = msg
    {data, rest}
  end

  def body(msg, _scheme = :ascii, _data_type = :b, data_length) do # scheme ascii, binary data represented as hex in ascii
    data_length = data_length*2
    <<data::binary-size(data_length), rest::binary>> = msg
    data = Base.decode16!(data)
    {data, rest}
  end

  def body(msg, _scheme = :ascii, _data_type = :br, data_length) do # scheme ascii, raw binary data represented as raw binary
    data_length = data_length
    <<data::binary-size(data_length), rest::binary>> = msg
    {data, rest}
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

  # bitmap parsing
  def bmp(:ascii, msg = <<first_char::8, _rest::binary>>)
    when first_char > ?1 and first_char < ?8 do # if the first bit is not set, the message only contains first bmp
    <<bitmap::binary-size(16), rest::binary>> = msg
    {bitmap_to_list(Base.decode16!(bitmap)), rest}
  end

  def bmp(:ascii, msg) do
    <<bitmap::binary-size(32), rest::binary>> = msg # the msg contains both bitmap
    {bitmap_to_list(Base.decode16!(bitmap)), rest}
  end

  def bmp(:binary, <<0::1, bmp::63, rest::binary>>) do
    {bitmap_to_list(<<0::1, bmp::63>>), rest} # if the first bit is not set, the message only contains first bmp
  end

  def bmp(:binary, <<1::1, bmp::127, rest::binary>>) do
    {bitmap_to_list(<<0::1, bmp::127>>), rest} # the msg contains both bitmap
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
    get_msg_field_spec(tail, master_list, [spec | output])
  end

end
