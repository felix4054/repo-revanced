#!/bin/bash

revanced=no
while getopts r flag
do
    case "${flag}" in
        r) revanced=yes;;
    esac
done

VMG_VERSION="0.2.24.220220"

# Artifacts associative array aka dictionary
declare -A artifacts

artifacts["revanced-cli.jar"]="inotia00/revanced-cli revanced-cli .jar"
artifacts["revanced-integrations.apk"]="inotia00/revanced-integrations app-release-unsigned .apk"
artifacts["revanced-patches.jar"]="inotia00/revanced-patches revanced-patches .jar"
artifacts["apkeep"]="EFForg/apkeep apkeep-x86_64-unknown-linux-gnu"

get_artifact_download_url () {
    # Usage: get_download_url <repo_name> <artifact_name> <file_type>
    local api_url="https://api.github.com/repos/$1/releases/latest"
    local result=$(curl $api_url | jq ".assets[] | select(.name | contains(\"$2\") and contains(\"$3\") and (contains(\".sig\") | not)) | .browser_download_url")
    echo ${result:1:-1}
}

# Fetch all the dependencies
for artifact in "${!artifacts[@]}"; do
    if [ ! -f $artifact ]; then
        echo "Downloading $artifact"
        curl -L -o $artifact $(get_artifact_download_url ${artifacts[$artifact]})
    fi
done

# Fetch Vanced microG
chmod +x apkeep

if [ "$revanced" = 'yes' ]; then
    if [ ! -f "vanced-microG.apk" ]; then
        echo "Downloading Vanced microG"
        ./apkeep -a com.mgoogle.android.gms@$VMG_VERSION .
        mv com.mgoogle.android.gms@$VMG_VERSION.apk vanced-microG.apk
    fi
fi

mkdir -p build

# A list of available patches and their descriptions can be found here:
# https://github.com/LeddaZ/revanced-patches

if [ "$revanced" = 'yes' ]; then
    echo "************************************"
    echo "*    Building YouTube ReVanced     *"
    echo "************************************"

    yt_excluded_patches="-i premium-heading -i amoled -i materialyou -i custom-package-name -e custom-branding-name -e custom-branding-icon-red -i custom-branding-icon-blue -e custom-branding-icon-revancify"

    if [ -f "youtube.apk" ]; then
        java -jar revanced-cli.jar -m revanced-integrations.apk -b revanced-patches.jar \
                                $yt_excluded_patches \
                                -a youtube.apk -o build/revanced-nonroot.apk
        echo "YouTube ReVanced build finished"
    else
        echo "Cannot find YouTube APK, skipping build"
    fi
else
    echo "Skipping YouTube Revanced build"
fi
