#!/bin/bash

revanced=no
while getopts r flag
do
    case "${flag}" in
        r) revanced=yes;;
    esac
done

# Generate SHA-256 hashes
if [ "$revanced" = 'yes' ]; then
    sha256sum build/revanced-nonroot-release.apk > build/SHA-256-yt.txt
fi
