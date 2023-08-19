defmodule ParseTest do
  use ExUnit.Case
  alias ElixirISO8583.Parse

  test "test all" do

    data = "123456789012345"
    msg = Base.decode16!("15") <> Base.decode16!(data <> "0")
    {:ok, parsed, _left} = Parse.field(msg, :bin, 2, :num, 20)
    assert(data == parsed)

    data = "123456789012345"
    msg = Base.decode16!("0015") <> Base.decode16!(data <> "0")
    {:ok, parsed, _left} = Parse.field(msg, :bin, 3, :num, 20)
    assert(data == parsed)

    data = "123456789012345"
    msg = Base.decode16!(data <> "0")
    {:ok, parsed, _left} = Parse.field(msg, :bin, 0, :num, 15)
    assert(data == parsed)

    data = "123456789012345"
    msg = Base.decode16!("15") <> data
    {:ok, parsed, _left} = Parse.field(msg, :bin, 2, :alphanum, 20)
    assert(data == parsed)

    data = "123456789012345"
    msg = Base.decode16!("0015") <> data
    {:ok, parsed, _left} = Parse.field(msg, :bin, 3, :alphanum, 20)
    assert(data == parsed)

    data = "123456789012345"
    msg = data
    {:ok, parsed, _left} = Parse.field(msg, :bin, 0, :alphanum, 15)
    assert(data == parsed)

    data = "1234567890123456789012345678901234567"
    msg = Base.decode16!("37") <> Base.decode16!(data <> "0")
    {:ok, parsed, _left} = Parse.field(msg, :bin, 2, :z, 40)
    assert(data == parsed)

    data = "1234"
    msg = Base.decode16!("02") <> Base.decode16!(data)
    {:ok, parsed, _left} = Parse.field(msg, :bin, 2, :b, 40)
    assert (parsed == Base.decode16!(data))

    #
    data = "123456789012345"
    msg = "15" <> data
    {:ok, parsed, _left} = Parse.field(msg, :ascii, 2, :num, 20)
    assert(data == parsed)

    data = "123456789012345"
    msg = "015" <> data
    {:ok, parsed, _left} = Parse.field(msg, :ascii, 3, :num, 20)
    assert(data == parsed)

    data = "123456789012345"
    msg = data
    {:ok, parsed, _left} = Parse.field(msg, :ascii, 0, :num, 15)
    assert(data == parsed)

    data = "123456789012345"
    msg = "15" <> data
    {:ok, parsed, _left} = Parse.field(msg, :ascii, 2, :alphanum, 20)
    assert(data == parsed)

    data = "123456789012345"
    msg = "015" <> data
    {:ok, parsed, _left} = Parse.field(msg, :ascii, 3, :alphanum, 20)
    assert(data == parsed)

    data = "123456789012345"
    msg = data
    {:ok, parsed, _left} = Parse.field(msg, :ascii, 0, :alphanum, 15)
    assert(data == parsed)

    data = "1234567890123456789012345678901234567"
    msg = "37" <> data
    {:ok, parsed, _left} = Parse.field(msg, :ascii, 2, :z, 40)
    assert(data == parsed)

    data = "1234567890123456789012345678901234567"
    msg = "037" <> data
    {:ok, parsed, _left} = Parse.field(msg, :ascii, 3, :z, 40)
    assert(data == parsed)

    data = "1234567890123456789012345678901234567"
    msg = data
    {:ok, parsed, _left} = Parse.field(msg, :ascii, 0, :z, 37)
    assert(data == parsed)

    data = "123456789012345678901234567890123456"
    msg = "18" <> data
    {:ok, parsed, _left} = Parse.field(msg, :ascii, 2, :b, 40)
    data = Base.decode16!(data)
    assert(data == parsed)

    data = "123456789012345678901234567890123456"
    msg = "018" <> data
    {:ok, parsed, _left} = Parse.field(msg, :ascii, 3, :b, 40)
    data = Base.decode16!(data)
    assert(data == parsed)

    data = "123456789012345678901234567890123456"
    msg = data
    {:ok, parsed, _left} = Parse.field(msg, :ascii, 0, :b, 18)
    data = Base.decode16!(data)
    assert(data == parsed)

    data = "123456789012345678901234567890123456"
    msg = "18" <> Base.decode16!(data)
    {:ok, parsed, _left} = Parse.field(msg, :ascii, 2, :br, 40)
    data = Base.decode16!(data)
    assert(data == parsed)

    data = "123456789012345678901234567890123456"
    msg = "018" <> Base.decode16!(data)
    {:ok, parsed, _left} = Parse.field(msg, :ascii, 3, :br, 40)
    data = Base.decode16!(data)
    assert(data == parsed)

    data = "123456789012345678901234567890123456"
    msg = Base.decode16!(data)
    {:ok, parsed, _left} = Parse.field(msg, :ascii, 0, :br, 18)
    data = Base.decode16!(data)
    assert(data == parsed)

    ##

    data = "123456789012345678901234567890123456"
    msg = "018" <> Base.decode16!(data)
    msg_multiple = msg

    data = "123456789012345678901234567890123456"
    msg = Base.decode16!(data)

    msg_multiple = msg_multiple <> msg

    _result = Parse.parse_elements(msg_multiple, :ascii, [{2, 3, :br, 40}, {3, 0, :br, 18}])


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

    <<_::binary-size(7), bmp_and_data::binary>> = msg_bin

    parsed = Parse.parse_msg(bmp_and_data, :bin, master_spec)

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

  test "form a message then map to a txn type" do
    alias ElixirISO8583.Form
    alias ElixirISO8583.Parse

    encoding_scheme = :ascii

    iso_spec = [
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
        {128, 0, :alphanum, 16}
      ]

      mapper = fn (iso_msg) ->
        case iso_msg do
          %{:mti => "0200", 3 => "00" <> _} -> 1
          %{:mti => "0200", 3 => "02" <> _} -> 2
          %{:mti => "0200", 3 => _} -> 0
          %{:mti => "0400", 3 => "00" <> _} -> 3
          %{:mti => "0400", 3 => "02" <> _} -> 4
          %{:mti => "0400", 3 => "93" <> _} -> 6
          %{:mti => "0400", 3 => _} -> 0
          %{:mti => "0500", 3 => "93" <> _} -> 5
          %{:mti => "0500", 3 => "94" <> _} -> 4
          %{:mti => "0500", 3 => "92" <> _} -> 7
          %{:mti => "0500", 3 => "96" <> _} -> 8
          %{:mti => "0500", 3 => _} -> 0
          %{:mti => "0800", 3 => "93" <> _} -> 11
          %{:mti => "0800", 3 => "94" <> _} -> 12
          %{:mti => "0800", 3 => _} -> 0
          %{:mti => "0320", 3 => <<_::binary-size(5), "0">>} -> 9
          %{:mti => "0320", 3 => <<_::binary-size(5), "1">>} -> 10
        end
      end

    msg = %{
      4 => "000000000010"
    }

    formed_msg = Form.form_msg(msg, encoding_scheme, iso_spec)
    tpdu = "123456789012"
    mti = "0200"

    formed_msg = tpdu <> mti <> formed_msg

    <<tpdu::binary-size(12), mti::binary-size(4), data::binary>> = formed_msg

    {:ok, parsed} = Parse.parse_msg(data, encoding_scheme, iso_spec)

    assert parsed == %{4 => "000000000010"}

  end

  test "parse eCard txn" do

    iso_spec = [
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
      {128, 0, :alphanum, 16}
    ]

    msg = "600132000002003020058020C0001C0040000000000010650005780022013200347897139200999776D3812101999000000F3838353032393032303030303031303238393032393034003330313A50313A3030303537383A563A30313035313934303031303635303130363D001530323A3030303030303030313036350003000001"

    <<tpdu::binary-size(10), mti::binary-size(4), data::binary>> = msg

    decoded = Base.decode16!(data)

    encoding_scheme = :bin

    Parse.parse_msg(decoded, encoding_scheme, iso_spec)
  end

  test "parse eCard txn 2" do

    iso_spec = [
      {2, 2, :num, 19},
      {3, 0, :num, 6},
      {4, 0, :num, 12},
      {5, 0, :num, 12},
      {6, 0, :num, 12},
      {7, 0, :num, 10},
      {8, 0, :num, 8},
      {9, 0, :num, 8},
      {10, 0, :num, 8},
      {11, 0, :num, 6},
      {12, 0, :num, 6},
      {13, 0, :num, 4},
      {14, 0, :num, 4},
      {15, 0, :num, 4},
      {16, 0, :num, 4},
      {17, 0, :num, 4},
      {18, 0, :num, 4},
      {19, 0, :num, 3},
      {20, 0, :num, 3},
      {21, 0, :num, 3},
      {22, 0, :num, 3},
      {23, 0, :num, 3},
      {24, 0, :num, 3},
      {25, 0, :num, 2},
      {26, 0, :num, 2},
      {27, 0, :num, 1},
      {28, 0, :num, 8},
      {29, 0, :num, 8},
      {30, 0, :num, 8},
      {31, 0, :num, 8},
      {32, 2, :num, 11},
      {33, 2, :num, 11},
      {34, 2, :num, 28},
      {35, 2, :num, 37},
      {36, 3, :num, 104},
      {37, 0, :num, 12},
      {38, 0, :num, 6},
      {39, 0, :num, 2},
      {40, 0, :alphanum, 3},
      {41, 0, :alphanum, 16},
      {42, 0, :alphanum, 15},
      {43, 0, :alphanum, 40},
      {44, 2, :alphanum, 25},
      {45, 2, :alphanum, 76},
      {46, 3, :alphanum, 999},
      {47, 3, :alphanum, 999},
      {48, 3, :alphanum, 30},
      {49, 0, :alphanum, 3},
      {50, 0, :alphanum, 3},
      {51, 0, :alphanum, 3},
      {52, 0, :alphanum, 16},
      {53, 0, :alphanum, 16},
      {54, 3, :alphanum, 12},
      {55, 3, :br, 999},
      {56, 3, :alphanum, 999},
      {57, 3, :alphanum, 999},
      {58, 3, :alphanum, 999},
      {59, 3, :alphanum, 999},
      {60, 3, :alphanum, 999},
      {61, 3, :alphanum, 999},
      {62, 3, :alphanum, 999},
      {63, 3, :alphanum, 999},
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
      {128, 0, :alphanum, 16}
    ]

    msg = "600132000002003020058020C0001C00400000000000072800062600220132003838353032393032303030303031303238393032393034003330313A50313A3030303532353A563A30313033353439303030373238303130363D002630323A3030303030303030303732383A303137373437343730330006303030303031"

    <<tpdu::binary-size(10), mti::binary-size(4), data::binary>> = msg

    decoded = Base.decode16!(data)

    encoding_scheme = :bin

    {error, result} = Parse.parse_msg(decoded, encoding_scheme, iso_spec)

    #{result, field_number, _, _, _, _, _, _} = error

    #assert result == :error

    IO.inspect error
    IO.inspect result
  end

end
