EAPI=5
GNOME2_LA_PUNT="yes"

inherit autotools eutils gnome2 ubuntu-versionator

UURL="http://archive.ubuntu.com/ubuntu/pool/main/t/${PN}"
URELEASE="raring"
UVER_PREFIX="daily13.03.01"

DESCRIPTION="Desktop service to integrate Telepathy with the messaging menu used by the Unity desktop"
HOMEPAGE="https://launchpad.net/telepathy-indicator"
SRC_URI="${UURL}/${MY_P}${UVER_PREFIX}.orig.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""
RESTRICT="mirror"

RDEPEND="dev-libs/libunity:="
DEPEND="${RDEPEND}
	dev-libs/libappindicator
	dev-libs/libdbusmenu[gtk]
	dev-libs/libindicate-qt
	net-libs/telepathy-glib
	unity-indicators/indicator-messages"

S="${WORKDIR}/${PN}-${PV}${UVER_PREFIX}"

src_prepare() {
	eautoreconf
}