EAPI=7

inherit linux-info linux-mod eutils

DESCRIPTION="Extensible Virtual Display Interface"
HOMEPAGE="https://github.com/DisplayLink/evdi"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="kernel_linux"

SRC_URI="https://github.com/DisplayLink/evdi/archive/v${PV}.tar.gz -> ${P}.tar.gz"

DEPEND="x11-libs/libdrm
    kernel_linux? ( virtual/linux-sources )"
RDEPEND="x11-libs/libdrm"

MODULE_NAMES="evdi(video:${S}/module)"
CONFIG_CHECK="FB_VIRTUAL"

pkg_setup() {
    linux-mod_pkg_setup
}

src_configure() {
    tc-export AR CC LD

    default
}

src_compile() {
	BUILD_TARGETS=module linux-mod_src_compile \
	    KERNELRELEASE="${KV_FULL}" \
	    src="${KERNEL_DIR}"
	emake -C "${S}/library"
}

src_install() {
	linux-mod_src_install
	dolib.so library/libevdi.so
}

