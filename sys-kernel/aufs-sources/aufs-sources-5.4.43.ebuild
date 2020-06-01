# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

ETYPE="sources"
K_WANT_GENPATCHES="base extras experimental"
K_GENPATCHES_VER=43
UNIPATCH_STRICTORDER=1
inherit kernel-2 eutils readme.gentoo-r1 git-r3

AUFS_VERSION=5.4.3

EGIT_REPO_URI="https://github.com/sfjro/aufs5-standalone.git"
EGIT_BRANCH="aufs5.4.3"

KEYWORDS="~amd64 ~x86"
HOMEPAGE="https://dev.gentoo.org/~mpagano/genpatches http://aufs.sourceforge.net/"
IUSE="experimental module"

DESCRIPTION="Full sources (incl. Gentoo patchset) for the linux kernel tree and aufs5 support"
SRC_URI="
	${KERNEL_URI}
	${ARCH_URI}
	${GENPATCHES_URI}
	"

PDEPEND="=sys-fs/aufs-util-4*"

README_GENTOO_SUFFIX="-r1"

src_unpack() {
	detect_version
	git-r3_src_unpack
	
	UNIPATCH_LIST="
		"${WORKDIR}"/${P}/aufs5-kbuild.patch
		"${WORKDIR}"/${P}/aufs5-base.patch
		"${WORKDIR}"/${P}/aufs5-mmap.patch"

	use module && UNIPATCH_LIST+=" "${WORKDIR}"/${P}/aufs5-standalone.patch"

	einfo "Using aufs5 version: ${AUFS_VERSION} ${UNIPATCH_LIST}"

	kernel-2_src_unpack
}

src_prepare() {
	kernel-2_src_prepare
	if ! use module; then
		sed -e 's:tristate:bool:g' -i "${WORKDIR}"/${P}/fs/aufs/Kconfig || die
	fi
	cp -f "${WORKDIR}"/${P}/include/uapi/linux/aufs_type.h include/uapi/linux/aufs_type.h || die
	cp -rf "${WORKDIR}"/${P}/{Documentation,fs} . || die
}

src_install() {
	kernel-2_src_install
	dodoc "${WORKDIR}"/${P}/{aufs5-loopback,vfs-ino,tmpfs-idr}.patch
	docompress -x /usr/share/doc/${PF}/{aufs5-loopback,vfs-ino,tmpfs-idr}.patch
	readme.gentoo_create_doc
}

pkg_postinst() {
	kernel-2_pkg_postinst
	einfo "For more info on this patchset, and how to report problems, see:"
	einfo "${HOMEPAGE}"
	has_version sys-fs/aufs-util || \
		elog "In order to use aufs FS you need to install sys-fs/aufs-util"

	readme.gentoo_print_elog
}

pkg_postrm() {
	kernel-2_pkg_postrm
}
