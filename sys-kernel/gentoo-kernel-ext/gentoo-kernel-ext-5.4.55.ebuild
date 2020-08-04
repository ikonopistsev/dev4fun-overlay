# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit kernel-build git-r3

MY_P=linux-${PV%.*}
GENPATCHES_P=genpatches-${PV%.*}-${PV##*.}
# https://git.archlinux.org/svntogit/packages.git/log/trunk/config?h=packages/linux
AMD64_CONFIG_VER=5.4.15-arch1
AMD64_CONFIG_HASH=dc8d69b59a7a529ec5aaeb6b32b16e59a3cc1569
# https://git.archlinux32.org/packages/log/core/linux/config.i686
I686_CONFIG_VER=5.4.15-arch1
I686_CONFIG_HASH=1ad219bd3f0ab439a81ed01fec7660eeea7daa0e
# aufs

DESCRIPTION="Linux kernel built with Gentoo patches"
HOMEPAGE="https://www.kernel.org/"
SRC_URI+=" https://cdn.kernel.org/pub/linux/kernel/v$(ver_cut 1).x/${MY_P}.tar.xz
	https://dev.gentoo.org/~mpagano/dist/genpatches/${GENPATCHES_P}.base.tar.xz
	https://dev.gentoo.org/~mpagano/dist/genpatches/${GENPATCHES_P}.extras.tar.xz
	https://dev.gentoo.org/~mpagano/dist/genpatches/${GENPATCHES_P}.experimental.tar.xz
	amd64? (
		https://git.archlinux.org/svntogit/packages.git/plain/trunk/config?h=packages/linux&id=${AMD64_CONFIG_HASH}
			-> linux-${AMD64_CONFIG_VER}.amd64.config
	)
	x86? (
		https://git.archlinux32.org/packages/plain/core/linux/config.i686?id=${I686_CONFIG_HASH}
			-> linux-${I686_CONFIG_VER}.i686.config
	)"
S=${WORKDIR}/${MY_P}


AUFS_VERSION=5.4.3
EGIT_REPO_URI="https://github.com/sfjro/aufs5-standalone.git"
EGIT_BRANCH="aufs5.4.3"
EGIT_CHECKOUT_DIR="${EGIT_BRANCH}"

LICENSE="GPL-2"
KEYWORDS="~amd64 ~x86"
IUSE="${IUSE} aufs experimental"

RDEPEND="
	!sys-kernel/vanilla-kernel:${SLOT}
	!sys-kernel/vanilla-kernel-bin:${SLOT}
	aufs? ( =sys-fs/aufs-util-4* )"

src_unpack() {
    default

    if use aufs; then
	git-r3_src_unpack
	einfo "Using aufs version: ${AUFS_VERSION}"
    fi
}

src_prepare() {

	if use experimental; then
	    local GCC_MAJOR_VER=$(gcc-major-version)
	    local GCC_MINOR_VER=$(gcc-minor-version)

	    if [[ "${GCC_MAJOR_VER}" -eq 8 ]]; then
	    # support old kernels for a period. For now, remove as all gcc versions required are masked
		rm -f "${WORKDIR}"/"5010_enable-additional-cpu-optimizations-for-gcc.patch"
		rm -f "${WORKDIR}"/"5010_enable-additional-cpu-optimizations-for-gcc-4.9.patch"
		rm -f "${WORKDIR}"/"5012_enable-cpu-optimizations-for-gcc91.patch"
		rm -f "${WORKDIR}"/"5013_enable-cpu-optimizations-for-gcc10.patch"
	    elif [[ "${GCC_MAJOR_VER}" -eq 9 ]] && [[ ${GCC_MINOR_VER} -ge 1 ]]; then
		rm -f "${WORKDIR}"/"5010_enable-additional-cpu-optimizations-for-gcc.patch"
		rm -f "${WORKDIR}"/"5010_enable-additional-cpu-optimizations-for-gcc-4.9.patch"
		rm -f "${WORKDIR}"/"5011_enable-cpu-optimizations-for-gcc8.patch"
		rm -f "${WORKDIR}"/"5013_enable-cpu-optimizations-for-gcc10.patch"
	    elif [[ "${GCC_MAJOR_VER}" -eq 10 ]]; then
		rm -f "${WORKDIR}"/"5010_enable-additional-cpu-optimizations-for-gcc.patch"
		rm -f "${WORKDIR}"/"5010_enable-additional-cpu-optimizations-for-gcc-4.9.patch"
		rm -f "${WORKDIR}"/"5011_enable-cpu-optimizations-for-gcc8.patch"
		rm -f "${WORKDIR}"/"5012_enable-cpu-optimizations-for-gcc91.patch"
	    fi
	else
	    rm -f "${WORKDIR}"/"5010_enable-additional-cpu-optimizations-for-gcc.patch"
	    rm -f "${WORKDIR}"/"5010_enable-additional-cpu-optimizations-for-gcc-4.9.patch"
	    rm -f "${WORKDIR}"/"5011_enable-cpu-optimizations-for-gcc8.patch"
	    rm -f "${WORKDIR}"/"5012_enable-cpu-optimizations-for-gcc91.patch"
	    rm -f "${WORKDIR}"/"5013_enable-cpu-optimizations-for-gcc10.patch"
	fi

	local PATCHES=(
		# meh, genpatches have no directory
		"${WORKDIR}"/*.patch
	)

	if use aufs; then
	    PATCHES+=("${WORKDIR}"/${EGIT_CHECKOUT_DIR}/aufs5-kbuild.patch)
	    PATCHES+=("${WORKDIR}"/${EGIT_CHECKOUT_DIR}/aufs5-base.patch)
	    PATCHES+=("${WORKDIR}"/${EGIT_CHECKOUT_DIR}/aufs5-mmap.patch)
	    PATCHES+=("${WORKDIR}"/${EGIT_CHECKOUT_DIR}/aufs5-standalone.patch)
	fi
	
	#if use experemental; then
	#    PATCHES+=("${WORKDIR}"/5012_enable-cpu-optimizations-for-gcc91.patch)
	#fi

	cp -f "${WORKDIR}"/${EGIT_CHECKOUT_DIR}/include/uapi/linux/aufs_type.h include/uapi/linux/aufs_type.h || die
	cp -rf "${WORKDIR}"/${EGIT_CHECKOUT_DIR}/{Documentation,fs} . || die

	default

	# prepare the default config
	case ${ARCH} in
		amd64)
			cp "${DISTDIR}"/linux-${AMD64_CONFIG_VER}.amd64.config .config || die
			;;
		x86)
			cp "${DISTDIR}"/linux-${I686_CONFIG_VER}.i686.config .config || die
			;;
		*)
			die "Unsupported arch ${ARCH}"
			;;
	esac

	local config_tweaks=(
		# shove arch under the carpet!
		-e 's:^CONFIG_DEFAULT_HOSTNAME=:&"gentoo":'
		# we do support x32
		-e '/CONFIG_X86_X32/s:.*:CONFIG_X86_X32=y:'
		# disable signatures
		-e '/CONFIG_MODULE_SIG/d'
		-e '/CONFIG_SECURITY_LOCKDOWN/d'
		# disable compression to allow stripping
		-e '/CONFIG_MODULE_COMPRESS/d'
		# disable gcc plugins to unbreak distcc
		-e '/CONFIG_GCC_PLUGIN_STRUCTLEAK/d'
	)
	sed -i "${config_tweaks[@]}" .config || die
}
