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

_unix_socket_auth() {
    local MARIADB_ROOT_PASSWORD_ESCAPED="$(docker_sql_escape_string_literal "$MARIADB_ROOT_PASSWORD")"
    docker_process_sql \
        <<<"ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket OR mysql_native_password USING PASSWORD('$MARIADB_ROOT_PASSWORD_ESCAPED')"
}

_unix_socket_auth
