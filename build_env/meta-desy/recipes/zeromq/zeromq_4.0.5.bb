LICENSE="GPLv3"

LIC_FILES_CHKSUM = "file://COPYING;md5=f7b40df666d41e6508d03e1c207d498f"
DESCRIPTION = "zeromq 4.0.5"
HOMEPAGE = "http://zeromq.org/"
SECTION = "console/utils"
PRIORITY = "optional"

SRC_URI = "http://download.zeromq.org/zeromq-4.0.5.tar.gz"
SRC_URI[sha256sum] = "3bc93c5f67370341428364ce007d448f4bb58a0eaabd0a60697d8086bc43342b"
SRC_URI[md5sum] = "73c39f5eb01b9d7eaf74a5d899f1d03d"

inherit autotools
