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

## How to use zenoh-bridge-dds

1. copy zenoh-bridge-dds binary under `rootfs_overlay/opt` directory.
2. uncomment line of zenoh-router config/config.exs
```
config :rclex_on_nerves, zenoh_router_ip: System.get_env("ZENOH_ROUTER_IP")
```
3. Set ENV "ZENOH_ROUTER_IP"

### NOTE

Nerves同士の時刻同期が取れていないと以下のログが出る。

> 2022-10-27T11:10:34Z ERROR zenoh::net::routing::pubsub] Error treating timestamp for received Data (incoming timestamp from 9874FE3FBB724868BDFC9299B37E7E66 exceeding delta 500ms is rejected: 2022-10-27T11:14:04.452741976Z vs. now: 2022-10-27T11:10:34.024079553Z): drop it!

publisher がメッセージに（おそらく）付与した時刻と subscriber が受け取った時刻を比較して500msec 以上の開きがある場合は drop していると考えられる。

Nerves で dateコマンドを打ったら時刻ずれが解消し（NTPサーバへの問い合わせが走った？）、drop が起きなくなった。

## turtle_sim demo
参照 : [zenoh-plugin-dds demo](https://github.com/eclipse-zenoh/zenoh-plugin-dds#2-hosts-with-an-intermediate-zenoh-router-in-the-cloud)

### zenoh router
クラウドVM等のグローバルIPの取れる環境を用意し、TCPポート7447を解放しておく
#### install rust
  ```
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

#### install clang
  ```
  sudo apt install clang
  ```
#### source clone
githubから[zenoh(v0.6.0-dev)](https://github.com/eclipse-zenoh/zenoh/releases/tag/0.6.0-dev)をcloneする。(※ 現時点の最新はv0.6.0-beta.1だが、まだ動作できていないため、動作実績のある0.6.0-devで解説する)
  ```
  git clone https://github.com/eclipse-zenoh/zenoh.git -b 0.6.0-dev
  cd zenoh
  ```
#### build
  ```
  cargo build --release --all-targets
  ```
./target/release/下にビルド済みのバイナリが生成される。
#### execute zenohd
zenohd(zenoh router)の起動は単にzenohdを実行するだけでよい。
```
./target/release/zenohd
```

### host pc (ROS2 foxy)
#### install rust and clang
前項のzenoh routerのセットアップと同様に、rust, clangをインストールする。

#### source clone
githubから[zenoh(v0.6.0-dev)](https://github.com/eclipse-zenoh/zenoh/releases/tag/0.6.0-dev)をcloneする。(※ 現時点の最新はv0.6.0-beta.1だが、まだ動作できていないため、動作実績のある0.6.0-devで解説する)
  ```
  git clone git clone https://github.com/eclipse-zenoh/zenoh-plugin-dds.git -b 0.6.0-dev
  cd zenoh
  ```
#### build
  ```
  cargo build --release -p zenoh-bridge-dds
  ```
./target/release/下にビルド済みのバイナリが生成される。
#### execute zenohd
zenoh-bridge-ddsはzenoh routerのIPアドレス(下記xxx部)を指定して実行する。
```
./target/release/zenoh-bridge-dds -e tcp/XXX.XXX.XXX.XXX:7447
```
#### launch turtlesim
別ターミナルを開き、turtlesimを起動する
```
ros2 run turtlesim turtlesim_node
```

### nerves
#### zenoh-bridgeの準備
nervesのビルドの前に、Raspberry Pi向けにビルドしたzenoh-bridge-ddsを用意する必要ある。
Nervesではなく、UbuntuかRaspbianをインストールしたRaspberry Pi環境で、
host pcと同様の手順でzenoh-bridge-ddsをビルドし、zenoh-bridge-ddsのバイナリを開発環境にコピーしておく。

