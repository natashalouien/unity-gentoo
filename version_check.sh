#!/bin/sh

## Script to compare upstream versions of packages with versions in overlay tree ##
# If run without any arguments it recurses through the overlay tree and compares versions for all packages #
# Or can be run on individual packages as 'version_check.sh category/package-version.ebuild' #

local_to_upstream_packnames() {
	## Overlay package names to upstream package names mapping ##
	if [ -n "`echo "${packbasename}" | grep 'appmenu-libreoffice'`" ]; then treepackname="${packname}"; packname="lo-menubar"
	elif [ -n "`echo "${packbasename}" | grep 'appmenu-thunderbird'`" ]; then treepackname="${packname}"; packname="thunderbird-globalmenu"
	elif [ -n "`echo "${packbasename}" | grep 'chromium-[0-9]'`" ]; then treepackname="${packname}"; packname="chromium-browser"
	elif [ -n "`echo "${packbasename}" | grep 'fixesproto'`" ]; then treepackname="${packname}"; packname="x11proto-fixes"
	elif [ -n "`echo "${packbasename}" | grep '^glib-[0-9]'`" ]; then treepackname="${packname}"; packname="glib2.0"
	elif [ -n "`echo "${packbasename}" | grep 'gnome-desktop'`" ]; then treepackname="${packname}"; packname="gnome-desktop3"
	elif [ -n "`echo "${packbasename}" | grep 'gtk+-2'`" ]; then treepackname="${packname}"; packname="gtk+2.0"
	elif [ -n "`echo "${packbasename}" | grep 'gtk+-3'`" ]; then treepackname="${packname}"; packname="gtk+3.0"
	elif [ -n "`echo "${packbasename}" | grep 'gtk-engines-unico'`" ]; then treepackname="${packname}"; packname="gtk3-engines-unico"
	elif [ -n "`echo "${packbasename}" | grep 'indicator-classicmenu'`" ]; then treepackname="${packname}"; packname="classicmenu-indicator"
	elif [ -n "`echo "${packbasename}" | grep 'indicator-evolution'`" ]; then treepackname="${packname}"; packname="evolution-indicator"
	elif [ -n "`echo "${packbasename}" | grep 'indicator-psensor'`" ]; then treepackname="${packname}"; packname="psensor"
	elif [ -n "`echo "${packbasename}" | grep 'libupstart-[0-9]'`" ]; then treepackname="${packname}"; packname="upstart"
	elif [ -n "`echo "${packbasename}" | grep 'libupstart-app-launch'`" ]; then treepackname="${packname}"; packname="upstart-app-launch"
	elif [ -n "`echo "${packbasename}" | grep 'libXfixes'`" ]; then treepackname="${packname}"; packname="libxfixes"
	elif [ -n "`echo "${packbasename}" | grep 'libXi'`" ]; then treepackname="${packname}"; packname="libxi"
	elif [ -n "`echo "${packbasename}" | grep 'lazr-restfulclient'`" ]; then treepackname="${packname}"; packname="lazr.restfulclient"
	elif [ -n "`echo "${packbasename}" | grep 'mesa-mir'`" ]; then treepackname="${packname}"; packname="mesa"
	elif [ -n "`echo "${packbasename}" | grep 'nm-applet'`" ]; then treepackname="${packname}"; packname="network-manager-applet"
	elif [ -n "`echo "${packbasename}" | grep 'qtpim'`" ]; then treepackname="${packname}"; packname="libqt5organizer5"
	elif [ -n "`echo "${packbasename}" | grep 'telepathy-mission-control'`" ]; then treepackname="${packname}"; packname="telepathy-mission-control-5"
	elif [ -n "`echo "${packbasename}" | grep 'unity-webapps'`" ]; then treepackname="${packname}"; packname="libunity-webapps"
	elif [ -n "`echo "${packbasename}" | grep 'webapps-base'`" ]; then treepackname="${packname}"; packname="unity-webapps-common"
	elif [ -n "`echo "${packbasename}" | grep 'xf86-video-ati'`" ]; then treepackname="${packname}"; packname="xserver-xorg-video-ati"
	elif [ -n "`echo "${packbasename}" | grep 'xf86-video-intel'`" ]; then treepackname="${packname}"; packname="xserver-xorg-video-intel"
	elif [ -n "`echo "${packbasename}" | grep 'xf86-video-nouveau'`" ]; then treepackname="${packname}"; packname="xserver-xorg-video-nouveau"
	elif [ -n "`echo "${packbasename}"`" ]; then treepackname="${packname}"
	fi
}

