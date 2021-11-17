#!/bin/bash
# MariaDB
# A MariaDB container with an improved configuration structure.
#
# Copyright (c) 2021  SGS Serious Gaming & Simulations GmbH
#
# This work is licensed under the terms of the MIT license.
# For a copy, see LICENSE file or <https://opensource.org/licenses/MIT>.
#
# SPDX-License-Identifier: MIT
# License-Filename: LICENSE

set -eu -o pipefail
export LC_ALL=C

BUILD_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
[ -f "$BUILD_DIR/container.env" ] && source "$BUILD_DIR/container.env" \
    || { echo "ERROR: Container environment not found" >&2; exit 1; }

IMAGE_ID="$(podman pull "$BASE_IMAGE" || true)"
if [ -z "$IMAGE_ID" ]; then
    echo "Failed to pull image '$BASE_IMAGE': No image with this tag found" >&2
    exit 1
fi

MYSQL_VERSION="$(podman image inspect --format '{{range .Config.Env}}{{printf "%q\n" .}}{{end}}' "$BASE_IMAGE" \
    | sed -ne 's/^"MARIADB_VERSION=\(.*\)"$/\1/p')"
if [ -z "$MYSQL_VERSION" ]; then
    echo "Unable to read image's env variable 'MARIADB_VERSION': No such variable" >&2
    exit 1
fi
if ! [[ "$MYSQL_VERSION" =~ ^([0-9]+:)?([0-9]+)\.([0-9]+)\.([0-9]+)([+~-]|$) ]]; then
    echo "Unable to read image's env variable 'MARIADB_VERSION': '$MYSQL_VERSION' is no valid version" >&2
    exit 1
fi

MYSQL_VERSION="${BASH_REMATCH[2]}.${BASH_REMATCH[3]}.${BASH_REMATCH[4]}"
MYSQL_VERSION_MINOR="${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
MYSQL_VERSION_MAJOR="${BASH_REMATCH[2]}"

TAG_DATE="$(date -u +'%Y%m%d%H%M')"

DEFAULT_TAGS=(
    "v$MYSQL_VERSION-default" "v$MYSQL_VERSION-default_$TAG_DATE"
    "v$MYSQL_VERSION_MINOR-default" "v$MYSQL_VERSION_MINOR-default_$TAG_DATE"
    "v$MYSQL_VERSION_MAJOR-default" "v$MYSQL_VERSION_MAJOR-default_$TAG_DATE"
    "latest-default"
)

BASE_TAGS=(
    "v$MYSQL_VERSION" "v${MYSQL_VERSION}_$TAG_DATE"
    "v$MYSQL_VERSION_MINOR" "v${MYSQL_VERSION_MINOR}_$TAG_DATE"
    "v$MYSQL_VERSION_MAJOR" "v${MYSQL_VERSION_MAJOR}_$TAG_DATE"
    "latest"
)

printf 'VERSION="%s"\n' "$MYSQL_VERSION"
printf 'DEFAULT_TAGS="%s"\n' "${DEFAULT_TAGS[*]}"
printf 'BASE_TAGS="%s"\n' "${BASE_TAGS[*]}"
