defmodule ParseTest do
  use ExUnit.Case
  alias ElixirISO8583.Parse

  test "test all" do

    data = "123456789012345"
    msg = Base.decode16!("15") <> Base.decode16!(data <> "0")
    {parsed, _left} = Parse.field(msg, :bin, 2, :num, 20)
    assert(data == parsed)

    data = "123456789012345"
    msg = Base.decode16!("0015") <> Base.decode16!(data <> "0")
    {parsed, _left} = Parse.field(msg, :bin, 3, :num, 20)
    assert(data == parsed)

    data = "123456789012345"
    msg = Base.decode16!(data <> "0")
    {parsed, _left} = Parse.field(msg, :bin, 0, :num, 15)
    assert(data == parsed)

    data = "123456789012345"
    msg = Base.decode16!("15") <> data
    {parsed, _left} = Parse.field(msg, :bin, 2, :alphanum, 20)
    assert(data == parsed)

    data = "123456789012345"
    msg = Base.decode16!("0015") <> data
    {parsed, _left} = Parse.field(msg, :bin, 3, :alphanum, 20)
    assert(data == parsed)

    data = "123456789012345"
    msg = data
    {parsed, _left} = Parse.field(msg, :bin, 0, :alphanum, 15)
    assert(data == parsed)

    data = "1234567890123456789012345678901234567"
    msg = Base.decode16!("37") <> Base.decode16!(data <> "0")
    {parsed, _left} = Parse.field(msg, :bin, 2, :z, 40)
    assert(data == parsed)

    data = "1234"
    msg = Base.decode16!("02") <> Base.decode16!(data)
    {parsed, _left} = Parse.field(msg, :bin, 2, :b, 40)
    ^parsed = Base.decode16!(data)

    #
    data = "123456789012345"
    msg = "15" <> data
    {parsed, _left} = Parse.field(msg, :ascii, 2, :num, 20)
    assert(data == parsed)

    data = "123456789012345"
    msg = "015" <> data
    {parsed, _left} = Parse.field(msg, :ascii, 3, :num, 20)
    assert(data == parsed)

    data = "123456789012345"
    msg = data
    {parsed, _left} = Parse.field(msg, :ascii, 0, :num, 15)
    assert(data == parsed)

    data = "123456789012345"
    msg = "15" <> data
    {parsed, _left} = Parse.field(msg, :ascii, 2, :alphanum, 20)
    assert(data == parsed)

    data = "123456789012345"
    msg = "015" <> data
    {parsed, _left} = Parse.field(msg, :ascii, 3, :alphanum, 20)
    assert(data == parsed)

    data = "123456789012345"
    msg = data
    {parsed, _left} = Parse.field(msg, :ascii, 0, :alphanum, 15)
    assert(data == parsed)

    data = "1234567890123456789012345678901234567"
    msg = "37" <> data
    {parsed, _left} = Parse.field(msg, :ascii, 2, :z, 40)
    assert(data == parsed)

    data = "1234567890123456789012345678901234567"
    msg = "037" <> data
    {parsed, _left} = Parse.field(msg, :ascii, 3, :z, 40)
    assert(data == parsed)

    data = "1234567890123456789012345678901234567"
    msg = data
    {parsed, _left} = Parse.field(msg, :ascii, 0, :z, 37)
    assert(data == parsed)

    data = "123456789012345678901234567890123456"
    msg = "18" <> data
    {parsed, _left} = Parse.field(msg, :ascii, 2, :b, 40)
    data = Base.decode16!(data)
    assert(data == parsed)

    data = "123456789012345678901234567890123456"
    msg = "018" <> data
    {parsed, _left} = Parse.field(msg, :ascii, 3, :b, 40)
    data = Base.decode16!(data)
    assert(data == parsed)

    data = "123456789012345678901234567890123456"
    msg = data
    {parsed, _left} = Parse.field(msg, :ascii, 0, :b, 18)
    data = Base.decode16!(data)
    assert(data == parsed)

    data = "123456789012345678901234567890123456"
    msg = "18" <> Base.decode16!(data)
    {parsed, _left} = Parse.field(msg, :ascii, 2, :br, 40)
    data = Base.decode16!(data)
    assert(data == parsed)

    data = "123456789012345678901234567890123456"
    msg = "018" <> Base.decode16!(data)
    {parsed, _left} = Parse.field(msg, :ascii, 3, :br, 40)
    data = Base.decode16!(data)
    assert(data == parsed)

    data = "123456789012345678901234567890123456"
    msg = Base.decode16!(data)
    {parsed, _left} = Parse.field(msg, :ascii, 0, :br, 18)
    data = Base.decode16!(data)
    assert(data == parsed)

    ##

    data = "123456789012345678901234567890123456"
    msg = "018" <> Base.decode16!(data)
    msg_multiple = msg

    data = "123456789012345678901234567890123456"
    msg = Base.decode16!(data)

    msg_multiple = msg_multiple <> msg

    _result = Parse.parse_fields(msg_multiple, :ascii, [{2, 3, :br, 40}, {3, 0, :br, 18}], %{})

    #IO.inspect result

  end

  test "parse loyalty response" do
    msg =        "60000001320210303801000E80000C0"
    msg = msg <> "0400000000000215300248516221007"
    msg = msg <> "2001323134313636353732383630373"
    msg = msg <> "5383838413830303838353032393032"
    msg = msg <> "0016343130303A323032362D30372D3"
    msg = msg <> "3313A0016323030303A323130303A30"
    msg = msg <> "3A34313030"

    # [3, 4, 11, 12, 13, 24, 37, 38, 39, 41, 61, 62]
    master_spec = [{3, 0, :num, 6}, {4, 0, :num, 12}, {11, 0, :num, 6}, {12, 0, :num, 6}, {13, 0, :num, 4}, {24, 0, :num, 3}, {37, 0, :alphanum, 12}, {38, 0, :alphanum, 6}, {39, 0, :alphanum, 2}, {41, 0, :alphanum, 8}, {61, 3, :alphanum, 996}, {62, 3, :alphanum, 997}]

    msg_bin = Base.decode16!(msg)
    #IO.inspect msg_bin
    #IO.inspect Base.encode16(binary_part(msg_bin, 0, 7))
    #IO.inspect Base.encode16(binary_part(msg_bin, 7, 8))
    #IO.inspect Parse.bitmap_to_list(binary_part(msg_bin, 7, 8))

    <<_::binary-size(7), bmp_and_data::binary>> = msg_bin

    parsed = Parse.parse_msg(bmp_and_data, :bin, master_spec)

    IO.inspect parsed

  end

  test "parse testing cpay signon" do
    master_spec = [
      {2, 2, :num, 19},
      {3, 0, :num, 6},
      {4, 0, :num, 12},
      {7, 0, :num, 10},
      {11, 0, :num, 6},
      {12, 0, :num, 6},
      {13, 0, :num, 4},
      {14, 0, :num, 4},
      {15, 0, :num, 4},
      {17, 0, :num, 4},
      {18, 0, :num, 4},
      {22, 0, :num, 3},
      {23, 0, :num, 3},
      {25, 0, :num, 2},
      {27, 0, :num, 1},
      {30, 0, :num, 9},
      {32, 2, :num, 11},
      {35, 2, :num, 37},
      {37, 0, :num, 12},
      {38, 0, :num, 6},
      {39, 0, :num, 2},
      {41, 0, :alphanum, 16},
      {42, 0, :alphanum, 15},
      {43, 0, :alphanum, 40},
      {48, 3, :alphanum, 30},
      {49, 0, :alphanum, 3},
      {50, 0, :alphanum, 3},
      {52, 0, :alphanum, 16},
      {53, 0, :alphanum, 16},
      {54, 3, :alphanum, 12},
      {55, 3, :br, 999},
      {60, 0, :alphanum, 19},
      {61, 0, :alphanum, 22},
      {64, 0, :alphanum, 16},
      {66, 0, :alphanum, 1},
      {70, 0, :alphanum, 3},
      {74, 0, :alphanum, 10},
      {75, 0, :alphanum, 10},
      {76, 0, :alphanum, 10},
      {77, 0, :alphanum, 10},
      {80, 0, :alphanum, 10},
      {81, 0, :alphanum, 10},
      {86, 0, :alphanum, 16},
      {87, 0, :alphanum, 16},
      {88, 0, :alphanum, 16},
      {89, 0, :alphanum, 16},
      {90, 0, :alphanum, 42},
      {97, 0, :alphanum, 17},
      {99, 2, :alphanum, 11},
      {100, 2, :alphanum, 11},
      {120, 0, :alphanum, 9},
      {123, 3, :alphanum, 153},
      {125, 0, :alphanum, 15},
      {128, 0, :alphanum, 16},
    ]

    msg = "8220000000010000040000000000000007230131050004510190160111000112M10000001"

    Parse.parse_msg(msg, :ascii, master_spec)

  end

end
