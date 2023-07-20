defmodule ElixirISO8583.Parse do

  def parse_msg(_msg, _scheme, [], output) do
    output
  end

  def parse_msg(msg, scheme, list_of_field_spec, output) do
    [{pos, head_size, data_type, max} | rest_list_of_field_spec] = list_of_field_spec

    {data, rest_of_msg} = field(msg, scheme, head_size, data_type, max)

    output = Map.put(output, pos, data)

    parse_msg(rest_of_msg, scheme, rest_list_of_field_spec, output)
  end

  def field(msg, scheme, head_size, data_type, max)
    when head_size in [0, 1, 2, 3, 4] do

    {data_length, rest} = head(msg, scheme, head_size)

    data_length =
      case data_length do
      0 -> max
      _ -> data_length
    end

    body(rest, scheme, data_type, data_length)

  end

  # binary head
  def head(<<a::4, b::4, rest::binary>>, :bin, 2)
    when a >= 0 and a <= 9 and b >= 0 and b <= 9 do
    data_length = a*10 + b
    {data_length, rest}
  end

  def head(<<_a::4, b::4, c::4, d::4, rest::binary>>, :bin, 3)
    when b >= 0 and b <= 9 and c >= 0 and c <= 9 and d >= 0 and d <= 9 do
    data_length = b*100 + c*10 + d
    {data_length, rest}
  end

  # ascii head
  def head(<<_::4, a::4, _::4, b::4, rest::binary>>, :ascii, 2)
    when a >= 0 and a <= 9 and b >= 0 and b <= 9 do
    data_length = a*10 + b
    {data_length, rest}
  end

  def head(<<_::4, a::4, _::4, b::4, _::4, c::4, rest::binary>>, :ascii, 3)
    when a >= 0 and a <= 9 and b >= 0 and b <= 9 and c >= 0 and c <= 9 do
    data_length = a*100 + b*10 + c
    {data_length, rest}
  end

  def head(msg, _scheme, 0) do
    {0, msg}
  end

  ## begin!!

  def body(msg, _scheme, _data_type = :alphanum, data_length) do # alphanum always 1 byte for any scheme
    <<data::binary-size(data_length), rest::binary>> = msg
    {data, rest}
  end

  def body(msg, _scheme = :bin, data_type, data_length)
    when data_type in [:num, :z] do
    byte_length = data_length + rem(data_length, 2) |> div(2)

    <<data::binary-size(byte_length), rest::binary>> = msg
    data = Base.encode16(data) |> truncate(data_length)
    {data, rest}
  end

  def body(msg, _scheme = :bin, _data_type = :b, data_length) do
    <<data::binary-size(data_length), rest::binary>> = msg
    {data, rest}
  end

  def body(msg, _scheme = :ascii, data_type, data_length)
   when data_type in [:num, :z] do
    <<data::binary-size(data_length), rest::binary>> = msg
    {data, rest}
  end

  def body(msg, _scheme = :ascii, _data_type = :b, data_length) do
    data_length = data_length*2
    <<data::binary-size(data_length), rest::binary>> = msg
    data = Base.decode16!(data)
    {data, rest}
  end

  def body(msg, _scheme = :ascii, _data_type = :br, data_length) do # special type: raw binary for ascii scheme
    data_length = data_length
    <<data::binary-size(data_length), rest::binary>> = msg
    {data, rest}
  end

  ## END!!


  def truncate(data, max) when byte_size(data) > max do
    <<data::binary-size(max), _::binary>> = data
    data
  end

  def truncate(data, _max) do
    data
  end

  def bmp(:ascii, msg = <<first_char::8, _rest::binary>>)
    when first_char > ?1 and first_char < ?8 do
    <<bitmap::binary-size(16), rest::binary>> = msg
    {bitmap_to_list(Base.decode16!(bitmap)), rest}
  end

  def bmp(:ascii, msg) do
    <<bitmap::binary-size(32), rest::binary>> = msg
    {bitmap_to_list(Base.decode16!(bitmap)), rest}
  end

  def bmp(:binary, <<0::1, bmp::63, rest::binary>>) do
    {bitmap_to_list(<<0::1, bmp::63>>), rest}
  end

  def bmp(:binary, <<1::1, bmp::127, rest::binary>>) do
    {bitmap_to_list(<<0::1, bmp::127>>), rest}
  end

  def bitmap_to_list(bitmap) do
    for(<<r::1 <- bitmap>>, do: r)
    |> Enum.with_index(1)
    |> Enum.map(fn {a, b} -> {b, a} end)
    |> Enum.filter(fn {_, b} -> b == 1 end)
    |> Enum.map(fn {a, _} -> a end)
  end

end
