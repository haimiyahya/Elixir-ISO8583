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

    _result = Parse.parse_msg(msg_multiple, :ascii, [{2, 3, :br, 40}, {3, 0, :br, 18}], %{})

    #IO.inspect result

  end
end
