#!/bin/bash

# 开发协助脚本
# 1. 没有其他依赖
# 2. 和安装脚本没有关系，因为开发环境和安装环境不是同一个

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_d6dc03c7="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "$SCRIPT_DIR_d6dc03c7/lib/utils/all.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR_d6dc03c7/manager/base.sh"
# shellcheck source=/dev/null
source "$SCRIPT_DIR_d6dc03c7/manager/app_manager.sh"

function develop::gen_uuid() {
    uuidgen | awk -F '-' '{print $1}'
}

function develop::update_trait_script() {
    local app_name="$1"
    local app_dir="${SCRIPT_DIR_d6dc03c7}/app/$app_name"

    local uuid
    uuid=$(develop::gen_uuid)
    sed -i "s/SCRIPT_DIR_uuid/SCRIPT_DIR_$uuid/g" "${app_dir}/trait.sh"
    sed -i "s/template/""${app_name}""/g" "${app_dir}/trait.sh"
}

function develop::update_readme() {
    local app_name="$1"
    local app_dir="${SCRIPT_DIR_d6dc03c7}/app/$app_name"

    sed -i "s/app_name/$app_name/" "${app_dir}/README.asciidoc"
}

function develop::create_app() {
    if [ $# -ne 1 ]; then
        lerror "add app failed, param app_name is empty"
    fi

    if [ -z "$1" ]; then
        lerror "add app failed, param app_name is empty"
        return "$SHELL_FALSE"
    fi

    local app_name="$1"

    local app_dir="${SCRIPT_DIR_d6dc03c7}/app/$app_name"

    if [ -e "${app_dir}" ]; then
        println_warn "app already exists: $app_name"
        return "$SHELL_FALSE"
    fi

    println_info "add app: $app_name"

    cp -r "${SCRIPT_DIR_d6dc03c7}/app_template" "${app_dir}"

    develop::update_trait_script "$app_name" || return "$SHELL_FALSE"

    develop::update_readme "$app_name" || return "$SHELL_FALSE"
}

function develop::update_template() {
    local app_dir
    for app_dir in "${SCRIPT_DIR_d6dc03c7}/app"/*; do
        local app_name
        app_name="$(basename "$app_dir")"
        if [ ! -d "$app_dir" ]; then
            println_warn "$app_dir is not a directory"
            continue
        fi

        linfo "update app($app_name) template"
        # 复制新的文件
        cp -r --update=none "${SCRIPT_DIR_d6dc03c7}/app_template"/* "${app_dir}"
        if [ $? -ne "$SHELL_TRUE" ]; then
            lerror "copy template file to app($app_name) failed"
            return "$SHELL_FALSE"
        fi

    done
}

function develop::call_trait() {
    local app_name="$1"
    local sub_command="$2"

    if [ -z "$app_name" ]; then
        lerror "call trait failed, param app_name is empty"
        println_error "call trait failed, param app_name is empty"
        return "$SHELL_FALSE"
    fi

    if [ -z "$sub_command" ]; then
        lerror "call trait failed, param sub_command is empty"
        println_error "call trait failed, param sub_command is empty"
        return "$SHELL_FALSE"
    fi

    manager::app::run_custom_manager "custom:${app_name}" "${sub_command}" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

function develop::command() {
    local sum_command="$1"
    local command_params=("${@:2}")
    case "${sum_command}" in

    "create")
        develop::create_app "${command_params[@]}" || return "$SHELL_FALSE"
        ;;

    "update")
        develop::update_template || return "$SHELL_FALSE"
        ;;

    "check_loop")
        manager::app::check_loop_relationships || return "$SHELL_FALSE"
        ;;

    "trait")
        develop::call_trait "${command_params[@]}" || return "$SHELL_FALSE"
        ;;

    *)
        lerror "unknown sub cmd(${sum_command})"
        return "$SHELL_FALSE"
        ;;
    esac
    return "$SHELL_TRUE"
}
