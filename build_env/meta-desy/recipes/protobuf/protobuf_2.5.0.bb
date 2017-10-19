LICENSE="GPLv3"

LIC_FILES_CHKSUM = "file://COPYING.txt;md5=af6809583bfde9a31595a58bb4a24514"
DESCRIPTION = "google protocol buffers 2.5.0"
HOMEPAGE = "http://protobuf.googlecode.com"
SECTION = "console/utils"
PRIORITY = "optional"

SRC_URI = "http://protobuf.googlecode.com/files/protobuf-2.5.0.tar.gz "
SRC_URI[md5sum] = "b751f772bdeb2812a2a8e7202bf1dae8"
SRC_URI[sha256sum] = "c55aa3dc538e6fd5eaf732f4eb6b98bdcb7cedb5b91d3b5bdcf29c98c293f58e"

EXTRA_OECONF += " --with-protoc=echo"

inherit autotools
