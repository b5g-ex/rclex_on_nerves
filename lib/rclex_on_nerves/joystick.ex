defmodule RclexOnNerves.Joystick do
  @i2c_name "i2c-1"
  @i2c_addr 0x08

  alias Circuits.I2C
  use Bitwise

  def start_publish do
    {:ok, i2c_ref} = I2C.open(@i2c_name)

    context = Rclex.rclexinit()
    {:ok, node} = Rclex.ResourceServer.create_node(context, 'joystick')
    {:ok, publisher} = Rclex.Node.create_publisher(node, 'StdMsgs.Msg.String', 'pose')

    {:ok, timer} =
      Rclex.ResourceServer.create_timer(
        &pub_callback/1,
        {publisher, i2c_ref},
        100,
        'continus_timer'
      )

    Process.sleep(100_000)

    Rclex.ResourceServer.stop_timer(timer)
    Rclex.Node.finish_job(publisher)
    Rclex.ResourceServer.finish_node(node)
    Rclex.shutdown(context)
  end

  defp pub_callback({publisher, ref}) do
    msg = Rclex.Msg.initialize('StdMsgs.Msg.String')

    data = read_xy(ref)

    str = "Hello World from Rclex! #{data}"
    msg_struct = %Rclex.StdMsgs.Msg.String{data: String.to_charlist(str)}
    Rclex.Msg.set(msg, msg_struct, 'StdMsgs.Msg.String')

    IO.puts("Rclex: Publishing: #{str}")
    Rclex.Publisher.publish([publisher], [msg])
  end

  def open() do
    {:ok, ref} = I2C.open(@i2c_name)
    ref
  end

  def read_xy(ref) do
    x = read_word(ref, 0x30)
    y = read_word(ref, 0x32)
    data = "#{x} : #{y}"
    IO.puts(data)
    data
  end

  defp read_word(ref, register) do
    I2C.write(ref, @i2c_addr, <<register>>)
    Process.sleep(1)
    {:ok, <<low_byte, high_byte>>} = I2C.read(ref, @i2c_addr, 2)
    low_byte ||| high_byte <<< 8
  end
end
