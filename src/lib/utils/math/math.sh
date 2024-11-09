#!/bin/bash

if [ -n "${SCRIPT_DIR_4947c3c0}" ]; then
    return
fi

# dirname 处理不了相对路径， dirname ../../xxx => ../..
SCRIPT_DIR_4947c3c0="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

# shellcheck source=/dev/null
source "${SCRIPT_DIR_4947c3c0}/../constant.sh"

# 判断是否是整数，正负整数都是整数
function math::is_integer() {
    local num=$1
    if [[ $num =~ ^-?[0-9]+$ ]]; then
        return "$SHELL_TRUE"
    else
        return "$SHELL_FALSE"
    fi
}

function math::is_not_integer() {
    ! math::is_integer "$1"
}

# 大于
# 1. 整数、浮点数
# 2. 正数、负数
function math::gt() {
    local num1=$1
    local num2=$2
    local res
    res=$(awk "BEGIN{if(${num1} > ${num2}) print 0; else print 1}") || return "$SHELL_FALSE"
    if [ "$res" = "$SHELL_TRUE" ]; then
        return "$SHELL_TRUE"
    else
        return "$SHELL_FALSE"
    fi
}

# 小于
# 1. 整数、浮点数
# 2. 正数、负数
function math::lt() {
    local num1=$1
    local num2=$2
    local res
    res=$(awk "BEGIN{if(${num1} < ${num2}) print 0; else print 1}") || return "$SHELL_FALSE"
    if [ "$res" = "$SHELL_TRUE" ]; then
        return "$SHELL_TRUE"
    else
        return "$SHELL_FALSE"
    fi
}

# 等于
# 1. 整数、浮点数
# 2. 正数、负数
function math::eq() {
    local num1=$1
    local num2=$2
    local res
    res=$(awk "BEGIN{if(${num1} == ${num2}) print 0; else print 1}") || return "$SHELL_FALSE"
    if [ "$res" = "$SHELL_TRUE" ]; then
        return "$SHELL_TRUE"
    else
        return "$SHELL_FALSE"
    fi
}

function math::ne() {
    ! math::eq "$1" "$2"
}

# 大于等于
# 1. 整数、浮点数
# 2. 正数、负数
function math::ge() {
    math::gt "$1" "$2" || math::eq "$1" "$2"
}

# 小于等于
# 1. 整数、浮点数
# 2. 正数、负数
function math::le() {
    math::lt "$1" "$2" || math::eq "$1" "$2"
}

# 向下取整
# 1.123 => 1
function math::floor() {
    local num=$1
    local res=""
    # awk '{ print floor($1) }' | awk -l math
    # awk int 是朝0截断:
    #   -3 => -3    -3.9 => -3
    #   0 => 0    -0 => -0
    #   1 => 1    1.9 => 1
    res=$(awk "BEGIN{print int($num)}") || return "$SHELL_FALSE"
    if math::eq "$num" "$res"; then
        echo "$res"
        return "$SHELL_TRUE"
    fi
    if math::ge "$num" 0; then
        echo "$res"
        return "$SHELL_TRUE"
    else
        # awk "BEGIN{print int($num - 1)}" || return "$SHELL_FALSE"
        echo "$((res - 1))"
        return "$SHELL_TRUE"
    fi
}

# 向上取整
# 1.123 => 2
function math::ceil() {
    local num=$1
    local res

    res=$(math::floor "$num") || return "$SHELL_FALSE"
    if math::eq "$num" "$res"; then
        echo "$res"
        return "$SHELL_TRUE"
    fi
    echo "$((res + 1))"

    return "$SHELL_TRUE"
}

# 四舍五入
# 1.123 => 1
# 1.5 => 2
# -1.500001 => -2
# -1.5 => -1
# -1.49999 => -1
# NOTE: 浮点数需要注意精度的问题
# 0.499999 => 0
# 0.4999999 => 1
function math::round() {
    local num=$1
    local res

    res=$(awk "BEGIN{print $num+0.5}") || return "$SHELL_FALSE"
    lerror "lzw_test res=$res"
    res=$(math::floor "$res") || return "$SHELL_FALSE"
    echo "$res"

    return "$SHELL_TRUE"
}