RELEASES="saucy saucy-updates trusty"
SOURCES="main universe"

sources_download() {
	for get_release in ${RELEASES}; do
		for source in ${SOURCES}; do
			if [ ! -f /tmp/Sources-${source}-${get_release} ]; then
				echo
				wget http://archive.ubuntu.com/ubuntu/dists/${get_release}/${source}/source/Sources.bz2 -O /tmp/Sources-${source}-${get_release}.bz2
				bunzip2 /tmp/Sources-${source}-${get_release}.bz2
			fi
		done
	done
}

version_check() {
	local_to_upstream_packnames
	if [ -n "${stream_release}" ]; then
		version_check_other_releases
	else
		local_version_check
		upstream_version_check ${URELEASE}
		version_compare
	fi
}


local_version_check() {
	packbasename_saved="${packbasename}"    # Save off $packbasename for when uver() loops #
	if [ -z "`grep UVER= ${pack}`" ]; then
		uver
	else
		UVER=`grep UVER= ${pack} | awk -F\" '{print $2}'`
	fi
	UVER_PREFIX=`grep UVER_PREFIX= ${pack} | awk -F\" '{print $2}'`
	UVER_SUFFIX=`grep UVER_SUFFIX= ${pack} | awk -F\" '{print $2}'`
	URELEASE=`grep URELEASE= ${pack} | awk -F\" '{print $2}'`
	if [ -n "${URELEASE}" ]; then
		if [ -n "${UVER}" ]; then
			packbasename=`echo "${packbasename}" | sed -e 's:[a-z]$::'`	# Strip off trailing letter suffixes from ${PV}
			current=`echo "${packbasename}${UVER_PREFIX}-${UVER}${UVER_SUFFIX}"`
		else
			current=`echo "${packbasename}" | \
				sed -e 's:-r[0-9].*$::g' \
					-e 's:[a-z]$::'`	# Strip off trailing letter and revision suffixes from ${PV}
		fi
	fi
	packbasename="${packbasename_saved}"
}


upstream_version_check() {
	upstream_version=
	if [ -n "$1" ]; then
		if [ -z "${webscrape}" ]; then
			sources_download
			upstream_version=
			upstream_version=`grep -A2 "Package: ${packname}$" /tmp/Sources-main-$1 2> /dev/null | sed -n 's/^Version: \(.*\)/\1/p' | sed 's/[0-9]://g'`
			[[ -z "${upstream_version}" ]] && upstream_version=`grep -A2 "Package: ${packname}$" /tmp/Sources-universe-$1 2> /dev/null | sed -n 's/^Version: \(.*\)/\1/p' | sed 's/[0-9]://g'`
			[ -n "${upstream_version}" ] && [ -z "${CHANGES}" ] && [ -z "${checkmsg_supress}" ] && \
				echo -e "\nChecking ${packname}  ::  $1"
		else
			##  Use webscrape request when script is run as ./version_check.sh <pathto>/something-1.2.ebuild ##
			upstream_version_scraped=`wget -q "http://packages.ubuntu.com/$1/source/${packname}" -O - | sed -n "s/.*${packname} (\(.*\)).*/${packname}-\1/p" | sed "s/).*//g" | sed 's/1://g' | head -n1`
			if [ -z "${upstream_version_scraped}" ]; then
				[ "${stream_release}" != all ] && [ -z "${CHANGES}" ] && echo -e "\nChecking http://packages.ubuntu.com/$1/${packname}"
				upstream_version_scraped=`wget -q "http://packages.ubuntu.com/$1/${packname}" -O - | sed -n "s/.*${packname} (\(.*\)).*/${packname}-\1/p" | sed "s/).*//g" | sed 's/1://g' | head -n1`
			else
				[ "${stream_release}" != all ] && [ -z "${CHANGES}" ] && echo -e "\nChecking http://packages.ubuntu.com/$1/source/${packname}"
			fi
			upstream_version=`echo "${upstream_version_scraped}" | sed "s/^\${packname}-//" | sed 's/[0-9]://g'`
		fi
	fi
}


