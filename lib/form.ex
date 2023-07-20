defmodule ElixirISO8583.Form do

  require Integer

  def form_field(data, scheme, head_size, data_type, max) do
    head_val = head_val_from_data(data, head_size, max)
    data = pad_data(data, head_size, data_type, max)

    head_val = form_head(scheme, head_size, split_head(head_val))
    body_val = form_body(data, scheme, data_type, max)

    head_val <> body_val
  end

  def head_val_from_data(data, 3, max) do
    get_head_val(byte_size(data), max)
      |> get_head_val(999) # truncate by theoretical field maximum size
  end

  def head_val_from_data(data, 2, max) do
    get_head_val(byte_size(data), max)
      |> get_head_val(99) # truncate by the theoretical field maximum size
  end

  def head_val_from_data(data, 1, max) do
    get_head_val(byte_size(data), max)
      |> get_head_val(9) # truncate by the theoretical field maximum size
  end

  def head_val_from_data(_data, 0, _max) do
    0
  end

  def get_head_val(len, max) when len > max do
    max
  end

  def get_head_val(len, _max) do
    len
  end

  def split_head(len)  do
    Integer.digits(len) # split into [1, 2, 3]
    |> List.insert_at(0, 0) # prepand with 0 to make sure the list is at least have 3 item
    |> List.insert_at(0, 0) # prepand with 0 to make sure the list is at least have 3 item
    |> Enum.take(-3) # take the last three
    |> List.to_tuple # convert to tuple for eg: {1, 2, 3}
  end

  # head
  def form_head(:bin, 2, {0, p, s}) do
    <<p::4, s::4>>
  end
  def form_head(:bin, 3, {r, p, s}) do
    <<0::4, r::4, p::4, s::4>>
  end
  def form_head(:bin, 0, _) do
    <<>>
  end

  def form_head(:ascii, 2, {0, p, s}) do
    <<3::4, p::4, 3::4, s::4>>
  end
  def form_head(:ascii, 3, {r, p, s}) do
    <<3::4, r::4, 3::4, p::4, 3::4, s::4>>
  end
  def form_head(:ascii, 0, _) do
    <<>>
  end

  # body

  def form_body(data, _scheme, :alphanum, _max) do
    data
  end

  def form_body(data, _scheme = :bin, data_type, _max)
    when data_type in [:num, :z] do
    decode16(data)
  end

  def form_body(data, _scheme = :bin, :b, _max) do
    data
  end

  def form_body(data, _scheme = :ascii, data_type, _max)
    when data_type in [:num, :z] do
    data
  end

  def form_body(data, _scheme = :ascii, data_type, _max)
    when data_type in [:num, :z] do
    data
  end

  def form_body(data, _scheme = :ascii, :b, _max) do
    Base.encode16(data)
  end

  def form_body(data, _scheme = :ascii, :br, _max) do
    data
  end

  def decode16(data) when rem(byte_size(data), 2) > 0 do
    Base.decode16!(data <> "0")
  end

  def decode16(data) do
    Base.decode16!(data)
  end

  def pad_data(data, 0, :num, max) do
    String.pad_trailing(data, max, "0")
  end

  def pad_data(data, 0, :alphanum, max) do
    String.pad_leading(data, max)
  end

  def pad_data(data, 0, :z, max) do
    String.pad_trailing(data, max, "0")
  end

  def pad_data(data, _, :z, _max) do
    data
  end

  def pad_data(data, 0, :b, max) do
    pad = max - byte_size(data)
    <<data::binary, 0::pad*8>>
  end
  def pad_data(data, _, :b, _max) do
    data
  end

  def pad_data(data, _head_len, :num, _max) do
    data
  end

  def pad_data(data, _head_len, :alphanum, _max) do
    data
  end

  def pad_data(data, _head_len, :br, _max) do
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

  def form_bitmap(elements) do
    list_of_bits =
      1..128
      |> Enum.map(fn x -> Map.has_key?(elements, x) end)
      |> Enum.map(fn x -> case x do true -> 1; false -> 0 end end)

    bmp =
      for i <- list_of_bits, do: <<i::1>>, into: <<>>

    prettify(bmp)
  end

  def prettify(<<first_bmp::binary-size(8), 0::64 >>) do # remove the second bmp
    first_bmp
  end

  def prettify(bmp) do # set the first bit
    <<_first_bit::1, next7bit::7, the_rest::binary>> = bmp
    <<1::1, next7bit::7, the_rest::binary>>
  end

end
