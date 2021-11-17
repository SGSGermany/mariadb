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

readarray -t -d' ' TAGS < <(printf '%s' "$BASE_TAGS")
DEFAULT_TAG="${DEFAULT_TAGS%% *}"

echo + "CONTAINER=\"\$(buildah from $IMAGE:$DEFAULT_TAG)\""
CONTAINER="$(buildah from "$IMAGE:$DEFAULT_TAG")"

echo + "MOUNT=\"\$(buildah mount $CONTAINER)\""
MOUNT="$(buildah mount "$CONTAINER")"

echo + "rsync -v -rl --exclude .gitignore ./src/ …/"
rsync -v -rl --exclude '.gitignore' "$BUILD_DIR/src/" "$MOUNT/"

cmd buildah config \
    --volume "/run/mysql" \
    --port "-" \
    "$CONTAINER"

cmd buildah commit "$CONTAINER" "$IMAGE:${TAGS[0]}"
cmd buildah rm "$CONTAINER"

for TAG in "${TAGS[@]:1}"; do
    cmd buildah tag "$IMAGE:${TAGS[0]}" "$IMAGE:$TAG"
done
