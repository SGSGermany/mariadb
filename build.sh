#!/bin/bash
# MariaDB
# A MariaDB container with an improved configuration.
#
# Copyright (c) 2021  SGS Serious Gaming & Simulations GmbH
#
# This work is licensed under the terms of the MIT license.
# For a copy, see LICENSE file or <https://opensource.org/licenses/MIT>.
#
# SPDX-License-Identifier: MIT
# License-Filename: LICENSE

set -eu -o pipefail
export LC_ALL=C.UTF-8

[ -v CI_TOOLS ] && [ "$CI_TOOLS" == "SGSGermany" ] \
    || { echo "Invalid build environment: Environment variable 'CI_TOOLS' not set or invalid" >&2; exit 1; }

[ -v CI_TOOLS_PATH ] && [ -d "$CI_TOOLS_PATH" ] \
    || { echo "Invalid build environment: Environment variable 'CI_TOOLS_PATH' not set or invalid" >&2; exit 1; }

source "$CI_TOOLS_PATH/helper/common.sh.inc"
source "$CI_TOOLS_PATH/helper/container.sh.inc"
source "$CI_TOOLS_PATH/helper/container-debian.sh.inc"
source "$CI_TOOLS_PATH/helper/git.sh.inc"

BUILD_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$BUILD_DIR/container.env"

readarray -t -d' ' TAGS < <(printf '%s' "$TAGS")

git_clone "$MERGE_IMAGE_GIT_REPO" "$MERGE_IMAGE_GIT_REF" "$BUILD_DIR/vendor" "./vendor"

con_build --tag "$IMAGE-base" \
    --from "$BASE_IMAGE" --check-from "$MERGE_IMAGE_BASE_IMAGE_PATTERN" \
    "$BUILD_DIR/vendor/$MERGE_IMAGE_BUD_CONTEXT" "./vendor/$MERGE_IMAGE_BUD_CONTEXT"

echo + "CONTAINER=\"\$(buildah from $(quote "$IMAGE-base"))\"" >&2
CONTAINER="$(buildah from "$IMAGE-base")"

echo + "MOUNT=\"\$(buildah mount $(quote "$CONTAINER"))\"" >&2
MOUNT="$(buildah mount "$CONTAINER")"

echo + "rsync -v -rl --exclude .gitignore ./src/ …/" >&2
rsync -v -rl --exclude '.gitignore' "$BUILD_DIR/src/" "$MOUNT/"

user_changeuid "$CONTAINER" mysql 65536 "/var/lib/mysql"

cleanup "$CONTAINER"

cmd buildah config \
    --label org.opencontainers.image.title- \
    --label org.opencontainers.image.description- \
    --label org.opencontainers.image.version- \
    --label org.opencontainers.image.url- \
    --label org.opencontainers.image.source- \
    --label org.opencontainers.image.documentation- \
    --label org.opencontainers.image.authors- \
    --label org.opencontainers.image.vendor- \
    --label org.opencontainers.image.licenses- \
    --label org.opencontainers.image.base.name- \
    --label org.opencontainers.image.ref.name- \
    --port - \
    "$CONTAINER"

cmd buildah config \
    --env MARIADB_AUTO_UPGRADE="1" \
    "$CONTAINER"

cmd buildah config \
    --volume "/var/log/mysql" \
    --volume "/run/mysql" \
    "$CONTAINER"

echo + "MARIADB_VERSION=\"\$(buildah run $CONTAINER -- /bin/sh -c 'echo \"\$MARIADB_VERSION\"')\"" >&2
MARIADB_VERSION="$(buildah run "$CONTAINER" -- /bin/sh -c 'echo "$MARIADB_VERSION"')"

echo + "MARIADB_VERSION=\"\$(sed -ne 's/^\([0-9]*:\)\?\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\)\([+~-].*\)\?$/\2.\3.\4/p' <<< ${MARIADB_VERSION@Q})" >&2
MARIADB_VERSION="$(sed -ne 's/^\([0-9]*:\)\?\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\)\([+~-].*\)\?$/\2.\3.\4/p' <<< "$MARIADB_VERSION")"

cmd buildah config \
    --annotation org.opencontainers.image.title="MariaDB" \
    --annotation org.opencontainers.image.description="A MariaDB container with an improved configuration." \
    --annotation org.opencontainers.image.version="$MARIADB_VERSION" \
    --annotation org.opencontainers.image.url="https://github.com/SGSGermany/mariadb" \
    --annotation org.opencontainers.image.authors="SGS Serious Gaming & Simulations GmbH" \
    --annotation org.opencontainers.image.vendor="SGS Serious Gaming & Simulations GmbH" \
    --annotation org.opencontainers.image.licenses="MIT" \
    --annotation org.opencontainers.image.base.name="$BASE_IMAGE" \
    --annotation org.opencontainers.image.base.digest="$(podman image inspect --format '{{.Digest}}' "$BASE_IMAGE")" \
    "$CONTAINER"

con_commit "$CONTAINER" "${TAGS[@]}"
