EAPI=6

inherit git-r3 linux-mod eutils

DESCRIPTION="Extensible Virtual Display Interface"
HOMEPAGE="https://github.com/aircrack-ng/rtl8812au"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~x86 ~amd64"

EGIT_REPO_URI="https://github.com/aircrack-ng/rtl8812au.git"
EGIT_BRANCH="v5.6.4.2"

DEPEND="sys-kernel/linux-headers"
RDEPEND=""

MODULE_NAMES="88XXau(net/wireless)"
#CONFIG_CHECK="FB_VIRTUAL"

pkg_setup() {
    linux-mod_pkg_setup
}

src_compile() {
	BUILD_TARGETS="modules"
	linux-mod_src_compile
}

src_install() {
	linux-mod_src_install
}

