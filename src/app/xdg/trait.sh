#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_29b7d4b3="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/config/config.sh"

# 指定使用的包管理器
function xdg::trait::package_manager() {
    echo "default"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function xdg::trait::package_name() {
    # 它是一系列xdg相关的包，所以没有具体的包名
    echo "_xdg_spec_group"
}

# 简短的描述信息，查看包的信息的时候会显示
function xdg::trait::description() {
    echo "xdg specification for applications"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function xdg::trait::install_guide() {
    if config::app::is_configed::get "$PM_APP_NAME"; then
        # 说明已经配置过了
        linfo "app(${PM_APP_NAME}) has configed, not need to config again"
        return "$SHELL_TRUE"
    fi
    # TODO: 做你想做的
    config::app::is_configed::set_true "$PM_APP_NAME" || return "$SHELL_FALSE"
    return "${SHELL_TRUE}"
}

# 安装的前置操作，比如下载源代码
function xdg::trait::pre_install() {
    return "${SHELL_TRUE}"
}

# 安装的操作
function xdg::trait::do_install() {
    # package_manager::pacman::install "$(xdg::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function xdg::trait::post_install() {
    # https://wiki.archlinux.org/title/XDG_user_directories
    cmd::run_cmd_with_history xdg-user-dirs-update
    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function xdg::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function xdg::trait::do_uninstall() {
    # package_manager::pacman::uninstall "$(xdg::trait::package_name)" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function xdg::trait::post_uninstall() {
    return "${SHELL_TRUE}"
}

# 有一些操作是需要特定环境才可以进行的
# 例如：
# 1. Hyprland 的插件需要在Hyprland运行时才可以启动
# 函数内部需要自己检测环境是否满足才进行相关操作。
function xdg::trait::fixme() {
    return "${SHELL_TRUE}"
}

# fixme 的逆操作
# 有一些操作如果不进行 fixme 的逆操作，可能会有残留。
# 如果直接卸载也不会有残留就不用处理
function xdg::trait::unfixme() {
    println_info "${PM_APP_NAME}: start undo fixme..."

    return "${SHELL_TRUE}"
}

# 安装和运行的依赖
# 一般来说使用包管理器安装程序时会自动安装依赖的包
# 但是有一些非官方的包不一定添加了依赖
# 或者有一些依赖的包不仅安装就可以了，它自身也需要进行额外的配置。
# 因此还是需要为一些特殊场景添加依赖
# NOTE: 这里的依赖包是必须安装的，并且在安装本程序前进行安装
function xdg::trait::dependencies() {
    # 一个APP的书写格式是："包管理器:包名"
    # 例如：
    # pacman:vim
    # yay:vim
    # pamac:vim
    # custom:vim   自定义，也就是通过本脚本进行安装
    local apps=("default:xdg-utils" "default:xdg-user-dirs")
    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function xdg::trait::features() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

function xdg::trait::main() {
    return "$SHELL_TRUE"
}

xdg::trait::main
