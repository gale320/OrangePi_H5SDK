#!/bin/bash
set -e
##############################################
##
## Compile kernel
##
##############################################
if [ -z $ROOT ]; then
	ROOT=`cd .. && pwd`
fi
# Platform
if [ -z $PLATFORM ]; then
	PLATFORM="OrangePiH5_PC2"
fi
# Cleanup
if [ -z $CLEANUP ]; then
	CLEANUP="0"
fi
# kernel option
if [ -z $BUILD_KERNEL ]; then
	BUILD_KERNEL="0"
fi
# module option
if [ -z $BUILD_MODULE ]; then
	BUILD_MODULE="0"
fi
# Knernel Direct
LINUX=$ROOT/kernel
# Compile Toolchain
TOOLS=$ROOT/toolchain/gcc-linaro-aarch/bin/aarch64-linux-gnu-
# OUTPUT DIRECT
BUILD=$ROOT/output

if [ ! -d $BUILD ]; then
	mkdir -p $BUILD
fi 

# Perpare souce code
if [ -d $LINUX ]; then
	echo "Kernel exist and compile kernel"
else
	echo "Kernel doesn't exist, pls perpare linux source code."
	exit 0
fi

echo -e "\e[1;31m Start Compile.....\e[0m"

if [ $CLEANUP = "1" ]; then
	make -C $LINUX ARCH=arm64 CROSS_COMPILE=$TOOLS clean
	echo -e "\e[1;31m Clean up kernel \e[0m"
fi

if [ ! -f $LINUX/.config ]; then
	make -C $LINUX ARCH=arm64 CROSS_COMPILE=$TOOLS ${PLATFORM}_linux_defconfig
	echo -e "\e[1;31m Using ${PLATFROM}_linux_defconfig \e[0m"
fi

if [ $BUILD_KERNEL = "1" ]; then
	# make kernel
	make -C $LINUX ARCH=arm64 CROSS_COMPILE=$TOOLS -j4 Image
fi

if [ $BUILD_MODULE = "1" ]; then
	# make module
	echo -e "\e[1;31m Start Compile Module \e[0m"
	make -C $LINUX ARCH=arm64 CROSS_COMPILE=$TOOLS -j4 modules

	# install module
	echo -e "\e[1;31m Start Install Module \e[0m"
	make -C $LINUX ARCH=arm64 CROSS_COMPILE=$TOOLS -j4 modules_install INSTALL_MOD_PATH=$BUILD
fi

if [ $BUILD_KERNEL = "1" ]; then
	# compile dts
	echo -e "\e[1;31m Start Compile DTS \e[0m"
	$ROOT/kernel/scripts/dtc/dtc -Odtb -o "$BUILD/OrangePiH5.dtb" "$LINUX/arch/arm64/boot/dts/${PLATFORM}.dts"
	## DTB conver to DTS
	# Command:
	# dtc -I dtb -O dts -o target_file.dts source_file.dtb

	# Perpare uImage
	mkimage -A arm -n "OrangePiH5" -O linux -T kernel -C none -a 0x40080000 -e 0x40080000 \
		-d $LINUX/arch/arm64/boot/Image $BUILD/uImage

	## Create uEnv.txt
	echo -e "\e[1;31m Create uEnv.txt \e[0m"
cat <<EOF > "$BUILD/uEnv.txt"
console=tty0 console=ttyS0,115200n8 no_console_suspend
kernel_filename=orangepi/uImage
initrd_filename=initrd.img
EOF

	## Build initrd.img
	echo -e "\e[1;31m Build initrd.img \e[0m"
	cp -rfa $ROOT/external/initrd.img $BUILD
fi 

clear
echo -e "\e[1;31m ============================== \e[0m"
echo -e "\e[1;31m Build Kernel OK \e[0m"
echo -e "\e[1;31m ============================== \e[0m"
echo -e "\e[1;31m Kernel: ${BUILD}/uImage \e[0m"
echo -e "\e[1;31m Module: ${BUILD}/lib/ \e[0m"
echo -e "\e[1;31m DTB:    ${BUILD}/OrangePiH5.dtb \e[0m"
echo -e "\e[1;31m uEnv:   ${BUILD}/uEnv.txt \e[0m"
echo -e "\e[1;31m initrd: ${BUILD}/initrd.img \e[0m"
echo ""







