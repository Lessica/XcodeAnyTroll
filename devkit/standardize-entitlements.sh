#!/bin/sh

cd "$(dirname "$0")"/.. || exit

plutil -convert xml1 serialcomm/entitlements.plist
