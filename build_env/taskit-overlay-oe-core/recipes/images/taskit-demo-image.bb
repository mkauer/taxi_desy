LICENSE="MIT"
FILESPATHBASE_LAYER := "${@os.path.dirname(bb.data.getVar('FILE', d, True))}"
LIC_FILES_CHKSUM = "file://${FILESPATHBASE_LAYER}/../../LICENSE;md5=3ef3bc6a418b731c5c8b05d31db110eb"

FEED_URIS=" \
all##http://downloads.yoctoproject.org/releases/yocto/yocto-1.4/ipk/all \
armv5te##http://downloads.yoctoproject.org/releases/yocto/yocto-1.4/ipk/armv5te \
"

IMAGE_FEATURES="package-management"

IMAGE_PREPROCESS_COMMAND="echo console=ttyS0,115200 root=/dev/mmcblk0p1 rootwait mmc_core.removable=0 > ${IMAGE_ROOTFS}/boot/cmdline"

DISTRO_SSH_DAEMON ?= "dropbear"
DISTRO_PACKAGE_MANAGER ?= "opkg opkg-collateral"

IMAGE_LINGUAS = "en-gb de-de fr-fr"

IMAGE_INSTALL += " \
	task-core-boot \
	\
	${DISTRO_PACKAGE_MANAGER} \
	${DISTRO_SSH_DAEMON} \
	openssh-sftp-server \
	avahi-daemon \
	avahi-autoipd \
	mtd-utils \
	boots-utils \
	gdbserver \
	strace \
	qt4-embedded-examples \
	qt4-embedded-fonts \
	lighttpd \
	lighttpd-module-alias \
	lighttpd-module-auth \
	lighttpd-module-cgi \
	lighttpd-module-compress \
	lighttpd-module-fastcgi \
	lighttpd-module-evhost \
	lighttpd-module-redirect \
	lighttpd-module-rewrite \
	lighttpd-module-setenv \
	lighttpd-module-simple-vhost \
	fastcgi \
	kernel-modules \
	module-init-tools \
	${@base_contains('MACHINE_FEATURES', 'ext2', 'task-base-ext2', '', d)} \
	${@base_contains('MACHINE_FEATURES', 'usbhost', 'task-base-usbhost', '', d)} \
	${@base_contains('MACHINE_FEATURES', 'usbgadget', 'task-base-usbgadget', '', d)} \
	${@base_contains('MACHINE_FEATURES', 'vfat', 'task-base-vfat dosfstools', '', d)} \
	${@base_contains('DISTRO_FEATURES', 'ppp', 'task-base-ppp', '', d)} \
"

export IMAGE_BASENAME="taskit-demo-image"

inherit image

