# RclexOnNerves

## How to try

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
$ mix burn
```