function math::_check_accuracy() {
    local accuracy="$1"
    shift
    if math::is_not_integer "$accuracy"; then
        lerror "param accuracy($accuracy) is not integer"
        return "$SHELL_FALSE"
    fi
    if math::le "$accuracy" 0; then
        lerror "param accuracy($accuracy) <= 0"
        return "$SHELL_FALSE"
    fi
    return "$SHELL_TRUE"
}

# NOTE: 浮点数需要注意精度的问题
# NOTE: 注意溢出
function math::add() {
    local num1="$1"
    shift
    local num2="$1"
    shift
    # 精度，默认2
    local accuracy="$1"
    shift
    local res

    if [ -z "$accuracy" ]; then
        res=$(awk "BEGIN{print (${num1} + ${num2})}")
    else
        math::_check_accuracy "$accuracy" || return "$SHELL_FALSE"
        res=$(awk "BEGIN{printf \"%.${accuracy}f\n\",(${num1} + ${num2})}")
    fi

    echo "$res"

    return "$SHELL_TRUE"
}

# NOTE: 浮点数需要注意精度的问题
# NOTE: 注意溢出
function math::sub() {
    local num1="$1"
    shift
    local num2="$1"
    shift
    # 精度，默认2
    local accuracy="$1"
    shift
    local res

    if [ -z "$accuracy" ]; then
        res=$(awk "BEGIN{print (${num1} - ${num2})}")
    else
        math::_check_accuracy "$accuracy" || return "$SHELL_FALSE"
        res=$(awk "BEGIN{printf \"%.${accuracy}f\n\",(${num1} - ${num2})}")
    fi

    echo "$res"

    return "$SHELL_TRUE"
}

# NOTE: 浮点数需要注意精度的问题
# NOTE: 注意溢出
function math::mul() {
    local num1="$1"
    shift
    local num2="$1"
    shift
    # 精度，默认2
    local accuracy="$1"
    shift
    local res

    if [ -z "$accuracy" ]; then
        res=$(awk "BEGIN{print (${num1} * ${num2})}")
    else
        math::_check_accuracy "$accuracy" || return "$SHELL_FALSE"
        res=$(awk "BEGIN{printf \"%.${accuracy}f\n\",(${num1} * ${num2})}")
    fi

    echo "$res"

    return "$SHELL_TRUE"
}

# NOTE: 浮点数需要注意精度的问题
function math::div() {
    # 被除数
    local dividend="$1"
    shift
    # 除数
    local divisor="$1"
    shift
    # 精度，默认2
    local accuracy="$1"
    shift

    local res

    if [ "$divisor" = "0" ]; then
        lerror "the divisor cannot be 0"
        return "$SHELL_FALSE"
    fi

    if [ -z "$accuracy" ]; then
        res=$(awk "BEGIN{print (${dividend} / ${divisor})}")
    else
        math::_check_accuracy "$accuracy" || return "$SHELL_FALSE"
        res=$(awk "BEGIN{printf \"%.${accuracy}f\n\",(${dividend} / ${divisor})}")
    fi

    echo "$res"
    return "$SHELL_TRUE"
}

######################################### 下面是单元测试代码 #########################################
function TEST::math::is_integer() {
    math::is_integer 0
    utest::assert $?

    math::is_integer "-0"
    utest::assert $?

    math::is_integer 1
    utest::assert $?

    math::is_integer "-1"
    utest::assert $?

    math::is_integer 0.0
    utest::assert_fail $?

    math::is_integer "-0.0"
    utest::assert_fail $?

    math::is_integer 1.0
    utest::assert_fail $?

    math::is_integer "-1.0"
    utest::assert_fail $?

    math::is_integer 1.1
    utest::assert_fail $?

    math::is_integer "-1.1"
    utest::assert_fail $?

    math::is_integer 1.1234567890
    utest::assert_fail $?

    math::is_integer "-1.1234567890"
    utest::assert_fail $?
}

