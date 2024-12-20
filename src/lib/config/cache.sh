#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_e85fa6af="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_e85fa6af}/../utils/all.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_e85fa6af}/yaml/array.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_e85fa6af}/yaml/map.sh"

if [ -z "${__config_filepath}" ]; then
    lerror "env __config_filepath is empty"
    exit 1
fi

function config::cache::delete() {
    config::map::delete_key "." "cache" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::is_exists() {
    config::map::has_key "." "cache" "${__config_filepath}"
}

function config::cache::is_not_exists() {
    ! config::cache::is_exists
}

######################## top_apps 相关 ########################

function config::cache::top_apps::is_exists() {
    config::map::has_key ".cache" "top_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::cache::top_apps::is_not_exists() {
    ! config::cache::top_apps::is_exists
}

function config::cache::top_apps::delete() {
    config::map::delete_key ".cache" "top_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::cache::top_apps::all() {
    # shellcheck disable=SC2034
    local -n top_apps_6f9f87d6="$1"
    shift

    local temp_str_6f9f87d6

    temp_str_6f9f87d6="$(config::array::all ".cache.top_apps" "${__config_filepath}")" || return "$SHELL_FALSE"
    array::readarray top_apps_6f9f87d6 < <(echo "${temp_str_6f9f87d6}")

    return "$SHELL_TRUE"
}

function config::cache::top_apps::clean() {
    config::array::clean ".cache.top_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::cache::top_apps::rpush_unique() {
    local app="$1"
    config::array::rpush_unique ".cache.top_apps" "$app" "${__config_filepath}" || return "$SHELL_FALSE"
}

######################## exclude_apps 相关 ########################

function config::cache::exclude_apps::is_exists() {
    config::map::has_key ".cache" "exclude_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::cache::exclude_apps::is_not_exists() {
    ! config::cache::exclude_apps::is_exists
}

function config::cache::exclude_apps::all() {
    # shellcheck disable=SC2034
    local -n exclude_apps_22d8e2fc="$1"
    shift

    local temp_str_22d8e2fc

    temp_str_22d8e2fc="$(config::array::all ".cache.exclude_apps" "${__config_filepath}")" || return "$SHELL_FALSE"
    array::readarray exclude_apps_22d8e2fc < <(echo "${temp_str_22d8e2fc}")
    return "$SHELL_TRUE"
}

function config::cache::exclude_apps::clean() {
    config::array::clean ".cache.exclude_apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::cache::exclude_apps::rpush_unique() {
    local app="$1"
    config::array::rpush_unique ".cache.exclude_apps" "$app" "${__config_filepath}" || return "$SHELL_FALSE"
}

######################## APP 相关 ########################
function config::cache::apps::is_exists() {
    config::map::has_key ".cache" "apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::cache::apps::is_not_exists() {
    ! config::cache::apps::is_exists
}

function config::cache::apps::delete() {
    config::map::delete_key ".cache" "apps" "${__config_filepath}" || return "$SHELL_FALSE"
}

function config::cache::app::dependencies::is_exists() {
    local pm_app="$1"
    config::map::has_key ".cache.apps.[\"${pm_app}\"]" "dependencies" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::dependencies::is_not_exists() {
    ! config::cache::app::dependencies::is_exists "$@"
}

function config::cache::app::dependencies::delete() {
    local pm_app="$1"
    config::map::delete_key ".cache.apps.[\"${pm_app}\"]" "dependencies" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::dependencies::clean() {
    local pm_app="$1"
    config::array::clean ".cache.apps.[\"${pm_app}\"].dependencies" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::dependencies::is_contain() {
    local pm_app="$1"
    local dependency="$2"
    config::array::is_contain ".cache.apps.[\"${pm_app}\"].dependencies" "${dependency}" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::dependencies::rpush_unique() {
    local pm_app="$1"
    local dependency="$2"
    config::array::rpush_unique ".cache.apps.[\"${pm_app}\"].dependencies" "${dependency}" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::dependencies::all() {
    # shellcheck disable=SC2034
    local -n exclude_apps_18b945db="$1"
    shift
    local pm_app_18b945db="$1"
    shift

    local temp_str_18b945db

    temp_str_18b945db="$(config::array::all ".cache.apps.[\"${pm_app_18b945db}\"].dependencies" "${__config_filepath}")" || return "$SHELL_FALSE"
    array::readarray exclude_apps_18b945db < <(echo "${temp_str_18b945db}")

    return "$SHELL_TRUE"
}

function config::cache::app::required_by::is_exists() {
    local pm_app="$1"
    config::map::has_key ".cache.apps.[\"${pm_app}\"]" "required_by" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::required_by::delete() {
    local pm_app="$1"
    config::map::delete_key ".cache.apps.[\"${pm_app}\"]" "required_by" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::required_by::clean() {
    local pm_app="$1"
    config::array::clean ".cache.apps.[\"${pm_app}\"].required_by" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::required_by::is_contain() {
    local pm_app="$1"
    local dependency="$2"
    config::array::is_contain ".cache.apps.[\"${pm_app}\"].required_by" "${dependency}" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::required_by::rpush_unique() {
    local pm_app="$1"
    local dependency="$2"
    config::array::rpush_unique ".cache.apps.[\"${pm_app}\"].required_by" "${dependency}" "${__config_filepath}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function config::cache::app::required_by::all() {
    # shellcheck disable=SC2034
    local -n exclude_apps_6c0b3f04="$1"
    shift
    local pm_app_6c0b3f04="$1"
    shift

    local temp_str_6c0b3f04

    temp_str_6c0b3f04="$(config::array::all ".cache.apps.[\"${pm_app_6c0b3f04}\"].required_by" "${__config_filepath}")" || return "$SHELL_FALSE"
    array::readarray exclude_apps_6c0b3f04 < <(echo "${temp_str_6c0b3f04}")

    return "$SHELL_TRUE"
}
