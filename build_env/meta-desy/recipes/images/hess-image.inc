LICENSE="MIT"
FILESPATHBASE_LAYER := "${@os.path.dirname(bb.data.getVar('FILE', d, True))}"
LIC_FILES_CHKSUM = "file://${FILESPATHBASE_LAYER}/LICENSE_DESY;md5=ceb9285d11c0fcb404c099b5537c9201"

IMAGE_FEATURES="package-management"

FEED_URIS=" \
all##ftp://camerapc/pub/ipk/all \
armv5te##ftp://camerapc/pub/ipk/armv5te \
stamp9g45##ftp://camerapc/pub/ipk/stamp9g45 \
"

IMAGE_LINGUAS = ""

DISTRO_SSH_DAEMON ?= "dropbear"
DISTRO_PACKAGE_MANAGER ?= "opkg opkg-collateral"

IMAGE_FSTYPES = "tar.gz"

IMAGE_INSTALL += " \
	task-core-boot \
	\
	${DISTRO_PACKAGE_MANAGER} \
	${DISTRO_SSH_DAEMON} \
	mtd-utils \
	boots-utils \
	gdbserver \
	strace \
	kernel-modules \
	module-init-tools \
	\	
	boost\
	protobuf\
	zeromq\
    glog\
    gperftools\
    monit\
    procps\
    thrift\
	\
	gdb\
	openssl\
	rsync\
	ntp\
	inetutils\
	gsl\
	fftw\
	\	
	${@base_contains('MACHINE_FEATURES', 'ext2', 'task-base-ext2', '', d)} \
	${@base_contains('MACHINE_FEATURES', 'vfat', 'task-base-vfat dosfstools', '', d)} \
"

inherit image

