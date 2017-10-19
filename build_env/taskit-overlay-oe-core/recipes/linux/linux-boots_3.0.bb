require linux_${PV}.bb

SRC_URI_append = " \
	file://at91sam9-watchdog-do-not-change-timeout.patch \
"

S = "${WORKDIR}/linux-${PV}"

PROVIDES_stamp9g45 = "virtual/bootloader"
CMDLINE_stamp9g45 = "console=ttyS0,115200 mtdparts=atmel_nand:128k(bootstrap),256k(env),3712k(boot),-(ubi) quiet"
CMDLINE_stamp9g45-256k = "console=ttyS0,115200 mtdparts=atmel_nand:256k(bootstrap),512k(env),4352k(boot),-(ubi) quiet"
CMDLINE_DEBUG_stamp9g45 = ""

FILES_kernel-headers = ""
PACKAGES = ""
PACKAGES_DYNAMIC = ""
INITRAMFS_IMAGE = "boots-image"

KERNEL_IMAGE_BASE_NAME = "${KERNEL_IMAGETYPE}-boots-${PV}-${PR}-${MACHINE}-${DATETIME}"

kernel_do_deploy() {
	install -m 0644 arch/${ARCH}/boot/${KERNEL_IMAGETYPE} ${DEPLOYDIR}/${KERNEL_IMAGE_BASE_NAME}.bin
}

do_configure_prepend() {
	if [ ! -z "${INITRAMFS_IMAGE}" ]; then
		for img in cpio.gz cpio.lzo cpio.lzma cpio.xz; do
		if [ -e "${DEPLOY_DIR_IMAGE}/${INITRAMFS_IMAGE}-${MACHINE}.$img" ]; then
			sed -i -e /CONFIG_INITRAMFS_SOURCE/d ${WORKDIR}/defconfig
			echo "CONFIG_INITRAMFS_SOURCE=\"initramfs.$img\"" >> ${WORKDIR}/defconfig
		fi
		done
	fi
}