version_compare() {
	current_version=`echo "${current}" | sed "s/^\${treepackname}-//"`
	if [ "${current_version}" = "${upstream_version}" ]; then
		[ -n "${CHANGES}" ] && return
		if [ -n "${stream_release}" ]; then
			if [ -n "`grep "${stream_release}-updates" ${pack}`" ]; then
				echo "  Local version: ${current}  ::  ${stream_release}"
				echo "  Upstream version: ${packname}-${upstream_version}  ::  ${stream_release}"
			else
				echo "  Local version: ${current}  ::  ${stream_release}"
				echo "  Upstream version: ${packname}-${upstream_version}  ::  ${stream_release}"
			fi
		else
			echo "  Local version: ${current}  ::  ${URELEASE}"
			echo "  Upstream version: ${packname}-${upstream_version}  ::  ${URELEASE}"
		fi
	else
		if [ -n "${upstream_version}" ]; then
			echo "  Local version: ${current}  ::  ${URELEASE}"
			echo -e "  Upstream version: \033[1;31m${packname}-${upstream_version}\033[0m  ::  ${URELEASE}"
		fi
	fi
}


version_check_other_releases() {
	if [ -n "${stream_release}" ]; then
		if [ "${stream_release}" = all ]; then
			sources_download
			echo "Checking ${catpack}"
			echo "  Local versions:"
			for ebuild in $(find $(pwd) -name "*.ebuild" | grep /"${catpack}"/); do
				pack="${ebuild}"
				packbasename=$(basename ${pack} | awk -F.ebuild '{print $1}')
				packname=$(echo ${catpack} | awk -F/ '{print $2}')
				local_version_check
				if [ -z "${current}" ]; then
					echo "    ${packbasename}"
				else
					local_versions+=( "	${current}  :: ${URELEASE}" )
				fi
			done
			local_versions_output=$(IFS=$'\n'; echo "${local_versions[*]}" | sort -k3)
			echo "${local_versions_output}"
			unset local_versions

			echo "  Upstream versions:"
			for release in ${RELEASES}; do
				for ebuild in $(find $(pwd) -name "*.ebuild" | grep /"${catpack}"/ | sort); do
					pack="${ebuild}"
					packbasename=$(basename ${pack} | awk -F.ebuild '{print $1}')
					packname=$(echo ${catpack} | awk -F/ '{print $2}')
					local_to_upstream_packnames
					checkmsg_supress=1
					upstream_version_check ${release}
					checkmsg_supress=
					if [ -n "${upstream_version}" ]; then
						upstream_versions+=( "	${packname}-${upstream_version}  ::  ${release}" )
					else
						upstream_versions+=( "  		(none available)  ::  ${release}" )
					fi
				done
			done
			upstream_versions_output=$(IFS=$'\n'; echo "${upstream_versions[*]}" | sort -k3 | uniq)
			echo "${upstream_versions_output}"
			unset upstream_versions
			current=
			upstream_version_scraped=
			echo
		else
			if [ -z "`grep ${stream_release} ${pack} | grep URELEASE`" ]; then	# Skip over packages that don't contain the queried release #
				return
			else
				local_version_check
				upstream_version_check ${URELEASE}
	                	version_compare
			fi
		fi
	fi
}


