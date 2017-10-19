
LICENSE="Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=b6b281b97b28a39ba00bd2bc2df39244"
DESCRIPTION = "thrift 0.9.1"
HOMEPAGE = "https://thrift.apache.org/"
SECTION = "console/utils"
PRIORITY = "optional"

DEPENDS = "autoconf automake libtool m4 openssl flex bison boost libevent zlib"
RDEPENDS_${PN} = "boost libevent zlib"

inherit autotools

SRC_URI = "ftp://ftp.fu-berlin.de/unix/www/apache/thrift/0.9.1/thrift-0.9.1.tar.gz \
           file://no_tests.patch \
           file://tprotocol.patch \
           file://cross_compile.patch"

SRC_URI[sha256sum] = "ac175080c8cac567b0331e394f23ac306472c071628396db2850cb00c41b0017"
SRC_URI[md5sum] = "d2e46148f6e800a9492dbd848c66ab6e"

MIRRORS = "http://archive.apache.org/dist/thrift/0.9.1/thrift-0.9.1.tar.gz \
ftp://ftp.halifax.rwth-aachen.de/apache/thrift/0.9.1/thrift-0.9.1.tar.gz \
ftp://ftp-stud.hs-esslingen.de/pub/Mirrors/ftp.apache.org/dist/thrift/0.9.1/thrift-0.9.1.tar.gz \
ftp://mirror.netcologne.de/apache.org/thrift/0.9.1/thrift-0.9.1.tar.gz \
ftp://ftp.fau.de/apache/thrift/0.9.1/thrift-0.9.1.tar.gz"

# Needed for correct packaging of malformed autotools libraries
FILES_${PN} += "${libdir}/lib*.so*"
FILES_${PN}-dev = "${includedir} ${libdir}/lib*.a ${libdir}/*.la \
             ${libdir}/*.o ${libdir}/pkgconfig ${datadir}/pkgconfig \
             ${datadir}/aclocal ${base_libdir}/*.o"
INSANE_SKIP_${PN} += "dev-so"

EXTRA_OECONF="\
    --with-cpp\
    --without-boost\
    --with-libevent\
    --with-zlib\
    --without-qt4\
    --without-c_glib\
    --without-csharp\
    --without-java\
    --without-erlang\
    --without-python\
    --without-perl\
    --without-php\
    --without-php_extension\
    --without-ruby\
    --without-haskell\
    --without-go\
    --without-d\
    --without-openssl\
"

# Autoreconf breaks with
# gnu-configize 'configure.ac' or 'configure.in' is required
do_configure_prepend () {
    sed -e '/AC_CONFIG_SUBDIRS/d' -i ${S}/configure.ac
}
