# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="Lightweight persistent shell sessions (tmux without the terminal emulation)"
HOMEPAGE="https://github.com/shell-pool/shpool"
SRC_URI="
	amd64? ( https://github.com/shell-pool/shpool/releases/download/v${PV}/shpool-x86_64-unknown-linux-gnu.tar.gz -> ${P}-amd64.tar.gz )
	arm64? ( https://github.com/shell-pool/shpool/releases/download/v${PV}/shpool-aarch64-unknown-linux-gnu.tar.gz -> ${P}-arm64.tar.gz )
"
S="${WORKDIR}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
RESTRICT="strip"

RDEPEND=">=sys-libs/glibc-2.34"

QA_PREBUILT="usr/bin/shpool"

src_install() {
	dobin shpool
	systemd_douserunit "${FILESDIR}"/shpool.service "${FILESDIR}"/shpool.socket
}
