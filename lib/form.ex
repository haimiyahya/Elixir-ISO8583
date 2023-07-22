defmodule ElixirISO8583.Form do

  require Integer

  # supply the field_spec like this {pos, head_size, data_type, max} :
  # [{2, 2, :num, 19}, {3, 0, :num, 6}]

  def form_msg(msg_map, scheme, master_spec) do
    spec = Map.keys(msg_map) |> Enum.sort |> get_msg_field_spec(master_spec) |> Enum.reverse # from the map, get the list of pos, then get the list of spec, the end result is: [{2, 2, :num, 19}, {42, 0, :alphanum, 15}]
    bitmap = form_bitmap(msg_map) |> encode_bmp(scheme)
    fields = form_fields(msg_map, scheme, spec)

    bitmap <> fields
  end

  def form_fields(msg_map, scheme, spec) do
    form_fields(msg_map, scheme, spec, <<>>)
  end

  def form_fields(_msg_map, _scheme, [], output) do
    output
  end

  def form_fields(msg_map, scheme, spec, output) do

    [{pos, head_size, data_type, max} | rest_spec] = spec

    field_val = Map.fetch!(msg_map, pos)
    formed_field = form(field_val, scheme, head_size, data_type, max)

    form_fields(msg_map, scheme, rest_spec, output <> formed_field) # call itself with the next list of field spec
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

  def form(data, scheme, head_size, data_type, max) do
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

    tidy(bmp)
  end

  def tidy(<<first_bmp::binary-size(8), 0::64 >>) do # remove the second bmp if all the last 64 bits are zeroes
    first_bmp
  end

  def tidy(bmp) do # set the first bit
    <<_first_bit::1, next7bit::7, the_rest::binary>> = bmp
    <<1::1, next7bit::7, the_rest::binary>> # set the first bit
  end

  def encode_bmp(bmp, :ascii) do
    Base.encode16!(bmp)
  end

  def encode_bmp(bmp, _) do
    bmp
  end

end
