LICENSE="MIT"
FILESPATHBASE_LAYER := "${@os.path.dirname(bb.data.getVar('FILE', d, True))}"
LIC_FILES_CHKSUM = "file://${FILESPATHBASE_LAYER}/../../LICENSE;md5=3ef3bc6a418b731c5c8b05d31db110eb"

IMAGE_INSTALL="busybox-boots boots lrzsz e2fsprogs-e2fsck e2fsprogs-mke2fs e2fsprogs-tune2fs"
IMAGE_BASENAME="boots-image"

IMAGE_DEV_MANAGER=""
IMAGE_LOGIN_MANAGER=""
IMAGE_INIT_MANAGER=""
IMAGE_INITSCRIPTS=""
IMAGE_DEVICE_TABLES="files/device_table-console.txt"
IMAGE_LINGUAS=""

ANGSTROM_FEED_CONFIGS=""
ONLINE_PACKAGE_MANAGEMENT=""

IMAGE_FSTYPES = "cpio.gz"

IMAGE_PREPROCESS_COMMAND="ln -s /sbin/boots-init ${IMAGE_ROOTFS}/init"

inherit image