function TEST::math::is_not_integer() {
    math::is_not_integer 0
    utest::assert_fail $?

    math::is_not_integer "-0"
    utest::assert_fail $?

    math::is_not_integer 1
    utest::assert_fail $?

    math::is_not_integer "-1"
    utest::assert_fail $?

    math::is_not_integer 0.0
    utest::assert $?

    math::is_not_integer "-0.0"
    utest::assert $?

    math::is_not_integer 1.0
    utest::assert $?

    math::is_not_integer "-1.0"
    utest::assert $?

    math::is_not_integer 1.1
    utest::assert $?

    math::is_not_integer "-1.1"
    utest::assert $?

    math::is_not_integer 1.1234567890
    utest::assert $?

    math::is_not_integer "-1.1234567890"
    utest::assert $?
}

function TEST::math::gt() {
    # 整数比较
    math::gt 1 0
    utest::assert $?

    math::gt 0 1
    utest::assert_fail $?

    math::gt 1 1
    utest::assert_fail $?

    # 浮点数比较
    math::gt 1.1 1.0
    utest::assert $?

    math::gt 1.11 1.1
    utest::assert $?

    math::gt 1.1 1.10
    utest::assert_fail $?

    # 负整数比较
    math::gt -1 -2
    utest::assert $?

    math::gt -1 -1
    utest::assert_fail $?

    math::gt -2 -1
    utest::assert_fail $?

    # 负浮点数比较
    math::gt -1.1 -1.2
    utest::assert $?

    math::gt -1.1 -1.1
    utest::assert_fail $?

    math::gt -1.1 -1.10
    utest::assert_fail $?

    math::gt -1.10 -1.1
    utest::assert_fail $?

    math::gt -1.2 -1.1
    utest::assert_fail $?
}

function TEST::math::lt() {
    # 整数比较
    math::lt 0 1
    utest::assert $?

    math::lt 1 0
    utest::assert_fail $?

    math::lt 1 1
    utest::assert_fail $?

    # 浮点数比较
    math::lt 1.0 1.1
    utest::assert $?

    math::lt 1.1 1.11
    utest::assert $?

    math::lt 1.1 1.10
    utest::assert_fail $?

    # 负整数比较
    math::lt -2 -1
    utest::assert $?

    math::lt -1 -1
    utest::assert_fail $?

    math::lt -1 -2
    utest::assert_fail $?

    # 负浮点数比较
    math::lt -1.2 -1.1
    utest::assert $?

    math::lt -1.1 -1.1
    utest::assert_fail $?

    math::lt -1.1 -1.10
    utest::assert_fail $?

    math::lt -1.1 -1.11
    utest::assert_fail $?

    math::lt -1.1 -1.2
    utest::assert_fail $?
}

function TEST::math::eq() {
    # 测试整数
    math::eq 0 0
    utest::assert $?

    math::eq 0 0.0
    utest::assert $?

    math::eq 1 1
    utest::assert $?

    math::eq 1 2
    utest::assert_fail $?

    # 测试正浮点数
    math::eq 1.0 1
    utest::assert $?

    math::eq 1.1 1.1
    utest::assert $?

    math::eq 1.1 1.10
    utest::assert $?

    math::eq 1.10 1.11
    utest::assert_fail $?

    # 测试负整数
    math::eq -1 -1
    utest::assert $?

    math::eq 0 -0
    utest::assert $?

    math::eq -1 -2
    utest::assert_fail $?

    # 测试负浮点数
    math::eq -1.1 -1.1
    utest::assert $?

    math::eq -1.1 -1.10
    utest::assert $?

    math::eq -1.10 -1.11
    utest::assert_fail $?
}

