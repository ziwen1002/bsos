#!/bin/bash

if [ -n "${SCRIPT_DIR_72e5c74f}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_72e5c74f="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# NOTE: 尽可能少的依赖其他脚本
# shellcheck source=/dev/null
source "${SCRIPT_DIR_72e5c74f}/../constant.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_72e5c74f}/../debug.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_72e5c74f}/../print.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_72e5c74f}/../utest.sh" || exit 1
# shellcheck source=/dev/null
source "${SCRIPT_DIR_72e5c74f}/formatter.sh" || exit 1

function log::handler::stream_handler::_init() {
    if [ -v "__log_stream_handler_stream" ]; then
        return "$SHELL_TRUE"
    fi
    export __log_stream_handler_stream="tty"
}

function log::handler::stream_handler::set_stream() {
    local stream="$1"
    export __log_stream_handler_stream="$stream"
}

function log::handler::stream_handler::register() {
    log::handler::add "$LOG_HANDLER_STREAM" || return "$SHELL_FALSE"
    log::handler::stream_handler::_init || return "$SHELL_FALSE"
}

function log::handler::stream_handler::unregister() {
    log::handler::remove "$LOG_HANDLER_STREAM" || return "$SHELL_FALSE"
}

# 参数说明参考 log::handler::template_handler::trait::log
function log::handler::stream_handler::trait::log() {
    local stream
    local formatter
    local level
    local datetime_format
    local file
    local line
    local function_name
    local message_format
    local message_params=()

    local message
    local param
    local level_name
    local is_parse_self="$SHELL_TRUE"

    for param in "$@"; do
        if [ "$is_parse_self" == "$SHELL_FALSE" ]; then
            message_params+=("$param")
            continue
        fi
        case "$param" in
        --)
            is_parse_self="$SHELL_FALSE"
            ;;
        --stream=*)
            stream="${param#*=}"
            ;;
        --formatter=*)
            formatter="${param#*=}"
            ;;
        --level=*)
            level="${param#*=}"
            ;;
        --datetime-format=*)
            datetime_format="${param#*=}"
            ;;
        --file=*)
            file="${param#*=}"
            ;;
        --line=*)
            line="${param#*=}"
            ;;
        --function-name=*)
            function_name="${param#*=}"
            ;;
        --message-format=*)
            message_format="${param#*=}"
            ;;
        -*)
            println_error "[$(debug::function::call_stack)] unknown option $param"
            return "$SHELL_FALSE"
            ;;
        *)
            message_params+=("$param")
            ;;
        esac
    done

    stream="${stream:-${__log_stream_handler_stream}}"
    level_name=$(log::level::level_name "${level}") || return "$SHELL_FALSE"

    message=$(log::formatter::format_message --formatter="${formatter}" --level="${level}" --datetime-format="${datetime_format}" --file="${file}" --line="${line}" --function-name="${function_name}" --message-format="${message_format}" -- "${message_params[@]}") || return "$SHELL_FALSE"

    "println_${level_name}" --stream="$stream" -- "${message}" || return "$SHELL_FALSE"

    return "$SHELL_TRUE"
}

# ==================================== 下面是测试代码 ====================================

function log::handler::stream_handler::_main() {
    log::handler::stream_handler::_init

    return "$SHELL_TRUE"
}

log::handler::stream_handler::_main
