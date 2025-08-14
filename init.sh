#!/bin/sh

# Setup /proc /sys and /dev
mkdir -p /proc /sys /dev
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev

while [ 1 ]
do
    bash
	echo '>>> Tried to exit the shell, this is forbidden <<<'
done
