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

cmd() {
    echo + "$@"
    "$@"
    return $?
}

BUILD_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
[ -f "$BUILD_DIR/../container.env" ] && source "$BUILD_DIR/../container.env" \
    || { echo "ERROR: Container environment not found" >&2; exit 1; }

readarray -t -d' ' TAGS < <(printf '%s' "$DEFAULT_TAGS")

echo + "CONTAINER=\"\$(buildah from $BASE_IMAGE)\""
CONTAINER="$(buildah from "$BASE_IMAGE")"

echo + "MOUNT=\"\$(buildah mount $CONTAINER)\""
MOUNT="$(buildah mount "$CONTAINER")"

echo + "rsync -v -rl --exclude .gitignore ./src/ …/"
rsync -v -rl --exclude '.gitignore' "$BUILD_DIR/src/" "$MOUNT/"

echo + "OLD_MYSQL_UID=\"\$(grep ^mysql: …/etc/passwd | cut -d: -f3)\""
OLD_MYSQL_UID="$(grep ^mysql: "$MOUNT/etc/passwd" | cut -d: -f3)"

echo + "OLD_MYSQL_GID=\"\$(grep ^mysql: …/etc/group | cut -d: -f3)\""
OLD_MYSQL_GID="$(grep ^mysql: "$MOUNT/etc/group" | cut -d: -f3)"

cmd buildah run "$CONTAINER" -- \
    usermod -u 65536 -s "/sbin/nologin" -d "/var/lib/mysql" mysql

cmd buildah run "$CONTAINER" -- \
    groupmod -g 65536 mysql

cmd buildah run "$CONTAINER" -- \
    find / -path /sys -prune -o -path /proc -prune -o -user "$OLD_MYSQL_UID" -exec chown mysql -h {} \;

cmd buildah run "$CONTAINER" -- \
    find / -path /sys -prune -o -path /proc -prune -o -group "$OLD_MYSQL_GID" -exec chgrp mysql -h {} \;

cmd buildah config --volume "/var/log/mysql" "$CONTAINER"

cmd buildah commit "$CONTAINER" "$IMAGE:${TAGS[0]}"
cmd buildah rm "$CONTAINER"

for TAG in "${TAGS[@]:1}"; do
    cmd buildah tag "$IMAGE:${TAGS[0]}" "$IMAGE:$TAG"
done
