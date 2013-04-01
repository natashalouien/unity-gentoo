EAPI=4

inherit autotools gnome2 ubuntu-versionator

UURL="http://archive.ubuntu.com/ubuntu/pool/main/i/${PN}"
URELEASE="raring"
UVER_PREFIX="daily13.03.28.1"
GNOME2_LA_PUNT="1"

DESCRIPTION="Indicator for synchronisation processes status used by the Unity desktop"
HOMEPAGE="http://launchpad.net/indicator-sync"
SRC_URI="${UURL}/${MY_P}${UVER_PREFIX}.orig.tar.gz"

LICENSE="GPL-3"
SLOT="0"
#KEYWORDS="~amd64 ~x86"
IUSE=""
RESTRICT="mirror"

DEPEND=">=dev-libs/glib-2.35.4
	dev-libs/libappindicator
	dev-libs/libdbusmenu[gtk]
	dev-libs/libindicate
	dev-libs/libindicator
	unity-base/ido
	x11-libs/gtk+:3
	x11-libs/pango"

S="${WORKDIR}/${PN}-${PV}${UVER_PREFIX}"

src_prepare() {
	eautoreconf
	gnome2_src_prepare
}