uver() {
	PVR=`echo "${packbasename}" | awk -F_p '{print "_p"$(NF-1)"_p"$NF }'`
	packbasename=`echo "${packbasename}" | sed "s/${PVR}//"`
	packbasename=`echo "${packbasename}" | sed "s/[a-z]$//"`
	PVR_PL_MAJOR="${PVR#*_p}"
	PVR_PL_MAJOR="${PVR_PL_MAJOR%_p*}"
	PVR_PL="${PVR##*_p}"
	PVR_PL="${PVR_PL%%-r*}"
	char=2
	index=1
	strlength="${#PVR_PL}"
	while [ "${PVR_PL}" != "" ]; do
		strtmp="${PVR_PL:0:$char}"
		if [ "${strlength}" -ge 6 ]; then       # Don't strip zeros from 3rd number field, this is the Ubuntu OS release #
			if [ "${index}" != 3 ]; then
				strtmp="${strtmp#0}"
			fi
		else
			strtmp="${strtmp#0}"
		fi
		strarray+=( "${strtmp}" )
		PVR_PL="${PVR_PL:$char}"
		((index++))
	done
	PVR_PL_MINOR="${strarray[@]}"
	PVR_PL_MINOR="${PVR_PL_MINOR// /.}"	# Convert spaces in array to decimal points
	UVER="${PVR_PL_MAJOR}ubuntu${PVR_PL_MINOR}"
	unset strarray[@]
}

while (( "$#" )); do
	case $1 in
		--changes)
			CHANGES=1 && shift;;
		--release=*)
			stream_release=`echo "$1" | sed 's/--release=/ /' | sed 's/^[ \t]*//'` && shift;;
		--help|-h)
			echo -e "$0 (--release=<release>|all) (--changes) (category/package/package-version.ebuild)"; exit 0;;
		*)
			pack="$1" && shift;;
	esac
done

# Look for /tmp/Sources-* files older than 24 hours #
#  If found then delete them ready for fresh ones to be fetched #
[[ -n $(find /tmp -type f -ctime 1 | grep Sources-) ]] && rm /tmp/Sources-* 2> /dev/null

if [ "${stream_release}" = "all" ]; then
	for catpack in `find $(pwd) -name "*.ebuild" | awk -F/ '{print ( $(NF-2) )"/"( $(NF-1) )}' | sort -du | grep -Ev "eclass|metadata|profiles"`; do
		packname=`echo ${catpack} | awk -F/ '{print $2}'`
		version_check
	done
elif [ -n "${pack}" ]; then	# Use webscrape method when run against singular ebuild files
	packbasename=`basename ${pack} | awk -F.ebuild '{print $1}'`
	packname=`echo ${pack} | awk -F/ '{print ( $(NF-1) )}'`
	webscrape=1
	version_check
else
	for pack in `find $(pwd) -name "*.ebuild"`; do
		packbasename=`basename ${pack} | awk -F.ebuild '{print $1}'`
		packname=`echo ${pack} | awk -F/ '{print ( $(NF-1) )}'`
		version_check
	done
	if [ -z "${stream_release}" ]; then
		## Check versions in meta type ebuilds that install from multiple sources ##
		if [ -d "$(pwd)/unity-base/unity-language-pack" ]; then
			pushd $(pwd)/unity-base/unity-language-pack
				[ -n "${CHANGES}" ] && \
					./lang_version_check.sh --changes || \
						./lang_version_check.sh
			popd
		fi
		if [ -d "$(pwd)/unity-base/webapps" ]; then
			pushd $(pwd)/unity-base/webapps
				[ -n "${CHANGES}" ] && \
					./webapps_version_check.sh --changes || \
						./webapps_version_check.sh
			popd
		fi
		if [ -d "$(pwd)/unity-scopes/smart-scopes" ]; then
			pushd $(pwd)/unity-scopes/smart-scopes
				[ -n "${CHANGES}" ] && \
					./scopes_version_check.sh --changes || \
						./scopes_version_check.sh
			popd
		fi
	fi
fi
