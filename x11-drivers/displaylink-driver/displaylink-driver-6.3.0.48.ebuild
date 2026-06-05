# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd udev

DESCRIPTION="DisplayLink USB Graphics Software (DL-3x00/4x00/5x00/6x00 docks and adapters)"
HOMEPAGE="https://www.synaptics.com/products/displaylink-graphics"
SRC_URI="${P}.zip"
S="${WORKDIR}"

LICENSE="DisplayLink-EULA"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+systemd"

# Proprietary, EULA-gated manual download; prebuilt binary -> do not strip/mirror.
RESTRICT="fetch bindist mirror strip"

RDEPEND="
	>=x11-drivers/evdi-1.14.16[dist-kernel]
	sys-apps/util-linux
	systemd? ( sys-apps/systemd )
	!systemd? ( sys-auth/elogind )
"
DEPEND="${RDEPEND}"
BDEPEND="app-arch/unzip"

QA_PREBUILT="opt/displaylink/.*"

pkg_nofetch() {
	einfo "DisplayLink driver is a proprietary, EULA-restricted download."
	einfo "Get 'DisplayLink USB Graphics Software for Ubuntu 6.3' (.zip) from:"
	einfo "    ${HOMEPAGE}/downloads/ubuntu"
	einfo "rename it to ${P}.zip and place it into your DISTDIR:"
	einfo "    ${DISTDIR}"
}

src_unpack() {
	# default unzips ${P}.zip, leaving displaylink-driver-*.run in ${WORKDIR}
	default
	# makeself self-extractor; --nox11 prevents it from spawning a terminal in the sandbox
	sh "${WORKDIR}"/displaylink-driver-*.run \
		--nox11 --noexec --keep --target "${WORKDIR}/extracted" \
		|| die "makeself extraction failed"
}

src_install() {
	local core="/opt/displaylink"
	local bins="${WORKDIR}/extracted/x64-ubuntu-1604"

	exeinto "${core}"
	doexe "${bins}/DisplayLinkManager"

	# Bundled libusb: DisplayLinkManager has RUNPATH='.' and the service runs it
	# with WorkingDirectory=/opt/displaylink, so it loads libusb from there.
	local libusb
	libusb=$(basename "$(echo "${bins}"/libusb-1.0.so.[0-9]*)")
	doexe "${bins}/${libusb}"
	dosym "${libusb}" "${core}/libusb-1.0.so.0"
	dosym "${libusb}" "${core}/libusb-1.0.so"

	# Device firmware blobs and licenses.
	insinto "${core}"
	doins "${WORKDIR}"/extracted/*.spkg
	doins "${WORKDIR}/extracted/LICENSE"
	doins "${WORKDIR}/extracted/3rd_party_licences.txt"

	# udev hotplug bootstrap + rule (calls /opt/displaylink/udev.sh).
	exeinto "${core}"
	doexe "${FILESDIR}/udev.sh"
	udev_dorules "${FILESDIR}/99-displaylink.rules"

	keepdir /var/log/displaylink

	# Init system is selected by the 'systemd' USE flag (set by the profile);
	# the suspend hook uses the shared systemd/elogind system-sleep interface.
	if use systemd; then
		systemd_dounit "${FILESDIR}/dlm.service"
		exeinto /usr/lib/systemd/system-sleep
		newexe "${FILESDIR}/pm-systemd-displaylink" displaylink.sh
	else
		newinitd "${FILESDIR}/displaylink.initd" dlm
		exeinto /usr/lib/elogind/system-sleep
		newexe "${FILESDIR}/pm-systemd-displaylink" displaylink.sh
	fi
}

pkg_postinst() {
	udev_reload
	elog "DisplayLinkManager runs as a background service."
	if use systemd; then
		elog "  systemctl enable --now dlm.service"
	else
		elog "  rc-update add dlm default && rc-service dlm start"
	fi
	elog
	elog "The evdi kernel module is provided by x11-drivers/evdi and is loaded"
	elog "automatically by the service. After plugging in a DisplayLink dock,"
	elog "configure the new output with wlr-randr/kanshi (Wayland) or xrandr (X11)."
}
