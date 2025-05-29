#!/bin/bash

set -e

FINALPACKAGE=1 THEOS_PACKAGE_SCHEME='' gmake clean package
FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless gmake clean package
FINALPACKAGE=1 THEOS="$HOME/theos-roothide" THEOS_PACKAGE_SCHEME=roothide gmake clean package
