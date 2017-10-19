FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}"
 
PRINC := "${@int(PRINC) + 1}"

SRC_URI += "file://dropbear_rsa_host_key \
			file://id_rsa.pub \
"

dirs755 += "${sysconfdir}/profile.d \
	        ${sysconfdir}/opkg \
	        ${sysconfdir}/dropbear \
            /data \
            /opt/hess1u \
           "

BASEFILESISSUEINSTALL = "do_install_hess1u"

do_install_hess1u () {
    echo "hess1u" > ${D}${sysconfdir}/hostname

    echo "source /opt/hess1u/setupenv.sourceme" > ${D}${sysconfdir}/profile.d/hess1u.sh

    install -m 644 ${WORKDIR}/issue*  ${D}${sysconfdir}
    install -m 644 ${WORKDIR}/fstab  ${D}${sysconfdir}

    install -m 700 -d ${D}${sysconfdir}/dropbear
    install -m 600 ${WORKDIR}/dropbear_rsa_host_key ${D}${sysconfdir}/dropbear/
    install -m 600 ${WORKDIR}/id_rsa.pub ${D}${sysconfdir}/dropbear/authorized_keys

    install -m 700 -d ${D}/home/root/.ssh
    install -m 600 ${WORKDIR}/id_rsa.pub ${D}/home/root/.ssh/authorized_keys


}

