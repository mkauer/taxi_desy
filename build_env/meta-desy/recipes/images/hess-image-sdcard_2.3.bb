require hess-image.inc
IMAGE_PREPROCESS_COMMAND="echo console=ttyS0,115200 root=/dev/mmcblk0p1 rootwait mmc_core.removable=0 > ${IMAGE_ROOTFS}/boot/cmdline"
export IMAGE_BASENAME="hess-image-sdcard_2.3"
inherit image

