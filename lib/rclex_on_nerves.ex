defmodule RclexOnNerves do
  @moduledoc """
  Documentation for RclexOnNerves.
  """

  require Logger

  @doc """
  Hello world.

  ## Examples

      iex> RclexOnNerves.hello
      :world

  """
  def hello do
    :world
  end

  def test do
    context = Rclex.rclexinit()
    str_data = "data"
    pid = self()

    {:ok, sub_node} = Rclex.ResourceServer.create_node(context, 'listener')

    {:ok, subscriber} = Rclex.Node.create_subscriber(sub_node, 'StdMsgs.Msg.String', 'chatter')

    Rclex.Subscriber.start_subscribing([subscriber], context, fn msg ->
      recv_msg = Rclex.Msg.read(msg, 'StdMsgs.Msg.String')

      if List.to_string(recv_msg.data) == str_data do
        _msg_data = List.to_string(recv_msg.data)
        send(pid, :message_received)
      end
    end)

    {:ok, pub_node} = Rclex.ResourceServer.create_node(context, 'talker')

    {:ok, publisher} = Rclex.Node.create_publisher(pub_node, 'StdMsgs.Msg.String', 'chatter')

    {:ok, timer} =
      Rclex.ResourceServer.create_timer_with_limit(
        fn publisher ->
          msg = Rclex.Msg.initialize('StdMsgs.Msg.String')

          Rclex.Msg.set(
            msg,
            %Rclex.StdMsgs.Msg.String{data: String.to_charlist(str_data)},
            'StdMsgs.Msg.String'
          )

          Rclex.Publisher.publish([publisher], [msg])
        end,
        publisher,
        100,
        'continus_timer',
        1
      )

    receive do
      :message_received ->
        Logger.info("received")
    after
      500 ->
        Logger.info("timeout")
    end

    Rclex.ResourceServer.stop_timer(timer)
    Rclex.Subscriber.stop_subscribing([subscriber])
    Rclex.Node.finish_jobs([publisher, subscriber])
    Rclex.ResourceServer.finish_nodes([pub_node, sub_node])
    Rclex.shutdown(context)
  end
end
