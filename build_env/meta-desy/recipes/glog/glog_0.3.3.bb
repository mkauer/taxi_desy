LICENSE="GPLv3"

LIC_FILES_CHKSUM = "file://COPYING;md5=dc9db360e0bbd4e46672f3fd91dd6c4b"
DESCRIPTION = "google glog 0.3.3"
HOMEPAGE = "https://google-glog.googlecode.com"
SECTION = "console/utils"
PRIORITY = "optional"

SRC_URI = "https://google-glog.googlecode.com/files/glog-0.3.3.tar.gz "
SRC_URI[md5sum] = "a6fd2c22f8996846e34c763422717c18"
SRC_URI[sha256sum] = "fbf90c2285ba0561db7a40f8a4eefb9aa963e7d399bd450363e959929fe849d0"


#EXTRA_OECONF += " "

inherit autotools
