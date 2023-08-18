defmodule FormTest do
  use ExUnit.Case
  alias ElixirISO8583.Form

  test "test all" do

    #form(data, scheme, head_size, data_type, max)

    data = "123456789012345"
    manually = Base.decode16!("15") <> Base.decode16!(data <> "0")
    formed = Form.form(data, :bin, 2, :num, 20)
    assert(manually == formed)

    data = "123456789012345"
    manually = Base.decode16!("0015") <> Base.decode16!(data <> "0")
    formed = Form.form(data, :bin, 3, :num, 20)
    assert(manually == formed)

    data = "123456789012345"
    manually = Base.decode16!(data <> "0")
    formed = Form.form(data, :bin, 0, :num, 15)
    assert(manually == formed)

    data = "123456789012345"
    manually = Base.decode16!("15") <> data
    formed = Form.form(data, :bin, 2, :alphanum, 20)
    assert(manually == formed)

    data = "123456789012345"
    manually = Base.decode16!("0015") <> data
    formed = Form.form(data, :bin, 3, :alphanum, 20)
    assert(manually == formed)

    data = "123456789012345"
    manually = data
    formed = Form.form(data, :bin, 0, :alphanum, 15)
    assert(manually == formed)

    data = "1234567890123456789012345678901234567"
    manually = Base.decode16!("37") <> Base.decode16!(data <> "0")
    formed = Form.form(data, :bin, 2, :z, 40)
    assert(manually == formed)

    data = Base.decode16!("1234")
    manually = Base.decode16!("02") <> data
    formed = Form.form(data, :bin, 2, :b, 40)
    #^parsed = Base.decode16!(data)
    assert(manually == formed)

    data = "123456789012345"
    manually = "15" <> data
    formed = Form.form(data, :ascii, 2, :num, 20)
    assert(manually == formed)

    data = "123456789012345"
    manually = "015" <> data
    formed = Form.form(data, :ascii, 3, :num, 20)
    assert(manually == formed)

    data = "123456789012345"
    manually = data
    formed = Form.form(data, :ascii, 0, :num, 15)
    assert(manually == formed)

    data = "123456789012345"
    manually = "15" <> data
    formed = Form.form(data, :ascii, 2, :alphanum, 20)
    assert(manually == formed)

    data = "123456789012345"
    manually = "015" <> data
    formed = Form.form(data, :ascii, 3, :alphanum, 20)
    assert(manually == formed)

    data = "123456789012345"
    manually = data
    formed = Form.form(data, :ascii, 0, :alphanum, 15)
    assert(manually == formed)

    data = "1234567890123456789012345678901234567"
    manually = "37" <> data
    formed = Form.form(data, :ascii, 2, :z, 40)
    assert(manually == formed)

    data = "1234567890123456789012345678901234567"
    manually = "037" <> data
    formed = Form.form(data, :ascii, 3, :z, 40)
    assert(manually == formed)

    data = "1234567890123456789012345678901234567"
    manually = data
    formed = Form.form(data, :ascii, 0, :z, 37)
    assert(manually == formed)

    data = Base.decode16!("123456789012345678901234567890123456")
    manually = "18" <> Base.encode16(data)
    formed = Form.form(data, :ascii, 2, :b, 40)
    assert(manually == formed)

    data = Base.decode16!("123456789012345678901234567890123456")
    manually = "018" <> Base.encode16(data)
    formed = Form.form(data, :ascii, 3, :b, 40)
    assert(manually == formed)

    data = Base.decode16!("123456789012345678901234567890123456")
    manually = Base.encode16(data)
    formed = Form.form(data, :ascii, 0, :b, 18)
    assert(manually == formed)

    data = Base.decode16!("123456789012345678901234567890123456")
    manually = "18" <> data
    formed = Form.form(data, :ascii, 2, :br, 40)
    assert(manually == formed)

    data = Base.decode16!("123456789012345678901234567890123456")
    manually = "018" <> data
    formed = Form.form(data, :ascii, 3, :br, 40)
    assert(manually == formed)

    data = Base.decode16!("123456789012345678901234567890123456")
    manually = data
    formed = Form.form(data, :ascii, 0, :br, 18)
    assert(manually == formed)

    # ##

    # data = "123456789012345678901234567890123456"
    # manually = "018" <> Base.decode16!(data)
    # msg_multiple = msg

    # data = "123456789012345678901234567890123456"
    # manually = Base.decode16!(data)

    # msg_multiple = msg_multiple <> msg

    # result = Form.parse_msg(msg_multiple, :ascii, [{2, 3, :br, 40}, {3, 0, :br, 18}], %{})



  end

  test "test form msg" do
    msg_map = %{2 => "1234567890123456", 41 => "12345678", 42 => "123456789012345"}
    scheme = :bin
    master_spec = [{2, 2, :num, 19}, {41, 0, :alphanum, 8}, {42, 0, :alphanum, 15}]

    manually_formed = Base.decode16!("16") <> Base.decode16!("1234567890123456")
    manually_formed = manually_formed <> "12345678"
    manually_formed = manually_formed <> "123456789012345"

    formed = Form.form_fields(msg_map, scheme, master_spec)
    assert(formed == manually_formed)

    manually_formed = <<0b01000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b11000000, 0b00000000, 0b00000000>> <> manually_formed
    formed = Form.form_msg(msg_map, scheme, master_spec)
    assert(formed == manually_formed)

  end


  test "test form msg 2" do
    msg_map = %{
      3 => "930000",
      4 => "000000000010",
      11 => "000001",
      24 => "000",
      41 => "1234567890123456",
      42 => "123456789012345",
      61 => "123",
      64 => "123",
    }
    scheme = :ascii
    master_spec = [{3, 0, :num, 6}, {4, 0, :num, 12}, {11, 0, :num, 6}, {24, 0, :num, 3}, {41, 3, :alphanum, 16}, {42, 3, :alphanum, 15}, {61, 3, :alphanum, 10}, {64, 3, :alphanum, 10}]

    #manually_formed = Base.decode16!("16") <> Base.decode16!("1234567890123456")
    #manually_formed = manually_formed <> "12345678"
    #manually_formed = manually_formed <> "123456789012345"

    formed = Form.form_fields(msg_map, scheme, master_spec)


    #assert(formed == manually_formed)

    #manually_formed = <<0b01000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b11000000, 0b00000000, 0b00000000>> <> manually_formed
    #formed = Form.form_msg(msg_map, scheme, master_spec)
    #assert(formed == manually_formed)

  end


  msg = %{
    3 => "930000",
    4 => "000000000010",
    11 => "000001",
    24 => "000",
    41 => "1234567890123456",
    42 => "123456789012345",
    61 => "123",
    64 => "123",
  }

end
