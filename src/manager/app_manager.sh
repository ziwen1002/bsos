#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_612d794c="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_612d794c}/../lib/utils/all.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR_612d794c}/../lib/utils/utest.sh"

function manager::app::is_package_name_valid() {
    local package_name="$1"
    # https://www.gnu.org/software/bash/manual/html_node/Conditional-Constructs.html#index-_005b_005b
    # https://www.gnu.org/software/bash/manual/html_node/Pattern-Matching.html
    if [[ ! "$package_name" =~ ^[^:[:space:]]+:[^:[:space:]]+$ ]]; then
        lerror "package_name($package_name) is invalid, it should be 'package_manager:app_name'"
        return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

function manager::app::parse_package_manager() {
    local pm_app="$1"
    manager::app::is_package_name_valid "$pm_app" || return "$SHELL_FALSE"
    local package_manager=${pm_app%:*}
    echo "$package_manager"
}

function manager::app::parse_app_name() {
    local pm_app="$1"
    manager::app::is_package_name_valid "$pm_app" || return "$SHELL_FALSE"
    local app_name=${pm_app#*:}
    echo "$app_name"
}

function manager::app::is_custom() {
    local pm_app="$1"
    manager::app::is_package_name_valid "$pm_app" || return "$SHELL_FALSE"

    local package_manager
    package_manager=$(manager::app::parse_package_manager "$pm_app")
    if [ "$package_manager" == "custom" ]; then
        return "$SHELL_TRUE"
    fi
    return "$SHELL_FALSE"
}

function manager::app::app_directory() {
    local pm_app="$1"
    manager::app::is_package_name_valid "$pm_app" || return "$SHELL_FALSE"

    if ! manager::app::is_custom "$pm_app"; then
        lerror "app(${pm_app}) is not custom"
        return "$SHELL_FALSE"
    fi

    local app_name
    app_name=$(manager::app::parse_app_name "$pm_app")
    echo "${SRC_ROOT_DIR}/app/${app_name}"
}

function manager::app::run_custom_manager() {
    local pm_app="$1"
    local sub_command="$2"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty, params=$*"
        return "$SHELL_FALSE"
    fi

    if [ -z "$sub_command" ]; then
        lerror "sub_command is empty"
        return "$SHELL_FALSE"
    fi

    local app_name
    app_name=$(manager::app::parse_app_name "$pm_app")

    if ! manager::app::is_custom "$pm_app"; then
        lerror "app(${pm_app}) is not custom, sub_command=${sub_command}"
        return "$SHELL_FALSE"
    fi

    local custom_manager_path="${SCRIPT_DIR_612d794c}/custom_manager.sh"

    if [ ! -e "${custom_manager_path}" ]; then
        lerror "app install manager is not exists, custom_manager_path=${custom_manager_path}"
        return "${SHELL_FALSE}"
    fi

    "$custom_manager_path" "${app_name}" "${sub_command}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function manager::app::is_no_loop_dependencies() {
    local pm_app="$1"
    local link_path="$2"

    manager::app::is_package_name_valid "$pm_app" || return "$SHELL_FALSE"

    local temp_array=()
    local item
    local temp_str

    if ! manager::app::is_custom "$pm_app"; then
        # 如果不是自定义的包，那么不需要检查循环依赖
        return "$SHELL_TRUE"
    fi

    echo "$link_path" | grep -wq "$pm_app"
    if [ $? -eq "${SHELL_TRUE}" ]; then
        println_error "app($pm_app) has loop dependencies. dependencies link path: ${link_path} $pm_app"
        lerror "app($pm_app) has loop dependencies. dependencies link path: ${link_path} $pm_app"
        return "$SHELL_FALSE"
    fi

    temp_str="$(manager::app::run_custom_manager "${pm_app}" "dependencies")" || return "$SHELL_FALSE"
    array::readarray temp_array < <(echo "$temp_str")
    for item in "${temp_array[@]}"; do
        manager::app::is_no_loop_dependencies "${item}" "$link_path $pm_app" || return "$SHELL_FALSE"
    done

    return "$SHELL_TRUE"
}

function manager::app::is_no_loop_features() {
    local pm_app="$1"
    local link_path="$2"

    manager::app::is_package_name_valid "$pm_app" || return "$SHELL_FALSE"

    local temp_array=()
    local item
    local temp_str

    if ! manager::app::is_custom "$pm_app"; then
        # 如果不是自定义的包，那么不需要检查循环依赖
        return "$SHELL_TRUE"
    fi

    echo "$link_path" | grep -wq "$pm_app"
    if [ $? -eq "${SHELL_TRUE}" ]; then
        println_error "app($pm_app) has loop features. features link path: $pm_app ${link_path}"
        lerror "app($pm_app) has loop features. features link path: $pm_app ${link_path}"
        return "$SHELL_FALSE"
    fi

    temp_str="$(manager::app::run_custom_manager "${pm_app}" "features")" || return "$SHELL_FALSE"
    array::readarray temp_array < <(echo "$temp_str")
    for item in "${temp_array[@]}"; do
        manager::app::is_no_loop_features "${item}" "$pm_app $link_path" || return "$SHELL_FALSE"
    done
    return "$SHELL_TRUE"
}

# 检查循环依赖
function manager::app::check_loop_dependencies() {

    linfo "start check all app loop dependencies..."
    println_info "start check all app loop dependencies, it may take a long time..."

    for app_path in "${SRC_ROOT_DIR}/app"/*; do
        local app_name
        app_name=$(basename "${app_path}")
        local pm_app="custom:$app_name"

        manager::app::is_no_loop_dependencies "${pm_app}" || return "$SHELL_FALSE"
        manager::app::is_no_loop_features "${pm_app}" || return "$SHELL_FALSE"
    done

    linfo "check all app loop dependencies success"
    println_success "check all app loop dependencies success"
    return "$SHELL_TRUE"
}

# 根据依赖关系递归调用 trait 的命令
function manager::app::do_command_recursion() {
    local command="$1"
    local pm_app="$2"
    local level_indent="$3"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi
    local item
    local dependencies
    local features
    local temp_str

    if ! manager::app::is_custom "${pm_app}"; then
        linfo "app(${pm_app}) is not custom, skip run ${command}"
        println_info "${level_indent}${pm_app}: is not custom, skip run ${command}"
        return "$SHELL_TRUE"
    fi

    linfo "app(${pm_app}) run ${command}..."
    println_info "${level_indent}${pm_app}: run ${command}..."

    # 获取它的依赖
    linfo "app(${pm_app}) dependencies run ${command}..."
    println_info "${level_indent}${pm_app}: dependencies run ${command}..."
    temp_str="$(manager::app::run_custom_manager "${pm_app}" "dependencies")"
    array::readarray dependencies < <(echo "$temp_str")

    for item in "${dependencies[@]}"; do
        manager::app::do_command_recursion "${command}" "${item}" "${level_indent}  " || return "$SHELL_FALSE"
    done

    linfo "app(${pm_app}) self run ${command}..."
    println_info "${level_indent}${pm_app}: self run ${command}..."
    manager::app::run_custom_manager "${pm_app}" "${command}" || return "$SHELL_FALSE"

    # 获取它的feature
    linfo "app(${pm_app}) features run ${command}..."
    println_info "${level_indent}${pm_app}: features run ${command}..."
    temp_str="$(manager::app::run_custom_manager "${pm_app}" "features")"
    array::readarray features < <(echo "$temp_str")
    for item in "${features[@]}"; do
        manager::app::do_command_recursion "${command}" "${item}" "${level_indent}  " || return "$SHELL_FALSE"
    done

    linfo "app(${pm_app}) run ${command} done"
    println_info "${level_indent}${pm_app}: run ${command} done"

    return "${SHELL_TRUE}"
}

# 根据依赖关系递归调用 trait 的命令
function manager::app::do_command_recursion_reverse() {
    local command="$1"
    local pm_app="$2"
    local level_indent="$3"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi
    local item
    local dependencies
    local features
    local temp_str

    if ! manager::app::is_custom "${pm_app}"; then
        linfo "app(${pm_app}) is not custom, skip run ${command}"
        println_info "${level_indent}${pm_app}: is not custom, skip run ${command}"
        return "$SHELL_TRUE"
    fi

    linfo "app(${pm_app}) run ${command}..."
    println_info "${level_indent}${pm_app}: run ${command}..."

    # 获取它的feature
    linfo "app(${pm_app}) features run ${command}..."
    println_info "${level_indent}${pm_app}: features run ${command}..."
    temp_str="$(manager::app::run_custom_manager "${pm_app}" "features")"
    array::readarray features < <(echo "$temp_str")
    for item in "${features[@]}"; do
        manager::app::do_command_recursion_reverse "${command}" "${item}" "${level_indent}  " || return "$SHELL_FALSE"
    done

    linfo "app(${pm_app}) self run ${command}..."
    println_info "${level_indent}${pm_app}: self run ${command}..."
    manager::app::run_custom_manager "${pm_app}" "${command}" || return "$SHELL_FALSE"

    # 获取它的依赖
    linfo "app(${pm_app}) dependencies run ${command}..."
    println_info "${level_indent}${pm_app}: dependencies run ${command}..."
    temp_str="$(manager::app::run_custom_manager "${pm_app}" "dependencies")"
    array::readarray dependencies < <(echo "$temp_str")

    for item in "${dependencies[@]}"; do
        manager::app::do_command_recursion_reverse "${command}" "${item}" "${level_indent}  " || return "$SHELL_FALSE"
    done

    linfo "app(${pm_app}) run ${command} done"
    println_info "${level_indent}${pm_app}: run ${command} done"

    return "${SHELL_TRUE}"
}

# 运行安装向导
function manager::app::do_install_guide() {
    local pm_app="$1"
    manager::app::do_command_recursion "install_guide" "${pm_app}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 使用包管理器直接安装
function manager::app::do_install_use_pm() {
    local pm_app="$1"
    local level_indent="$2"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi

    if manager::app::is_custom "${pm_app}"; then
        lerror "app(${pm_app}) is custom, can not use package manager direct install"
        println_error "${level_indent}${pm_app}: is custom, can not use package manager direct install"
        return "$SHELL_FALSE"
    fi

    local package_manager
    local package

    package_manager=$(manager::app::parse_package_manager "$pm_app")
    package=$(manager::app::parse_app_name "$pm_app")

    linfo "${pm_app}: direct installing app with ${package_manager}"
    println_info "${level_indent}${pm_app}: direct installing app with ${package_manager}"

    package_manager::install "${package_manager}" "${package}" || return "$SHELL_FALSE"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "${pm_app}: direct install app with ${package_manager} failed"
        println_error "${level_indent}${pm_app}: direct install app with ${package_manager} failed"
        return "$SHELL_FALSE"
    fi

    linfo "${pm_app}: direct install app with ${package_manager} success"
    println_success "${level_indent}${pm_app}: direct install app with ${package_manager} success"

    return "$SHELL_TRUE"
}

function manager::app::do_install_use_custom() {
    local pm_app="$1"
    local level_indent="$2"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi
    local dependencies
    local features
    local item
    local temp_str

    if ! manager::app::is_custom "${pm_app}"; then
        lerror "app(${pm_app}) is not custom, can not use custom to install"
        println_error "${level_indent}${pm_app}: is not custom, can not use custom to install"
        return "$SHELL_FALSE"
    fi

    if [ ! -e "$(manager::app::app_directory "${pm_app}")" ]; then
        lerror "app(${pm_app}) is not exist."
        return "$SHELL_FALSE"
    fi

    # 安装所有 dependencies
    linfo "start install app(${pm_app}) dependencies..."
    println_info "${level_indent}${pm_app}: install dependencies..."

    temp_str="$(manager::app::run_custom_manager "${pm_app}" "dependencies")" || return "$SHELL_FALSE"
    array::readarray dependencies < <(echo "$temp_str")

    for item in "${dependencies[@]}"; do
        manager::app::do_install "${item}" "  ${level_indent}" || return "$SHELL_FALSE"
    done

    linfo "app(${pm_app}) all dependencies install success"
    println_success "${level_indent}${pm_app}: all dependencies install success"

    # 安装自己
    linfo "start install app(${pm_app}) ..."
    println_info "${level_indent}${pm_app}: installing self... "
    manager::app::run_custom_manager "${pm_app}" "install"
    if [ $? -ne "${SHELL_TRUE}" ]; then
        lerror "install app(${pm_app}) failed"
        println_error "${level_indent}${pm_app}: install failed."
        return "$SHELL_FALSE"
    fi

    # 安装所有 features
    linfo "start install app(${pm_app}) features..."
    println_info "${level_indent}${pm_app}: install features..."

    temp_str="$(manager::app::run_custom_manager "${pm_app}" "features")"
    array::readarray features < <(echo "$temp_str")

    for item in "${features[@]}"; do
        manager::app::do_install "${item}" "  ${level_indent}" || return "$SHELL_FALSE"
    done
    linfo "app(${pm_app}) all features install success..."
    println_success "${level_indent}${pm_app}: all features install success"
    return "$SHELL_TRUE"
}

# 安装一个APP，附带其他的操作
function manager::app::do_install() {
    local pm_app="$1"
    local level_indent="$2"

    if [ -z "$pm_app" ]; then
        lerror "param pm_app is empty"
        return "$SHELL_FALSE"
    fi

    println_info "${level_indent}${pm_app}: install..."
    linfo "start install app(${pm_app})..."

    if config::cache::installed_apps::is_contain "${pm_app}"; then
        linfo "app(${pm_app}) has installed. dont need install again."
        println_success "${level_indent}${pm_app}: installed. dont need install again."
        return "${SHELL_TRUE}"
    fi

    if ! manager::app::is_custom "$pm_app"; then
        manager::app::do_install_use_pm "$pm_app" "$level_indent" || return "$SHELL_FALSE"
    else
        manager::app::do_install_use_custom "$pm_app" "$level_indent" || return "$SHELL_FALSE"
    fi

    config::cache::installed_apps::rpush "${pm_app}" || return "$SHELL_FALSE"

    linfo "install app(${pm_app}) success."
    println_success "${level_indent}${pm_app}: install success."
    return "${SHELL_TRUE}"
}

# 运行 fixme
function manager::app::do_fixme() {
    local pm_app="$1"
    manager::app::do_command_recursion "fixme" "${pm_app}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

function manager::app::do_unfixme() {
    local pm_app="$1"
    manager::app::do_command_recursion_reverse "unfixme" "${pm_app}" || return "$SHELL_FALSE"
    return "$SHELL_TRUE"
}

# 使用包管理器直接安装
function manager::app::_do_uninstall_use_pm() {
    local pm_app="$1"
    local level_indent="$2"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi

    if manager::app::is_custom "${pm_app}"; then
        lerror "app(${pm_app}) is custom, can not use package manager direct uninstall"
        println_error "${level_indent}${pm_app}: is custom, can not use package manager direct uninstall"
        return "$SHELL_FALSE"
    fi

    local package_manager
    local package

    package_manager=$(manager::app::parse_package_manager "$pm_app")
    package=$(manager::app::parse_app_name "$pm_app")

    linfo "${pm_app}: direct uninstalling app with ${package_manager}"
    println_info "${level_indent}${pm_app}: direct uninstalling app with ${package_manager}"

    package_manager::uninstall "${package_manager}" "${package}" || return "$SHELL_FALSE"
    if [ $? -ne "$SHELL_TRUE" ]; then
        lerror "${pm_app}: direct uninstall app with ${package_manager} failed"
        println_error "${level_indent}${pm_app}: direct uninstall app with ${package_manager} failed"
        return "$SHELL_FALSE"
    fi

    linfo "${pm_app}: direct uninstall app with ${package_manager} success"
    println_success "${level_indent}${pm_app}: direct uninstall app with ${package_manager} success"

    return "$SHELL_TRUE"
}

function manager::app::_do_uninstall_use_custom() {
    local pm_app="$1"
    local level_indent="$2"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi
    local dependencies
    local features
    local item
    local temp_str

    if ! manager::app::is_custom "${pm_app}"; then
        lerror "app(${pm_app}) is not custom, can not use custom to uninstall"
        println_error "${level_indent}${pm_app}: is not custom, can not use custom to uninstall"
        return "$SHELL_FALSE"
    fi

    if [ ! -e "$(manager::app::app_directory "${pm_app}")" ]; then
        lerror "app(${pm_app}) is not exist."
        return "$SHELL_FALSE"
    fi

    # 先卸载所有 features
    linfo "start uninstall app(${pm_app}) features..."
    println_info "${level_indent}${pm_app}: uninstall features..."
    temp_str="$(manager::app::run_custom_manager "${pm_app}" "features")"
    array::readarray features < <(echo "$temp_str")
    for item in "${features[@]}"; do
        manager::app::do_uninstall "${item}" "  ${level_indent}" || return "$SHELL_FALSE"
    done
    linfo "app(${pm_app}) all features uninstall success"
    println_success "${level_indent}${pm_app}: all features uninstall success"

    # 卸载自己
    linfo "start uninstall app(${pm_app}) self..."
    println_info "${level_indent}${pm_app}: uninstall self..."
    manager::app::run_custom_manager "${pm_app}" "uninstall" || return "$SHELL_FALSE"
    linfo "app(${pm_app}) uninstall self success"
    println_success "${level_indent}${pm_app}: uninstall self success"

    # 卸载所有 dependencies
    linfo "start uninstall app(${pm_app}) dependencies..."
    println_info "${level_indent}${pm_app}: uninstall dependencies..."

    temp_str="$(manager::app::run_custom_manager "${pm_app}" "dependencies")" || return "$SHELL_FALSE"
    array::readarray dependencies < <(echo "$temp_str")

    for item in "${dependencies[@]}"; do
        manager::app::do_uninstall "${item}" "  ${level_indent}" || return "$SHELL_FALSE"
    done

    linfo "app(${pm_app}) all dependencies uninstall success"
    println_success "${level_indent}${pm_app}: all dependencies uninstall success"

    linfo "app(${pm_app}) use custom uninstall done"
    println_success "${level_indent}${pm_app}: use custom uninstall done"
    return "$SHELL_TRUE"
}

function manager::app::do_uninstall() {
    local pm_app="$1"
    local level_indent="$2"

    if [ -z "$pm_app" ]; then
        lerror "pm_app is empty"
        return "$SHELL_FALSE"
    fi
    println_info "${level_indent}${pm_app}: uninstalling..."
    linfo "start uninstall app(${pm_app})..."

    if config::cache::uninstalled_apps::is_contain "${pm_app}"; then
        linfo "app(${pm_app}) has uninstalled. dont need uninstall again."
        println_success "${level_indent}${pm_app}: uninstalled. dont need uninstall again."
        return "${SHELL_TRUE}"
    fi

    if ! manager::app::is_custom "$pm_app"; then
        manager::app::_do_uninstall_use_pm "$pm_app" "$level_indent" || return "$SHELL_FALSE"
    else
        manager::app::_do_uninstall_use_custom "$pm_app" "$level_indent" || return "$SHELL_FALSE"
    fi

    config::cache::uninstalled_apps::rpush "${pm_app}" || return "$SHELL_FALSE"

    linfo "uninstall app(${pm_app}) success."
    println_success "${level_indent}${pm_app}: uninstall success."
    return "$SHELL_TRUE"
}

########################### 下面是测试代码 ###########################
function manager::app::_test_is_package_name_valid() {
    manager::app::is_package_name_valid "pamac:app_name"
    utest::assert $?

    manager::app::is_package_name_valid ""
    utest::assert_fail $?

    manager::app::is_package_name_valid "pamac app_name"
    utest::assert_fail $?

    manager::app::is_package_name_valid "pamac"
    utest::assert_fail $?

    manager::app::is_package_name_valid ":"
    utest::assert_fail $?

    manager::app::is_package_name_valid "::"
    utest::assert_fail $?

    manager::app::is_package_name_valid "pamac:"
    utest::assert_fail $?

    manager::app::is_package_name_valid ":pamac"
    utest::assert_fail $?

    manager::app::is_package_name_valid "pamac::pamac"
    utest::assert_fail $?

    manager::app::is_package_name_valid " :pamac"
    utest::assert_fail $?

    manager::app::is_package_name_valid "pamac: "
    utest::assert_fail $?

    manager::app::is_package_name_valid " pamac:pamac"
    utest::assert_fail $?

    manager::app::is_package_name_valid "pamac :pamac"
    utest::assert_fail $?

    manager::app::is_package_name_valid "pamac: pamac"
    utest::assert_fail $?

    manager::app::is_package_name_valid "pamac:pamac "
    utest::assert_fail $?

    manager::app::is_package_name_valid " pamac : pamac "
    utest::assert_fail $?

    manager::app::is_package_name_valid "pamac：pamac"
    utest::assert_fail $?
}

string::is_true "$TEST" && manager::app::_test_is_package_name_valid
true