function TEST::math::ge() {
    # 整数比较
    math::ge 0 0
    utest::assert $?

    math::ge 1 0
    utest::assert $?

    math::ge 1 1
    utest::assert $?

    math::ge 0 1
    utest::assert_fail $?

    # 浮点数比较
    math::ge 0 0.0000
    utest::assert $?

    math::ge 1.1 1.0
    utest::assert $?

    math::ge 1.1 1.1
    utest::assert $?

    math::ge 1.0 1.1
    utest::assert_fail $?

    # 负整数比较
    math::ge 0 -1
    utest::assert $?

    math::ge -1 -2
    utest::assert $?

    math::ge -1 -1
    utest::assert $?

    math::ge -2 -1
    utest::assert_fail $?

    # 负浮点数比较
    math::ge 0.0 -0.000
    utest::assert $?

    math::ge -1.1 -1.2
    utest::assert $?

    math::ge -1.1 -1.1
    utest::assert $?

    math::ge -1.1 -1.10
    utest::assert $?

    math::ge -1.2 -1.1
    utest::assert_fail $?

}

function TEST::math::le() {
    # 整数比较
    math::le 0 0
    utest::assert $?

    math::le 0 1
    utest::assert $?

    math::le 1 1
    utest::assert $?

    math::le 1 0
    utest::assert_fail $?

    # 浮点数比较
    math::le 0 0.0000
    utest::assert $?

    math::le 1.0 1.1
    utest::assert $?

    math::le 1.1 1.1
    utest::assert $?

    math::le 1.1 1.0
    utest::assert_fail $?

    # 负整数比较
    math::le -1 0
    utest::assert $?

    math::le -2 -1
    utest::assert $?

    math::le -1 -1
    utest::assert $?

    math::le -1 -2
    utest::assert_fail $?

    # 负浮点数比较
    math::le 0.0 -0.000
    utest::assert $?

    math::le -1.2 -1.1
    utest::assert $?

    math::le -1.1 -1.1
    utest::assert $?

    math::le -1.10 -1.1
    utest::assert $?

    math::le -1.1 -1.2
    utest::assert_fail $?

}

function TEST::math::floor() {
    local res

    # 正数
    res="$(math::floor 0)"
    utest::assert_equal "$res" "0"

    res="$(math::floor 0.000)"
    utest::assert_equal "$res" "0"

    res="$(math::floor 0.5)"
    utest::assert_equal "$res" "0"

    res="$(math::floor 1.0000)"
    utest::assert_equal "$res" "1"

    res="$(math::floor 1.123)"
    utest::assert_equal "$res" "1"

    res="$(math::floor 1.5)"
    utest::assert_equal "$res" "1"

    res="$(math::floor 1.6)"
    utest::assert_equal "$res" "1"

    # 负数
    res="$(math::floor -0)"
    utest::assert_equal "$res" "0"

    res="$(math::floor -0.000)"
    utest::assert_equal "$res" "0"

    res="$(math::floor -0.5)"
    utest::assert_equal "$res" "-1"

    res="$(math::floor "-1.0000")"
    utest::assert_equal "$res" "-1"

    res="$(math::floor -1.123)"
    utest::assert_equal "$res" "-2"

    res="$(math::floor -1.5)"
    utest::assert_equal "$res" "-2"

    res="$(math::floor -1.6)"
    utest::assert_equal "$res" "-2"
}

function TEST::math::ceil() {
    local res

    # 正数
    res="$(math::ceil 0)"
    utest::assert_equal "$res" "0"

    res="$(math::ceil 0.000)"
    utest::assert_equal "$res" "0"

    res="$(math::ceil 0.5)"
    utest::assert_equal "$res" "1"

    res="$(math::ceil 1.0000)"
    utest::assert_equal "$res" "1"

    res="$(math::ceil 1.123)"
    utest::assert_equal "$res" "2"

    res="$(math::ceil 1.5)"
    utest::assert_equal "$res" "2"

    res="$(math::ceil 1.6)"
    utest::assert_equal "$res" "2"

    # 负数
    res="$(math::ceil -0)"
    utest::assert_equal "$res" "0"

    res="$(math::ceil -0.000)"
    utest::assert_equal "$res" "0"

    res="$(math::ceil -0.5)"
    utest::assert_equal "$res" "0"

    res="$(math::ceil -1.0000)"
    utest::assert_equal "$res" "-1"

    res="$(math::ceil -1.123)"
    utest::assert_equal "$res" "-1"

    res="$(math::ceil -1.5)"
    utest::assert_equal "$res" "-1"

    res="$(math::ceil -1.6)"
    utest::assert_equal "$res" "-1"
}

