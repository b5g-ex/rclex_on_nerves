# This file is responsible for configuring your application and its
# dependencies.
#
# This configuration file is loaded before any dependency and is restricted to
# this project.
import Config

# Enable the Nerves integration with Mix
Application.start(:nerves_bootstrap)

config :rclex_on_nerves, target: Mix.target()
# Set IP address for Zenoh router if you want to connect it
config :rclex_on_nerves, zenoh_router_ip: System.get_env("ZENOH_ROUTER_IP")

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Set the SOURCE_DATE_EPOCH date for reproducible builds.
# See https://reproducible-builds.org/docs/source-date-epoch/ for more information

config :nerves, source_date_epoch: "1664934221"

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :logger, backends: [RingLogger]

config :rclex, ros2_message_types: ["std_msgs/msg/String", "geometry_msgs/msg/Twist"]

config :nerves_time, await_initialization_timeout: :timer.seconds(5)

if Mix.target() == :host do
  import_config "host.exs"
else
  import_config "target.exs"
end
