require hess-image.inc
IMAGE_PREPROCESS_COMMAND="echo console=ttyS0,115200 root=/dev/mtdblock3 rw rootfstype=jffs2 > ${IMAGE_ROOTFS}/boot/cmdline"
export IMAGE_BASENAME="hess-image_2.3"
inherit image

