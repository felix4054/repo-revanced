#!/bin/bash

revanced=no
while getopts mr flag
do
    case "${flag}" in
        r) revanced=yes;;
    esac
done

# Generate SHA-256 hashes
if [ "$revanced" = 'yes' ]; then
    sha256sum build/revanced-nonroot-signed.apk > build/SHA-256-yt.txt
fi
