PACKAGE_ARCH = "${MACHINE_ARCH}"
LICENSE="GPLv2"
PR="r0"

LIC_FILES_CHKSUM = "file://COPYING;md5=a120b594d4a52e7fb4b62b6978f3a383"

SRC_URI = " \
	http://download.armbedded.eu/software/boots/boots-${PV}.tar.bz2 \
	file://fw_env.h \
"

PACKAGES =+ "boots-utils"
RDEPENDS_${PN} = "kexec boots-utils"
RRECOMMENDS_boots-utils = "mtd-utils mtd-utils-jffs2 mtd-utils-ubifs"

FILES_boots-utils = " \
	${base_sbindir}/fw_printenv \
	${base_sbindir}/fw_setenv \
"

FILES_${PN} += "/sbin/init"

do_configure() {
	if [ -f "${WORKDIR}/fw_env.h" ]; then
		cp "${WORKDIR}/fw_env.h" "${S}/src/"
	fi
}

do_install() {
	oe_runmake install DESTDIR=${D}
}

SRC_URI[md5sum] = "fcc3e7d9e062cebeb4538ef24b63b576"
SRC_URI[sha256sum] = "b4b00f7283bcc44aed6d61e90d4a0d3b6b87ded82f08cce0aa5bbd182e7099de"
