LICENSE = "GPLv3"
LIC_FILES_CHKSUM = "file://LICENSE;md5=9552438152e11a52d83951c8eba1eefa"
DEPENDS = "openssl"
PR = "r3"

SRC_URI = "ftp://ftp.netbsd.org/pub/pkgsrc/distfiles/monit-${PV}.tar.gz\
	file://no-strip-in-makefile.patch \
	file://enable-include-from-etc-monit.d.patch \
	file://init"

INITSCRIPT_NAME = "monit"
INITSCRIPT_PARAMS = "defaults 97 3"

inherit autotools update-rc.d

EXTRA_OECONF = "--without-ssl"

do_install_append() {
	install -d ${D}${sysconfdir}/init.d/
	install -m 755 ${WORKDIR}/init ${D}${sysconfdir}/init.d/monit
}

CONFFILES_${PN} += "/opt/hess1u/monitrc"

SRC_URI[md5sum] = "d3143b0bbd79b53f1b019d2fc1dae656"
SRC_URI[sha256sum] = "f6a29300648381538a403f24506e75b94164e26c69c6861ca112d425edc9d193"
