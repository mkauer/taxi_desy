FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}"

PRINC := "${@int(PRINC) + 1}"

SRC_URI += "file://hess1u-init.d"

# Without this it is not possible to patch checkroot
S = "${WORKDIR}"

do_install_append() {
        install -m 0755 ${WORKDIR}/hess1u-init.d ${D}${sysconfdir}/init.d/hess1u-init.d
        update-rc.d -r ${D} hess1u-init.d defaults 1 99
}