function TEST::math::round() {
    local res

    # 浮点数需要注意精度的问题
    res="$(math::round 0.499999)"
    utest::assert_equal "$res" "0"

    res="$(math::round 0.4999999)"
    utest::assert_equal "$res" "1"

    # 正整数
    res="$(math::round 0)"
    utest::assert_equal "$res" "0"

    res="$(math::round 3)"
    utest::assert_equal "$res" "3"

    # 正浮点数
    res="$(math::round 0.000)"
    utest::assert_equal "$res" "0"

    res="$(math::round 0.499)"
    utest::assert_equal "$res" "0"

    res="$(math::round 0.5)"
    utest::assert_equal "$res" "1"

    res="$(math::round 0.99999999999999)"
    utest::assert_equal "$res" "1"

    # 负整数
    res="$(math::round -0)"
    utest::assert_equal "$res" "0"

    res="$(math::round -3)"
    utest::assert_equal "$res" "-3"

    # 负浮点数
    res="$(math::round -0.000)"
    utest::assert_equal "$res" "0"

    res="$(math::round -0.4999999999999)"
    utest::assert_equal "$res" "0"

    res="$(math::round -0.5)"
    utest::assert_equal "$res" "0"

    res="$(math::round -0.5000000000001)"
    utest::assert_equal "$res" "-1"

    res="$(math::round -0.9999999999999)"
    utest::assert_equal "$res" "-1"
}

function TEST::math::add() {
    utest::assert_equal "$(math::add 1 2)" "3"
    utest::assert_equal "$(math::add 1 1.2222 2)" "2.22"
    utest::assert_equal "$(math::add -3 4.567)" "1.567"
    utest::assert_equal "$(math::add -6 -2.01)" "-8.01"
}

function TEST::math::sub() {
    utest::assert_equal "$(math::sub 1 2)" "-1"
    utest::assert_equal "$(math::sub 1 1.2222 2)" "-0.22"
    utest::assert_equal "$(math::sub -3 4.567)" "-7.567"
    utest::assert_equal "$(math::sub -6 -2.01)" "-3.99"
}

function TEST::math::mul() {
    utest::assert_equal "$(math::mul 2 0)" "0"
    utest::assert_equal "$(math::mul 1 2)" "2"
    utest::assert_equal "$(math::mul 2 1.2222 2)" "2.44"
    utest::assert_equal "$(math::mul -3 3.33)" "-9.99"
    utest::assert_equal "$(math::mul -1 3.449 2)" "-3.45"
    utest::assert_equal "$(math::mul -3 3.333 2)" "-10.00"
    utest::assert_equal "$(math::mul -3 3.333)" "-9.999"
    utest::assert_equal "$(math::mul -6 -2.01)" "12.06"
}

function TEST::math::div() {
    utest::assert_equal "$(math::div 1 2 2)" "0.50"
    utest::assert_equal "$(math::div 1 3 2)" "0.33"
    utest::assert_equal "$(math::div 1 3 3)" "0.333"
    utest::assert_equal "$(math::div 6 2 2)" "3.00"

    utest::assert_equal "$(math::div 1.5 2)" "0.75"
    utest::assert_equal "$(math::div 1.5 2.0)" "0.75"
    utest::assert_equal "$(math::div 1.5 2.2 2)" "0.68"
    utest::assert_equal "$(math::div 1.5 2.6 2)" "0.58"
    utest::assert_equal "$(math::div 1.5 "$((2 * 3))")" "0.25"
}
