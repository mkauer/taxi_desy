require hess-image.inc
IMAGE_PREPROCESS_COMMAND="echo console=ttyS0,115200 root=/dev/nfs nfsroot=192.168.1.1:/opt/hess1u/nfs/root ip=dhcp nfsrootdebug ro nolock > ${IMAGE_ROOTFS}/boot/cmdline"
export IMAGE_BASENAME="hess-image-nfs_2.3"
inherit image

