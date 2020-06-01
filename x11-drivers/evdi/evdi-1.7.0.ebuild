EAPI=5

inherit git-r3 linux-mod eutils

DESCRIPTION="Extensible Virtual Display Interface"
HOMEPAGE="https://github.com/DisplayLink/evdi"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~x86 ~amd64"

EGIT_REPO_URI="https://github.com/DisplayLink/evdi.git"
EGIT_COMMIT="dc595db636845aef39490496bc075f6bf067106c"

DEPEND="x11-libs/libdrm
    sys-kernel/linux-headers"
RDEPEND="x11-libs/libdrm"

MODULE_NAMES="evdi(video:${S}/module)"
CONFIG_CHECK="FB_VIRTUAL"

pkg_setup() {
    linux-mod_pkg_setup
}

src_compile() {
	linux-mod_src_compile
	default
}

src_compile() {
	linux-mod_src_compile
	cd "${S}/library"
	sed -i 's/CFLAGS :=/CFLAGS := -I..\/module/g' Makefile
	default
}

src_install() {
	linux-mod_src_install
	dolib.so library/libevdi.so
}

