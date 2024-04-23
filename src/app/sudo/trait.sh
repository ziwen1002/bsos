#!/bin/bash

# dirname 处理不了相对路径， dirname ../../xxx => ../..
# shellcheck disable=SC2034
SCRIPT_DIR_3c59328b="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/utils/all.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/package_manager/manager.sh"
# shellcheck disable=SC1091
source "$SRC_ROOT_DIR/lib/config/config.sh"

# 指定使用的包管理器
function sudo::trait::package_manager() {
    # 这个是全局前置安装包，只能使用pacman安装
    echo "pacman"
}

# 需要安装包的名称，如果安装一个应用需要安装多个包，那么这里填写最核心的包，其他的包算是依赖
function sudo::trait::package_name() {
    echo "sudo"
}

# 简短的描述信息，查看包的信息的时候会显示
function sudo::trait::description() {
    package_manager::package_description "$(sudo::trait::package_manager)" "$(sudo::trait::package_name)"
}

# 安装向导，和用户交互相关的，然后将得到的结果写入配置
# 后续安装的时候会用到的配置
function sudo::trait::install_guide() {
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
function sudo::trait::pre_install() {
    return "${SHELL_TRUE}"
}

# 安装的操作
function sudo::trait::do_install() {
    # 执行 su 需要输入密码
    cmd::run_cmd_with_history printf "${ROOT_PASSWORD}" "|" su - root -c \""pacman -S --needed --noconfirm  $(sudo::trait::package_name)"\" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 安装的后置操作，比如写配置文件
function sudo::trait::post_install() {
    return "${SHELL_TRUE}"
}

# 卸载的前置操作，比如卸载依赖
function sudo::trait::pre_uninstall() {
    return "${SHELL_TRUE}"
}

# 卸载的操作
function sudo::trait::do_uninstall() {
    # 判断 sudo 是否安装
    # which "$(sudo::trait::package_name)" >/dev/null 2>&1 # which 命令可能没有安装
    if [ -f "/usr/bin/$(sudo::trait::package_name)" ]; then
        linfo "$(sudo::trait::package_name) is not installed"
        return "$SHELL_TRUE"
    fi

    # 执行 su 需要输入密码
    cmd::run_cmd_with_history printf "${ROOT_PASSWORD}" "|" su - root -c \""pacman -R --noconfirm $(sudo::trait::package_name)"\" || return "${SHELL_FALSE}"
    return "${SHELL_TRUE}"
}

# 卸载的后置操作，比如删除临时文件
function sudo::trait::post_uninstall() {
    return "${SHELL_TRUE}"
}

# 有一些操作是需要特定环境才可以进行的
# 例如：
# 1. Hyprland 的插件需要在Hyprland运行时才可以启动
# 函数内部需要自己检测环境是否满足才进行相关操作。
function sudo::trait::fixme() {
    return "${SHELL_TRUE}"
}

# fixme 的逆操作
# 有一些操作如果不进行 fixme 的逆操作，可能会有残留。
# 如果直接卸载也不会有残留就不用处理
function sudo::trait::unfixme() {
    println_info "${PM_APP_NAME}: start undo fixme..."

    return "${SHELL_TRUE}"
}

# 安装和运行的依赖
# 如下的包才应该添加进来
# 1. 使用包管理器安装，它没有处理的依赖，并且有额外的配置或者其他设置。如果没有额外的配置，可以在 sudo::trait::pre_install 函数里直接安装就可以了。
# 2. 包管理器安装处理了依赖，但是这个依赖有额外的配置或者其他设置的
# NOTE: 这里填写的依赖是必须要安装的
function sudo::trait::dependencies() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

# 有一些软件是本程序安装后才可以安装的。
# 例如程序的插件、主题等。
# 虽然可以建立插件的依赖是本程序，然后配置安装插件，而不是安装本程序。但是感觉宣兵夺主了。
# 这些软件是本程序的一个补充，一般可安装可不安装，但是为了简化安装流程，还是默认全部安装
function sudo::trait::features() {
    local apps=()
    array::print apps
    return "${SHELL_TRUE}"
}

function sudo::trait::main() {
    return "$SHELL_TRUE"
}

sudo::trait::main
