#/usr/bin/env bash

docker buildx build \
    --tag "gentoo-plasma:$(date +"%Y%m%d")" \
    --build-arg MAKEOPTS="-j$(nproc)" \
    --load \
    .
