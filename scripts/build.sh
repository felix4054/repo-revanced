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


VMG_VERSION="0.2.26.225014"

# File containing all patches
patch_file=./patches.txt

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

# artifacts["revanced-cli.jar"]="inotia00/revanced-cli revanced-cli .jar"
# artifacts["revanced-integrations.apk"]="inotia00/revanced-integrations revanced-integrations .apk"
# artifacts["revanced-patches.jar"]="inotia00/revanced-patches revanced-patches .jar"
# artifacts["microg.apk"]="inotia00/VancedMicroG microg .apk"
#artifacts["apkeep"]="EFForg/apkeep apkeep-x86_64-unknown-linux-gnu"

artifacts["revanced-cli.jar"]="revanced/revanced-cli revanced-cli .jar"
artifacts["revanced-integrations.apk"]="YT-Advanced/ReX-integrations revanced-integrations .apk"
artifacts["revanced-patches.jar"]="YT-Advanced/ReX-patches revanced-patches .jar"
artifacts["microg.apk"]="inotia00/VancedMicroG microg .apk"
artifacts["apkeep"]="EFForg/apkeep apkeep-x86_64-unknown-linux-gnu"

# artifacts["revanced-cli.jar"]="revanced/revanced-cli revanced-cli .jar"
# artifacts["revanced-integrations.apk"]="revanced/revanced-integrations app-release-unsigned .apk"
# artifacts["revanced-patches.jar"]="revanced/revanced-patches revanced-patches .jar"
# artifacts["apkeep"]="EFForg/apkeep apkeep-x86_64-unknown-linux-gnu"

get_artifact_download_url () {
    # Usage: get_download_url <repo_name> <artifact_name> <file_type>
    local api_url="https://api.github.com/repos/$1/releases/latest"
    local result=$(curl $api_url | jq ".assets[] | select(.name | contains(\"$2\") and contains(\"$3\") and (contains(\".sig\") | not)) | .browser_download_url")
    echo ${result:1:-1}
}

# Function for populating patches array, using a function here reduces redundancy & satisfies DRY principals
populate_patches() {
    # Note: <<< defines a 'here-string'. Meaning, it allows reading from variables just like from a file
    while read -r patch; do
        patches+=("$1 $patch")
    done <<< "$2"
}

## Main

# cleanup to fetch new revanced on next run
if [[ "$1" == "clean" ]]; then
    rm -f revanced-cli.jar revanced-integrations.apk revanced-patches.jar microg.apk
    exit
fi

# if [[ "$1" == "experimental" ]]; then
#     EXPERIMENTAL="--experimental"
# fi

# Fetch all the dependencies
for artifact in "${!artifacts[@]}"; do
    if [ ! -f $artifact ]; then
        out "${YELLOW}Downloading $artifact${NC}"
        curl -L -o $artifact $(get_artifact_download_url ${artifacts[$artifact]})
    fi
done

# Fetch Vanced microG
chmod +x apkeep


# if [ ! -f "vanced-microG.apk" ]; then
#     out "${YELLOW}Downloading Vanced microG"
#     ./apkeep -a com.mgoogle.android.gms@$VMG_VERSION .
#     mv com.mgoogle.android.gms@$VMG_VERSION.apk vanced-microG.apk
# fi



# If the variables are NOT empty, call populate_patches with proper arguments
[[ ! -z "$excluded_patches" ]] && populate_patches "-e" "$excluded_patches"
[[ ! -z "$included_patches" ]] && populate_patches "-i" "$included_patches"


out "${YELLOW}Building YouTube ReVanced APK"

mkdir -p build
if [[ -z "revanced-patches.jar" ]] || [[ -z "revanced-integrations.apk" ]] || [[ -z "revanced-cli.jar" ]]; then 
    printf "\033[0;31mError: patches files not found\033[0m\n" 
    exit 1 
fi

for file in "revanced-cli.jar" "revanced-integrations.apk" "revanced-patches.jar" "youtube.apk"; do 
    printf "\033[0;36m->%s\033[0m\n" "$file" 
done

if [ -f "youtube.apk" ]; then
    out "${YELLOW}Building Non-root APK"
    
    java -jar revanced-cli.jar patch \
    	 -a youtube.apk \
 	 -b revanced-patches.jar \
   	 -m revanced-integrations.apk \
         ${patches[@]} \
         -o build/revanced-nonroot.apk 
else
    out "${RED}Cannot find YouTube APK, skipping build"
fi


# A list of available patches and their descriptions can be found here:

# yt_excluded_patches="-i premium-heading -i amoled -i materialyou -i custom-package-name -e custom-branding-name -e custom-branding-icon-red -i custom-branding-icon-blue -e custom-branding-icon-revancify"
# if [ -f "youtube.apk" ]; then
#     echo "Building Non-root APK"
#     java -jar revanced-cli.jar -m revanced-integrations.apk -b revanced-patches.jar \
#                             $yt_excluded_patches \
#                             -a youtube.apk -o build/revanced-nonroot.apk
#     echo "YouTube ReVanced build finished"
# else
#     echo "Cannot find YouTube APK, skipping build"
# fi

