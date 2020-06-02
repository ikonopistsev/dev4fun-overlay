# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit eutils systemd udev unpacker

DESCRIPTION="DisplayLink USB Graphics Software"
HOMEPAGE="http://www.displaylink.com/downloads/ubuntu"
LICENSE="DisplayLink"
SRC_URI="${P}.zip"
RUN_PN="displaylink-driver"

SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="systemd"

QA_PREBUILT="/opt/displaylink/DisplayLinkManager"
RESTRICT="fetch"

DEPEND="app-admin/chrpath"
RDEPEND=">=sys-devel/gcc-4.8.3
    >=x11-drivers/evdi-1.5.0
    virtual/libusb:1
    || ( x11-drivers/xf86-video-modesetting >=x11-base/xorg-server-1.17.0 )"

PATCHES=(
    "${FILESDIR}"/${PN}-${PV}-openrc.patch
)

pkg_nofetch() {
    einfo "Please download DisplayLink USB Graphics Software for Ubuntu 5.3.1.zip from"
    einfo "$HOMEPAGE"
    einfo "and rename it to ${P}.zip"
}

src_prepare() {
    mkdir -p "${TMPDIR}"
    default
}

src_unpack() {
    default
    sh ./${RUN_PN}-${PV}.*.run --noexec --target "${P}"
}

src_install() {
    if [[ ( $(gcc-major-version) -eq 5 && $(gcc-minor-version) -ge 1 ) || $(gcc-major-version) -gt 5 ]]; then
	MY_UBUNTU_VERSION=1604
    else
	die
    fi

    einfo "Using package for Ubuntu ${MY_UBUNTU_VERSION} based on your gcc version: $(gcc-version)"

    case "${ARCH}" in
	amd64)	MY_ARCH="x64" ;;
	*)		MY_ARCH="${ARCH}" ;;
    esac

    DLM="${S}/${MY_ARCH}-ubuntu-${MY_UBUNTU_VERSION}/DisplayLinkManager"

    dodir /opt/displaylink
    dodir /var/log/displaylink

    exeinto /opt/displaylink
    chrpath -d "${DLM}"
    doexe "${DLM}"

    insinto /opt/displaylink
    doins *.spkg

    insinto /opt/displaylink
    insopts -m0755
    if use systemd; then
	sh ./udev-installer.sh systemd displaylink.rules udev.sh
	newins "udev.sh" udev.sh
	udev_newrules displaylink.rules 99-displaylink.rules
	systemd_dounit "${FILESDIR}/dlm.service"
    else
	sh ./udev-installer.sh openrc displaylink.rules udev.sh
	newins "udev.sh" udev.sh
	udev_newrules displaylink.rules 99-displaylink.rules
	newinitd "${FILESDIR}"/dlm.openrc dlm
    fi
}

pkg_postinst() {
    udev_reload
    
    einfo "The DisplayLinkManager Init is now called dlm"
    einfo ""
    einfo "You should be able to use xrandr as follows:"
    einfo "xrandr --setprovideroutputsource 1 0"
    einfo "Repeat for more screens, like:"
    einfo "xrandr --setprovideroutputsource 2 0"
    einfo "Then, you can use xrandr or GUI tools like arandr to configure the screens, e.g."
    einfo "xrandr --output DVI-1-0 --auto"
}
