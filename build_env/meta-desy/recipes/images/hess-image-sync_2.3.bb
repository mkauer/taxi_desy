require hess-image.inc
IMAGE_PREPROCESS_COMMAND="echo console=ttyS0,115200 root=/dev/mtdblock3 rw rootfstype=jffs2 > ${IMAGE_ROOTFS}/boot/cmdline"
export IMAGE_BASENAME="hess-image-sync_2.3"
ROOTFS_POSTPROCESS_COMMAND += "sed -i 's/^camerapc/#camerapc/' ${IMAGE_ROOTFS}/etc/fstab; "
IMAGE_INSTALL += "hess1u-sync"
inherit image

