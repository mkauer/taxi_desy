require busybox_${PV}.bb

ALTERNATIVE_${PN}-syslog = ""

configmangle-boots = '/CROSS_COMPILER_PREFIX/d; \
                      /CONFIG_EXTRA_CFLAGS/d;'

python () {
  d.setVar('configmangle-boots_append',
                 "/^### CROSS$/a\\\n%s\n" %
                  ("\\n".join(["CONFIG_CROSS_COMPILER_PREFIX=\"${TARGET_PREFIX}\"",
                               "CONFIG_EXTRA_CFLAGS=\"${CFLAGS}\" \"${HOST_CC_ARCH}\""
                        ])
                  ))
}

do_prepare_config () {
	sed -e 's#@DATADIR@#${datadir}#g' \
		< ${WORKDIR}/defconfig > ${S}/.config
	sed -i -e '/CONFIG_STATIC/d' .config
	echo "### CROSS" >> ${S}/.config
	sed -i -e '${configmangle-boots}' ${S}/.config
}

FILESPATH_append = ":${FILE_DIRNAME}/busybox-${PV}"

S = "${WORKDIR}/busybox-${PV}"
