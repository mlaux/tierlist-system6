#!/bin/sh
set -e
node rectify.js
node make-resource-script.js
Rez SongData.r -o Rez.out
macbinary encode -o SongDataResources.bin Rez.out
rm Rez.out
