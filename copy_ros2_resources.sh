#!/bin/bash

rm -rf rootfs_overlay/usr
mkdir -p rootfs_overlay/usr

# copy ROS 2 resources
cp -rf .ros2/resources/from-docker/arm64v8/foxy/opt/ros/foxy/include rootfs_overlay/usr
cp -rf .ros2/resources/from-docker/arm64v8/foxy/opt/ros/foxy/lib rootfs_overlay/usr
cp -rf .ros2/resources/from-docker/arm64v8/foxy/opt/ros/foxy/share rootfs_overlay/usr

# copy vendor resources
cp -rf .ros2/resources/from-docker/arm64v8/foxy/lib/aarch64-linux-gnu/* rootfs_overlay/usr/lib
