EAPI=6

inherit linux-mod

DESCRIPTION="Extensible Virtual Display Interface"
HOMEPAGE="https://github.com/DisplayLink/evdi"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~x86 ~amd64"

SRC_URI="https://github.com/DisplayLink/evdi/archive/v${PV}.tar.gz -> ${P}.tar.gz"

RDEPEND="x11-libs/libdrm"
DEPEND="${RDEPEND} sys-kernel/linux-headers"

MODULE_NAMES="evdi(video:${S}/module)"
CONFIG_CHECK="~FB_VIRTUAL ~I2C"

pkg_setup() {
    linux-mod_pkg_setup
}

src_compile() {
	BUILD_TARGETS=module linux-mod_src_compile \
	    KERNELRELEASE="${KV_FULL}" \
	    src="${KERNEL_DIR}"
	emake -C "${S}/library"
}

src_install() {
    linux-mod_src_install
    dolib.so library/libevdi.so.${PV}
    dosym libevdi.so.${PV} "/usr/$(get_libdir)/libevdi.so"
}
