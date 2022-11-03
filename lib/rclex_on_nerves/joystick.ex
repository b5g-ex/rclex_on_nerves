defmodule RclexOnNerves.Joystick do
  use GenServer
  import Bitwise
  require Logger
  alias Circuits.I2C

  @i2c_name "i2c-1"
  @i2c_addr 0x08

  @coeff_lin 30.0
  @coeff_ang 30.0

  defstruct i2c_ref: nil,
            init_lin: 0.0,
            init_ang: 0.0,
            context: nil,
            node: nil,
            publisher: nil,
            timer: nil

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(_),
    do: {:ok, %RclexOnNerves.Joystick{}}

  def terminate(_reason, %RclexOnNerves.Joystick{
        timer: timer,
        publisher: publisher,
        node: node,
        context: context
      }) do
    Rclex.ResourceServer.stop_timer(timer)
    Rclex.Node.finish_job(publisher)
    Rclex.ResourceServer.finish_node(node)
    Rclex.shutdown(context)
  end

  def start_publish, do: GenServer.call(__MODULE__, :start_publish)

  def pub_callback(_), do: GenServer.call(__MODULE__, :pub_callback)

  def handle_call(:start_publish, _from, _) do
    {:ok, i2c_ref} = I2C.open(@i2c_name)

    context = Rclex.rclexinit()
    {:ok, node} = Rclex.ResourceServer.create_node(context, 'teleop_joy')

    {:ok, publisher} =
      Rclex.Node.create_publisher(node, 'GeometryMsgs.Msg.Twist', 'turtle1/cmd_vel')

    init_lin = read_word(i2c_ref, 0x30)
    init_ang = read_word(i2c_ref, 0x32)

    {:ok, timer} =
      Rclex.ResourceServer.create_timer(
        &pub_callback/1,
        {},
        100,
        'continus_timer'
      )

    spawn(fn ->
      Process.sleep(30_000)
      GenServer.stop(__MODULE__)
    end)

    new_state = %RclexOnNerves.Joystick{
      i2c_ref: i2c_ref,
      init_lin: init_lin,
      init_ang: init_ang,
      context: context,
      node: node,
      publisher: publisher,
      timer: timer
    }

    {:reply, new_state, new_state}
  end

  def handle_call(
        :pub_callback,
        _from,
        state = %RclexOnNerves.Joystick{
          i2c_ref: i2c_ref,
          init_lin: init_lin,
          init_ang: init_ang,
          publisher: publisher
        }
      ) do
    msg = Rclex.Msg.initialize('GeometryMsgs.Msg.Twist')
    twist = read_twist(i2c_ref, init_lin, init_ang)

    Rclex.Msg.set(msg, twist, 'GeometryMsgs.Msg.Twist')

    Rclex.Publisher.publish([publisher], [msg])
    {:reply, state, state}
  end

  defp read_twist(i2c_ref, init_lin, init_ang) do
    linear = (read_word(i2c_ref, 0x30) - init_lin) / @coeff_lin
    angular = (read_word(i2c_ref, 0x32) - init_ang) / @coeff_ang
    IO.puts("Linear: #{linear}, Angular:#{angular}")

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
