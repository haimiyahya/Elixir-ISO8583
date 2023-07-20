defmodule FormTest do
  use ExUnit.Case
  alias ElixirISO8583.Form

  test "test all" do

    #form_field(data, scheme, head_size, data_type, max)

    data = "123456789012345"
    manually = Base.decode16!("15") <> Base.decode16!(data <> "0")
    formed = Form.form_field(data, :bin, 2, :num, 20)
    assert(manually == formed)

    data = "123456789012345"
    manually = Base.decode16!("0015") <> Base.decode16!(data <> "0")
    formed = Form.form_field(data, :bin, 3, :num, 20)
    assert(manually == formed)

    data = "123456789012345"
    manually = Base.decode16!(data <> "0")
    formed = Form.form_field(data, :bin, 0, :num, 15)
    assert(manually == formed)

    data = "123456789012345"
    manually = Base.decode16!("15") <> data
    formed = Form.form_field(data, :bin, 2, :alphanum, 20)
    assert(manually == formed)

    data = "123456789012345"
    manually = Base.decode16!("0015") <> data
    formed = Form.form_field(data, :bin, 3, :alphanum, 20)
    assert(manually == formed)

    data = "123456789012345"
    manually = data
    formed = Form.form_field(data, :bin, 0, :alphanum, 15)
    assert(manually == formed)

    data = "1234567890123456789012345678901234567"
    manually = Base.decode16!("37") <> Base.decode16!(data <> "0")
    formed = Form.form_field(data, :bin, 2, :z, 40)
    assert(manually == formed)

    data = Base.decode16!("1234")
    manually = Base.decode16!("02") <> data
    formed = Form.form_field(data, :bin, 2, :b, 40)
    #^parsed = Base.decode16!(data)
    assert(manually == formed)

    data = "123456789012345"
    manually = "15" <> data
    formed = Form.form_field(data, :ascii, 2, :num, 20)
    assert(manually == formed)

    data = "123456789012345"
    manually = "015" <> data
    formed = Form.form_field(data, :ascii, 3, :num, 20)
    assert(manually == formed)

    data = "123456789012345"
    manually = data
    formed = Form.form_field(data, :ascii, 0, :num, 15)
    assert(manually == formed)

    data = "123456789012345"
    manually = "15" <> data
    formed = Form.form_field(data, :ascii, 2, :alphanum, 20)
    assert(manually == formed)

    data = "123456789012345"
    manually = "015" <> data
    formed = Form.form_field(data, :ascii, 3, :alphanum, 20)
    assert(manually == formed)

    data = "123456789012345"
    manually = data
    formed = Form.form_field(data, :ascii, 0, :alphanum, 15)
    assert(manually == formed)

    data = "1234567890123456789012345678901234567"
    manually = "37" <> data
    formed = Form.form_field(data, :ascii, 2, :z, 40)
    assert(manually == formed)

    data = "1234567890123456789012345678901234567"
    manually = "037" <> data
    formed = Form.form_field(data, :ascii, 3, :z, 40)
    assert(manually == formed)

    data = "1234567890123456789012345678901234567"
    manually = data
    formed = Form.form_field(data, :ascii, 0, :z, 37)
    assert(manually == formed)

    data = Base.decode16!("123456789012345678901234567890123456")
    manually = "18" <> Base.encode16(data)
    formed = Form.form_field(data, :ascii, 2, :b, 40)
    assert(manually == formed)

    data = Base.decode16!("123456789012345678901234567890123456")
    manually = "018" <> Base.encode16(data)
    formed = Form.form_field(data, :ascii, 3, :b, 40)
    assert(manually == formed)

    data = Base.decode16!("123456789012345678901234567890123456")
    manually = Base.encode16(data)
    formed = Form.form_field(data, :ascii, 0, :b, 18)
    assert(manually == formed)

    data = Base.decode16!("123456789012345678901234567890123456")
    manually = "18" <> data
    formed = Form.form_field(data, :ascii, 2, :br, 40)
    assert(manually == formed)

    data = Base.decode16!("123456789012345678901234567890123456")
    manually = "018" <> data
    formed = Form.form_field(data, :ascii, 3, :br, 40)
    assert(manually == formed)

    data = Base.decode16!("123456789012345678901234567890123456")
    manually = data
    formed = Form.form_field(data, :ascii, 0, :br, 18)
    assert(manually == formed)

    # ##

    # data = "123456789012345678901234567890123456"
    # manually = "018" <> Base.decode16!(data)
    # msg_multiple = msg

    # data = "123456789012345678901234567890123456"
    # manually = Base.decode16!(data)

    # msg_multiple = msg_multiple <> msg

    # result = Form.parse_msg(msg_multiple, :ascii, [{2, 3, :br, 40}, {3, 0, :br, 18}], %{})

    # IO.inspect result

  end
end
