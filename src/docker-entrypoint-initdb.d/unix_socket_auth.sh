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
    local MARIADB_ROOT_PASSWORD_SQL
    if [ -n "$MARIADB_ROOT_PASSWORD_HASH" ]; then
        MARIADB_ROOT_PASSWORD_SQL="'$(docker_sql_escape_string_literal "$MARIADB_ROOT_PASSWORD_HASH")'"
    else
        MARIADB_ROOT_PASSWORD_SQL="PASSWORD('$(docker_sql_escape_string_literal "$MARIADB_ROOT_PASSWORD")')"
    fi

    docker_process_sql \
        <<<"ALTER USER 'root'@'localhost' IDENTIFIED VIA unix_socket OR mysql_native_password USING $MARIADB_ROOT_PASSWORD_SQL"
}

_unix_socket_auth
