#!/usr/bin/env bash



SIZE=680



convert assets/logomivion.png \
  -resize 680x680 \
  -background none \
  -gravity center \
  -extent 1024x1024 \
  assets/logo_launcher.png


dart run flutter_launcher_icons