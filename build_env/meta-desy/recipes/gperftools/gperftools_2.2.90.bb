SUMMARY = "Fast, multi-threaded malloc() and nifty performance analysis tools"
HOMEPAGE = "http://code.google.com/p/gperftools/"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://COPYING;md5=762732742c73dc6c7fbe8632f06c059a"
DEPENDS = "libunwind"
SRC_URI = "https://googledrive.com/host/0B6NtGsLhIcf7MWxMMF9JdTN3UVk/gperftools-${PV}.tar.gz"
SRC_URI[md5sum] = "616e30c1ab204a40e74bda25588f0bff"
SRC_URI[sha256sum] = "6cc2c832060dc47da295954fa1a5646a725b6071da6dd89b39566fd7eee1c76c"
inherit autotools

