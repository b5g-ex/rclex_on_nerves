defmodule RclexOnNerves.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RclexOnNerves.Supervisor]

    children =
      [
        # Children for all targets
        # Starts a worker by calling: RclexOnNerves.Worker.start_link(arg)
        # {RclexOnNerves.Worker, arg},
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: RclexOnNerves.Worker.start_link(arg)
      # {RclexOnNerves.Worker, arg},
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: RclexOnNerves.Worker.start_link(arg)
      # {RclexOnNerves.Worker, arg},
    ] ++ zenoh_bridge_dds()
  end

  def target() do
    Application.get_env(:rclex_on_nerves, :target)
  end

  @spec zenoh_bridge_dds() :: list()
  def zenoh_bridge_dds() do
    zenoh_bridge_dds = "/opt/zenoh-bridge-dds"
    ip = Application.get_env(:rclex_on_nerves, :zenoh_router_ip)

    if File.exists?(zenoh_bridge_dds) and not is_nil(ip) do
      Logger.info("start zenoh-bridge-dds, server is #{ip}")
      [{MuonTrap.Daemon, [zenoh_bridge_dds, ["-e", "tcp/#{ip}:7447"]]}]
    else
      []
    end
  end
end
