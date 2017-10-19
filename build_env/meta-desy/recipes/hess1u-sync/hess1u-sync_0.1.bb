SUMMARY = "HESS1U sync init script."
DESCRIPTION = "The sync script syncs the /opt/hess1u folder."
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://../licenses/GPL-2;md5=94d55d512a9ba36caa9b7df079bae19f"
DEPENDS = "base-files rsync dropbear"
PR = "r1"

SRC_URI = "file://hess1u-sync\
		   file://licenses/GPL-2"

INITSCRIPT_NAME = "hess1u-sync"
INITSCRIPT_PARAMS = "defaults 47 47"

inherit update-rc.d

do_install() {
	install -d ${D}${sysconfdir}/init.d/
	install -m 755 ${WORKDIR}/hess1u-sync ${D}${sysconfdir}/init.d/hess1u-sync
}
