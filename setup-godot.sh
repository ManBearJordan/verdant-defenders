#!/usr/bin/env bash
set -e
GODOT_VERSION="4.1.2"
ARCH="x11.64"
URL="https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}/Godot_v${GODOT_VERSION}-${ARCH}.zip"
mkdir -p godot
wget -qO godot.zip "$URL"
unzip godot.zip -d godot
chmod +x godot/Godot_v${GODOT_VERSION}-${ARCH}
echo "export PATH=\$PWD/godot:\$PATH" >> ~/.bashrc
