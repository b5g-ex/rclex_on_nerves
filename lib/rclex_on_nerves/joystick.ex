defmodule RclexOnNerves.Joystick do
  @i2c_name "i2c-1"
  @i2c_addr 0x08

  @coeff_lin 10.0
  @coeff_ang 10.0

  alias Circuits.I2C
  use Bitwise

  def start_publish do
    {:ok, i2c_ref} = I2C.open(@i2c_name)

    context = Rclex.rclexinit()
    {:ok, node} = Rclex.ResourceServer.create_node(context, 'teleop_joy')

    {:ok, publisher} =
      Rclex.Node.create_publisher(node, 'GeometryMsgs.Msg.Twist', 'turtle1/cmd_vel')

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
    msg = Rclex.Msg.initialize('GeometryMsgs.Msg.Twist')
    twist = read_twist(ref)

    Rclex.Msg.set(msg, twist, 'GeometryMsgs.Msg.Twist')

    Rclex.Publisher.publish([publisher], [msg])
  end

  def open() do
    {:ok, ref} = I2C.open(@i2c_name)
    ref
  end

  def read_twist(ref) do
    linear = read_word(ref, 0x30) / @coeff_lin
    angular = read_word(ref, 0x32) / @coeff_ang
    IO.puts("x: #{linear}, y: #{angular}")

    %Rclex.GeometryMsgs.Msg.Twist{
      linear: %Rclex.GeometryMsgs.Msg.Vector3{x: linear, y: 0.0, z: 0.0},
      angular: %Rclex.GeometryMsgs.Msg.Vector3{x: 0.0, y: 0.0, z: angular}
    }
  end

  defp read_word(ref, register) do
    I2C.write(ref, @i2c_addr, <<register>>)
    Process.sleep(1)
    {:ok, <<low_byte, high_byte>>} = I2C.read(ref, @i2c_addr, 2)
    low_byte ||| high_byte <<< 8
  end
end
