EAPI=5
PYTHON_DEPEND="2:2.7 3:3.2"
#SUPPORT_PYTHON_ABIS="1"

inherit autotools base eutils autotools python ubuntu-versionator

UURL="http://archive.ubuntu.com/ubuntu/pool/main/libu/${PN}"
URELEASE="raring"
UVER_PREFIX="daily13.04.05"

DESCRIPTION="Library for instrumenting and integrating with all aspects of the Unity shell"
HOMEPAGE="https://launchpad.net/libunity"
SRC_URI="${UURL}/${MY_P}${UVER_PREFIX}.orig.tar.gz
	${UURL}/${MY_P}${UVER_PREFIX}-${UVER}.diff.gz"

LICENSE="GPL-3"
SLOT="0/9.0.2"
KEYWORDS="~amd64 ~x86"
IUSE=""
RESTRICT="mirror"

RDEPEND="dev-libs/dee:=
	dev-libs/libdbusmenu:=[gtk]"
DEPEND="${RDEPEND}
	dev-libs/libgee:0
	dev-lang/vala:0.16
	x11-libs/gtk+:3"

S="${WORKDIR}/${PN}-${PV}${UVER_PREFIX}"

src_prepare() {
	export VALAC=$(type -P valac-0.16) && \
	export VALA_API_GEN=$(type -p vapigen-0.16)

	epatch -p1 "${WORKDIR}/${MY_P}${UVER_PREFIX}-${UVER}.diff"
	for patch in $(cat "debian/patches/series" | grep -v '#'); do
		PATCHES+=( "debian/patches/${patch}" )
	done
	base_src_prepare
	eautoreconf
}

src_configure() {
        # Build PYTHON2 support #
	export EPYTHON="$(PYTHON -2)"
	cd "${WORKDIR}"
	cp -rf "${S}" "${S}"-build_python2
	pushd "${S}"-build_python2
		./configure --prefix=/usr || die
	popd

	# Build PYTHON3 support #
	export EPYTHON="$(PYTHON -3)"
	cd "${WORKDIR}"
	cp -rf "${S}" "${S}"-build_python3
	pushd "${S}"-build_python3
		./configure --prefix=/usr || die
	popd
}

src_compile() {
	# Build PYTHON2 support #
	pushd "${S}"-build_python2
		emake || die
	popd

	# Build PYTHON3 support #
	pushd "${S}"-build_python3
		emake || die
	popd
}

src_install() {
	# Install PYTHON2 support #
	pushd "${S}"-build_python2
		emake DESTDIR="${D}" install || die
	popd

	# Install PYTHON3 support #
	pushd "${S}"-build_python3
		emake DESTDIR="${D}" install || die
	popd

	prune_libtool_files --modules
}
