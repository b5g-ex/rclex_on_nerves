# RclexOnNerves

This repository has been prepared for the demonstration in our presentation at [Code BEAM America 2022](https://codebeamamerica.com).

- Presentation Title: [On the way to achieve autonomous node communication in the Elixir ecosystem](https://codebeamamerica.com/participants/hideki-takase/)
  - [Slide on SpeakerDeck](https://speakerdeck.com/takasehideki/codebeamamerica-20221103)
  - Note: some operations on this repository have been improved from the presentation

You will experience a world of [autonomous node communication (across the Pacific Ocean)](https://twitter.com/takasehideki/status/1588521053311365121) made possible by the combination of [Rclex](https://github.com/rclex/rclex), [Nerves](https://www.nerves-project.org/), and [Zenoh](https://zenoh.io/). 
**Please try it out!!**

## Preliminaries

- Equipments
  - [Raspberry Pi 4](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/) (`${MIX_TARGET}=rpi4`)
  - [Grove Base Hat for Raspberry Pi](https://wiki.seeedstudio.com/Grove_Base_Hat_for_Raspberry_Pi/)
  - [Grove - Thumb Joystick](https://wiki.seeedstudio.com/Grove-Thumb_Joystick/)
  - Internet connectivity with Ethernet
- Software environment
  - Elixir 1.14.0-otp-25
  - Erlang/OTP 25.0.4
  - Docker
    - Please install [Docker Desktop](https://docs.docker.com/desktop/) or [Docker Engine](https://docs.docker.com/engine/), and start it first.
    - Rclex on Nerves will deploy an docker container for arm64 arch. If you want to operate this project by Docker Engine on other platforms (x86_64), you need to install qemu as the follows: `sudo apt-get install qemu binfmt-support qemu-user-static`

This repository is developed and maintained exclusively for `rpi4`.
If you want to try this repository on other boards, please refer to [this section](https://github.com/rclex/rclex/blob/main/USE_ON_NERVES.md#supported-targets) about other supported targets that can operate Rclex on Nerves.

## Notice

It should be noted that do not perform the following steps inside a docker container, since the docker command is used to copy the necessary directory in `mix rclex.prep.ros2`.  
Once again, they can be operated even if ROS 2 is not installed on the host machine!

And also, we assume that an RSA key pair named `nerves_rsa` is prepared.

## How to Install Rclex on Nerves

### Build steps

```
# 1. clone our repository
git clone https://github.com/b5g-ex/rclex_on_nerves.git
cd rclex_on_nerves/

# 2. deps.get
export MIX_TARGET=rpi4
mix deps.get

# 3. prepare ros2 resources
export ROS_DISTRO=foxy
mix rclex.prep.ros2 --arch arm64v8

# 4. generate codes of message types for topic comm.
mix rclex.gen.msgs

# 5. create fw, and burn (or, upload)
mix firmware
mix burn    # or, mix upload
```

### Execution example

#### simple pub/sub for String message

publish String message:

```
iex()> context = Rclex.rclexinit                         
#Reference<0.314340768.268566529.132643>

iex()> publisher = RclexOnNerves.start_publisher(context)
{'talker0', 'chatter', :pub}

iex()> RclexOnNerves.publish(publisher)
:ok
```

subscribe String message:

```
iex()> RingLogger.attach
iex()> context = Rclex.rclexinit                         
#Reference<0.314340768.268566529.132947>

iex()> subscriber = RclexOnNerves.start_subscriber(context)
[:ok]
```

#### Teleop for turtlesim_node

You need to prepare [Grove Base Hat](https://www.seeedstudio.com/Grove-Base-Hat-for-Raspberry-Pi.html) and [Grove - Thumb Joystick](https://wiki.seeedstudio.com/Grove-Thumb_Joystick/), and attach them to Raspberry Pi 4. Note that older HATs may have different I2C address, in which case change the value of `@i2c_addr` to `0x04` in `/lib/rclex_on_nerves/joystick.ex`.

Please execute the following to Teleop "turtlesim_node".

```
iex()> RclexOnNerves.Joystick.start_link                 
{:ok, #PID<0.1225.0>}

iex()> RclexOnNerves.Joystick.start_publish              
%RclexOnNerves.Joystick{
  i2c_ref: #Reference<0.314340768.268566539.124422>,
  init_lin: 502,
  init_ang: 495,
  context: #Reference<0.314340768.268828673.169521>,
  node: 'teleop_joy0',
  publisher: {'teleop_joy0', 'turtle1/cmd_vel', :pub},
  timer: "continus_timer/Timer"
}
Linear: 0.06666666666666667, Angular:0.03333333333333333
Linear: 0.03333333333333333, Angular:0.0
Linear: 0.06666666666666667, Angular:0.03333333333333333
Linear: 0.03333333333333333, Angular:0.0
<cont.>
```

You can operate the behavior of `turtlesim_node` on the host with ROS 2 Foxy by the JoyStick.

```
ros2 run turtlesim turtlesim_node
```

## How to Use Zenoh with Rclex on Nerves

To try this section, the following environments are required to prepare.

- a server that can take a global IP ("aa.bbb.ccc.d" for example in the following explanation) and release TCP port 7447, such as a cloud VM (we use Azure VM), used as the Zenoh router (`zenohd`)
- a host machine with ROS 2 Foxy, running `zenoh-bridge-dds`
- a Raspberry Pi 4 for Rclex on Nerves, running `zenoh-bridge-dds`

Currently, we have confirmed the operation with the source code build of the **v0.6.0-dev tag**.
Although the latest release _v0.6.0-beta.1_ has pre-built binaries available, we could not confirm proper operation with them.  
Therefore, we need to clone the source code and build it by Clang and Rust/Cargo for now.

Also, the following steps assume that the previous section "How to Install Rclex on Nerves" has been completed.

### Build steps for rclex_on_nerves

First of all, we need to build zenoh-bridge-dds v0.6.0-dev targeting aarch64 platform for Raspberry Pi 4. The most simplest way is to prepare Ubuntu OS on your Raspberry Pi 4, and execute the following steps.

```
# install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

# install clang
sudo apt install clang

# clone repo and build from source
git clone git clone https://github.com/eclipse-zenoh/zenoh-plugin-dds.git -b 0.6.0-dev
cd zenoh
cargo build --release -p zenoh-bridge-dds
```

And then, please scp the entire directory `zenoh-plugin-dds/` to your development machine for Nerves.

```
# 1. scp from RPi4 on Ubuntu
scp -r ubuntu@ubuntu:~/zenoh-plugin-dds .

# 2. copy `zenoh-bridge-dds` binary under `./rootfs_overlay/opt/`
cp -f zenoh-plugin-dds/target/release/zenoh-bridge-dds rootfs_overlay/opt

# 3. Set `${ZENOH_ROUTER_IP}` for your server
export ZENOH_ROUTER_IP=aa.bbb.ccc.d

# 4. create fw, and upload
mix firmware
mix upload
```

The execution example is same as in the previous section.
For example, the following will Teleop "turtlesim_node".

```
iex()> RclexOnNerves.Joystick.start_link                 
iex()> RclexOnNerves.Joystick.start_publish              
```

### Prepare Zenoh router and ROS 2 (DDS) client

#### Zenoh router on Cloud VM

Prepare an environment that can take a global IP, such as a cloud VM (we use Azure VM), and release TCP port 7447.

Please clone the repository and build it from the source code by Clang and Rust/Cargo.

```
git clone https://github.com/eclipse-zenoh/zenoh.git -b 0.6.0-dev
cd zenoh
cargo build --release --all-targets
```

The built binary will be located under `./target/release/`.
To start zenohd (zenoh router), simply run `zenohd`.

```
./target/release/zenohd
```

Please also refer to [zenoh-plugin-dds demo](https://github.com/eclipse-zenoh/zenoh-plugin-dds#2-hosts-with-an-intermediate-zenoh-router-in-the-cloud) for more details.

#### Zenoh client on the host with ROS 2 Foxy

Please clone the repository and build it from the source code by Clang and Rust/Cargo.

```
git clone git clone https://github.com/eclipse-zenoh/zenoh-plugin-dds.git -b 0.6.0-dev
cd zenoh
cargo build --release -p zenoh-bridge-dds
```

The built binary will be located under `./target/release/`.
To start zenoh-bridge-dds, the IP address of Zenoh router (global IP of cloud VM) is required as the argument.

```
./target/release/zenoh-bridge-dds -e tcp/aa.bbb.ccc.d:7447
```

For example of the execution, please bringup `turtlesim_node` in the other terminal.

```
ros2 run turtlesim turtlesim_node
```

### NOTE

If the time synchronization between Nerves and other machines is not maintained, the following log will appear.

> 2022-10-27T11:10:34Z ERROR zenoh::net::routing::pubsub] Error treating timestamp for received Data (incoming timestamp from 9874FE3FBB724868BDFC9299B37E7E66 exceeding delta 500ms is rejected: 2022-10-27T11:14:04.452741976Z vs. now: 2022-10-27T11:10:34.024079553Z): drop it!

We guess that if there is a gap of 500 msec or more between the time given to the message by the publisher (probably) and the time received by the subscriber, the message is considered to be dropped.

After we executed `date` command on Nerves, the time discrepancy was resolved (querying the NTP server?), and the drop did not occur anymore. The drop does not occur anymore.
