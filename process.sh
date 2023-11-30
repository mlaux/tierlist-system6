#!/bin/sh
set -e
rm -f Rez.out
node rectify.js
node make-resource-script.js
Rez SongData.r -o Rez.out
macbinary encode -o SongDataResources.bin Rez.out
