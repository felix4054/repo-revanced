#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

out() {
    # print a message
    printf '%b\n' "$@"
}

# 0.3.0.234414
# 0.2.26.225014
VMG_VERSION="0.3.0.234414" 

# Import build configuration
source build.targets

# File containing all patches
patch_file=./youtube.patch

# Get line numbers where included & excluded patches start from. 
# We rely on the hardcoded messages to get the line numbers using grep
excluded_start="$(grep -n -m1 'EXCLUDE PATCHES' "$patch_file" | cut -d':' -f1)"
included_start="$(grep -n -m1 'INCLUDE PATCHES' "$patch_file" | cut -d':' -f1)"

# Get everything but hashes from between the EXCLUDE PATCH & INCLUDE PATCH line
# Note: '^[^#[:blank:]]' ignores starting hashes and/or blank characters i.e, whitespace & tab excluding newline
excluded_patches="$(tail -n +$excluded_start $patch_file | head -n "$(( included_start - excluded_start ))" | grep '^[^#[:blank:]]')"

# Get everything but hashes starting from INCLUDE PATCH line until EOF
included_patches="$(tail -n +$included_start $patch_file | grep '^[^#[:blank:]]')"

# Array for storing patches
declare -a patches

# Artifacts associative array aka dictionary
declare -A artifacts

if [ "$EXTENDED_SUPPORT" = "true" ]; then
artifacts["revanced-integrations.apk"]="YT-Advanced/ReX-integrations revanced-integrations .apk"
artifacts["revanced-cli.jar"]="inotia00/revanced-cli revanced-cli .jar"
artifacts["revanced-patches.jar"]="YT-Advanced/ReX-patches revanced-patches .jar"

# artifacts["revanced-integrations.apk"]="inotia00/revanced-integrations revanced-integrations .apk"
# artifacts["revanced-cli.jar"]="inotia00/revanced-cli revanced-cli .jar"
# artifacts["revanced-patches.jar"]="inotia00/revanced-patches revanced-patches .jar"
else
artifacts["revanced-integrations.apk"]="YT-Advanced/ReX-integrations revanced-integrations .apk"
artifacts["revanced-cli.jar"]="inotia00/revanced-cli revanced-cli .jar"
artifacts["revanced-patches.jar"]="YT-Advanced/ReX-patches revanced-patches .jar"

# artifacts["revanced-integrations.apk"]="revanced/revanced-integrations revanced-integrations .apk"
# artifacts["revanced-cli.jar"]="revanced/revanced-cli revanced-cli .jar"
# artifacts["revanced-patches.jar"]="revanced/revanced-patches revanced-patches .jar"
fi
artifacts["vanced-microG.apk"]="inotia00/VancedMicroG microg .apk"
artifacts["apkeep"]="EFForg/apkeep apkeep-x86_64-unknown-linux-gnu"


get_artifact_download_url () {
    local api_url result
    api_url="https://api.github.com/repos/$1/releases/latest"
    result=$(curl -s $api_url | jq ".assets[] | select(.name | contains(\"$2\") and contains(\"$3\") and (contains(\".sig\") | not)) | .browser_download_url")
    echo "${result:1:-1}"
}

# Function for populating patches array, using a function here reduces redundancy & satisfies DRY principals
populate_patches() {
    while read -r revanced_patches
    do
        patches+=("$1 $revanced_patches")
    done <<< "$2"
}

## Main

# cleanup to fetch new revanced on next run
out "${BLUE}CLEANING UP"
if [[ "$1" == "clean" ]]; then
    rm -f revanced-cli.jar revanced-integrations.apk revanced-patches.jar microg.apk
    exit
fi

out "${BLUE}SET EXPERIMENTAL"
if [[ "$1" == "experimental" ]]; then
    EXPERIMENTAL="--experimental"
fi

# Fetch all the dependencies
for artifact in "${!artifacts[@]}"; do
    if [ ! -f $artifact ]; then
        out "${YELLOW}Downloading $artifact${NC}"
        # curl -L -o $artifact $(get_artifact_download_url ${artifacts[$artifact]})
	curl -sLo "$artifact" $(get_artifact_download_url ${artifacts[$artifact]})
    fi
done

# Fetch Vanced microG
chmod +x apkeep

out "${BLUE}VANCED MICROG"
if [  -f "vanced-microG.apk" ]; then
    out "${CYAN}Choosing Vanced microG: $VMG_VERSION"
    # ./apkeep -a com.mgoogle.android.gms@$VMG_VERSION .
    mv vanced-microG.apk build/microG-$VMG_VERSION.apk
fi


out "${BLUE}CALL POPULATE PATCHES"
# If the variables are NOT empty, call populate_patches with proper arguments
[[ ! -z "$excluded_patches" ]] && populate_patches "-e" "$excluded_patches"
[[ ! -z "$included_patches" ]] && populate_patches "-i" "$included_patches"


out "${YELLOW}Building YouTube ReVanced APK"

mkdir -p build


function build_youtube_root() {
if [ -f "com.google.android.youtube.apk" ]; then
    out "${YELLOW}Building Root APK"
    
    java -jar revanced-cli.jar  patch com.google.android.youtube.apk \
    	 -m revanced-integrations.apk \
 	 -b revanced-patches.jar \
         ${patches[@]} \
	 $EXPERIMENTAL \
         -o "build/rvx-youtube-$(cat versions.json | grep -oP '(?<="com.google.android.youtube.apk": ")[^"]*')-root.apk" 
	 
else
    out "${RED}Cannot find YouTube APK, skipping build"
fi
}

function build_youtube_nonroot() {
if [ -f "com.google.android.youtube.apk" ]; then
    out "${YELLOW}Building Non-Root APK"
    
    java -jar revanced-cli.jar  patch \
         -m revanced-integrations.apk \
 	 -b revanced-patches.jar \
         ${patches[@]} \
	 $EXPERIMENTAL \
         -o "build/rvx-youtube-$(cat versions.json | grep -oP '(?<="com.google.android.youtube.apk": ")[^"]*')-nonroot.apk" \
	 com.google.android.youtube.apk
	 
else
    out "${RED}Cannot find YouTube APK, skipping build"
fi
}

if [ "$YOUTUBE_ROOT" = "true" ]; then
	build_youtube_root
else
	out "${CYAN}Skipping YouTube ReVanced (root)"
fi

if [ "$YOUTUBE_NONROOT" = "true" ]; then
	build_youtube_nonroot
else
	out "${CYAN}Skipping YouTube ReVanced (nonroot)"
fi

out "${BLUE}DONE"
