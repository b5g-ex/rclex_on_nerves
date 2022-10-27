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

  def start_subscriber(context) do
    {:ok, sub_node} = Rclex.ResourceServer.create_node(context, 'listener')

    {:ok, subscriber} = Rclex.Node.create_subscriber(sub_node, 'StdMsgs.Msg.String', 'chatter')

    Rclex.Subscriber.start_subscribing([subscriber], context, fn msg ->
      recv_msg = Rclex.Msg.read(msg, 'StdMsgs.Msg.String')
      Logger.info("receive: #{List.to_string(recv_msg.data)}")
    end)
  end

  def start_publisher(context) do
    {:ok, pub_node} = Rclex.ResourceServer.create_node(context, 'talker')

    {:ok, publisher} = Rclex.Node.create_publisher(pub_node, 'StdMsgs.Msg.String', 'chatter')

    publisher
  end

  def publish(publisher) do
    msg = Rclex.Msg.initialize('StdMsgs.Msg.String')

    Rclex.Msg.set(
      msg,
      %Rclex.StdMsgs.Msg.String{data: String.to_charlist("Hello Rclex on Nerves")},
      'StdMsgs.Msg.String'
    )

    Rclex.Publisher.publish([publisher], [msg])
  end
end
