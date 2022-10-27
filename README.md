# RclexOnNerves

## How to try

以下の手順は

* docker コンテナの中で行わないで下さい。
  * `mix rclex.prep.ros2` は docker コマンドで copy するため
* ホストマシンに ROS 2 がインストールされていなくても実行できます。

```
# 1. clone
$ git clone git@github.com:b5g-ex/rclex_on_nerves.git
$ cd rclex_on_nerves

# 2. deps.get
$ mix deps.get

# 3. prepare ros2 resources
$ mix rclex.prep.ros2 --arch arm64v8 --ros2-distro foxy

# 4. copy them to rootfs_overlay
$ bash copy_ros2_resources.sh

# 5. generate message type codes
$ mix rclex.gen.msgs --from rootfs_overlay/usr/share

# 6 create fw and burn
$ export MIX_TARGET=rpi4
$ export ROS_DIR=$PWD/rootfs_overlay/usr

$ mix firmware
# The following Nerves packages need to be build:

  nerves_system_rpi4

が表示されたら、 mix deps.get して下さい。これは nerves_system_rpi4 の 最近の artifact をダウンロードしていないために表示されます。

$ mix burn
```

## How to set zenoh-bridge-dds

1. copy zenoh-bridge-dds binary under rootfs_overlay/opt.
2. set zenoh-router ip address to config/config.exs

ex) config :rclex_on_nerves, zenoh_router_ip: "\*.\*.\*.\*"

### NOTE

Nerves同士の時刻同期が取れていないと以下のログが出る。

> 2022-10-27T11:10:34Z ERROR zenoh::net::routing::pubsub] Error treating timestamp for received Data (incoming timestamp from 9874FE3FBB724868BDFC9299B37E7E66 exceeding delta 500ms is rejected: 2022-10-27T11:14:04.452741976Z vs. now: 2022-10-27T11:10:34.024079553Z): drop it!

publisher がメッセージに（おそらく）付与した時刻と subscriber が受け取った時刻を比較して500msec 以上の開きがある場合は drop していると考えられる。

Nerves で dateコマンドを打ったら時刻ずれが解消し（NTPサーバへの問い合わせが走った？）、drop が起きなくなった。
