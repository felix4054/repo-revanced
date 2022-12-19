#!/usr/bin/env bash

declare -A apks

YT_VERSION="17-45-36"

apks["com.google.android.youtube.apk"]=dl_yt

## Functions

# Wget user agent
WGET_HEADER="User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0"

# Wget function
req() { wget -nv -O "$2" --header="$WGET_HEADER" "$1"; }

# Wget apk verions
get_apk_vers() { req "$1" - | sed -n 's;.*Version:</span><span class="infoSlide-value">\(.*\) </span>.*;\1;p'; }

# Wget apk verions(largest)
get_largest_ver() {
	local max=0
	while read -r v || [ -n "$v" ]; do
		if [[ ${v//[!0-9]/} -gt ${max//[!0-9]/} ]]; then max=$v; fi
	done
	if [[ $max = 0 ]]; then echo ""; else echo "$max"; fi
}

# Wget download apk
dl_apk() {
	local url=$1 regexp=$2 output=$3
	url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n "s/href=\"/@/g; s;.*${regexp}.*;\1;p")"
	echo "$url"
	url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n 's;.*href="\(.*key=[^"]*\)">.*;\1;p')"
	url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n 's;.*href="\(.*key=[^"]*\)">.*;\1;p')"
	req "$url" "$output"
}

# Download YouTube
dl_yt() {
	if [ "$revanced" = 'yes' ]; then
		echo "Downloading YouTube..."

		local base_apk="com.google.android.youtube.apk"
		if [ ! -f "$base_apk" ]; then
			declare -r dl_url=$(dl_apk "https://www.apkmirror.com/apk/google-inc/youtube/youtube-${YT_VERSION}-release/" \
				"APK</span>[^@]*@\([^#]*\)" \
				"$base_apk")
			echo "YouTube version: ${last_ver}"
			echo "downloaded from: [APKMirror - YouTube]($dl_url)"
			
		fi
	else
		echo "Skipping YouTube..."
	fi
}

# Downloading youtube
# dl_yt() {
# 	echo "Downloading YouTube"
# 	local last_ver
# 	last_ver="$version"
# 	last_ver="${last_ver:-$(get_apk_vers "https://www.apkmirror.com/uploads/?appcategory=youtube" | get_largest_ver)}"

# 	echo "Choosing version '${last_ver}'"
# 	local base_apk="com.google.android.youtube.apk"
# 	if [ ! -f "$base_apk" ]; then
# 		declare -r dl_url=$(dl_apk "https://www.apkmirror.com/apk/google-inc/youtube/youtube-${last_ver//./-}-release/" \
# 			"APK</span>[^@]*@\([^#]*\)" \
# 			"$base_apk")
# 		echo "YouTube version: ${last_ver}"
# 		echo "downloaded from: [APKMirror - YouTube]($dl_url)"
# 	fi
# }

## Main

for apk in "${!apks[@]}"; do
    if [ ! -f $apk ]; then
        echo "Downloading $apk"
        version=$(jq -r ".\"$apk\"" <versions.json)
        ${apks[$apk]}
    fi
done
