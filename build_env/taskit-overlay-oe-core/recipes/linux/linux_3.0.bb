require linux.inc

PR="r1"

COMPATIBLE_MACHINE = "stamp9g45"
DEFAULT_PREFERENCE = "1"

SRC_URI = " \
	${KERNELORG_MIRROR}/linux/kernel/v3.0/linux-3.0.tar.bz2;name=kernel \
	file://atmel-mci_flush_kernel_dcache_page.patch \
	file://defconfig \
"

SRC_URI_append_stamp9g45 = " \
	file://stamp9g45-3.0.patch \
	file://at91sam9g45-sparsemem.patch \
	file://stamp9g45-bch.patch \
	file://stamp9g45-bch-4bit-const.patch \
"
SRC_URI[kernel.md5sum] = "398e95866794def22b12dfbc15ce89c0"
SRC_URI[kernel.sha256sum] = "64b0228b54ce39b0b2df086109a7b737cde58e3df4f779506ddcaccee90356a0"
