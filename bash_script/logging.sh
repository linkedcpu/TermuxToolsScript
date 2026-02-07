#!/bin/bash

# ============================================================================
# 日志系统模块
# ============================================================================

# 防止重复加载
[[ -n "${LOGGER_LOADED}" ]] && return
readonly LOGGER_LOADED=1

# ----------------------------------------------------------------------------
# 核心日志函数
# ----------------------------------------------------------------------------
log() {
    # 定义消息类型
    local -r types=("DEBUG" "INFO" "WARN" "ERROR" "FATAL" "STEP" "QUESTION" "SUCCESS" "FAILURE")
    
    # 定义表情符号
    local -rA symbols=(
        ["DEBUG"]="🐛"
        ["INFO"]="ℹ"
        ["WARN"]="⚠"
        ["ERROR"]="✗"
        ["FATAL"]="💀"
        ["STEP"]="➤"
        ["QUESTION"]="?"
        ["SUCCESS"]="✅"
        ["FAILURE"]="❌"
    )
    
    # 定义颜色
    local -rA colors=(
        ["DEBUG"]="\033[90;1m"
        ["INFO"]="\033[36;1m"
        ["WARN"]="\033[33;1m"
        ["ERROR"]="\033[31;1m"
        ["FATAL"]="\033[35;1m"
        ["STEP"]="\033[34;1m"
        ["QUESTION"]="\033[1m"
        ["SUCCESS"]="\033[32;1m"
        ["FAILURE"]="\033[31;1m"
    )
    local -r reset="\033[0m"
    
    # 单字母缩写映射
    local -rA shortcuts=(
        ["d"]="DEBUG"
        ["i"]="INFO"
        ["w"]="WARN"
        ["e"]="ERROR"
        ["f"]="FATAL"
        ["s"]="STEP"
        ["q"]="QUESTION"
        ["u"]="SUCCESS"
        ["x"]="FAILURE"
    )
    
    # 参数处理
    local level="INFO"
    local msg=""
    
    if [[ $# -eq 1 ]]; then
        msg="$1"
    elif [[ $# -eq 2 ]]; then
        level="$1"
        msg="$2"
    else
        echo -e "\033[31m❌ 错误: log函数需要1-2个参数\033[0m" >&2
        return 1
    fi
    
    # 解析级别
    local level_upper="${level^^}"
    local resolved_level="INFO"
    
    # 数字索引
    if [[ "$level" =~ ^[0-9]$ ]]; then
        [[ $level -lt ${#types[@]} ]] && resolved_level="${types[$level]}"
    
    # 单字母
    elif [[ ${#level} -eq 1 && -n "${shortcuts[${level,,}]}" ]]; then
        resolved_level="${shortcuts[${level,,}]}"
    
    # 类型名
    elif [[ -n "${symbols[$level_upper]}" ]]; then
        resolved_level="$level_upper"
    fi
    
    # 获取颜色和符号
    local color="${colors[$resolved_level]:-$reset}"
    local symbol="${symbols[$resolved_level]:-📄}"
    
    # 输出日志
    echo -e "${color}${symbol} ${msg}${reset}"
}

# ----------------------------------------------------------------------------
# 快捷函数
# ----------------------------------------------------------------------------
debug()   { log "d" "$*"; }
info()    { log "i" "$*"; }
warn()    { log "w" "$*"; }
error()   { log "e" "$*"; }
fatal()   { log "f" "$*"; }
step()    { log "s" "$*"; }
question(){ log "q" "$*"; }
success() { log "u" "$*"; }
failure() { log "x" "$*"; }

# ----------------------------------------------------------------------------
# 测试函数
# ----------------------------------------------------------------------------
_log_test() {
    echo "=== 单参数测试 ==="
    log "这是一个简单的消息"
    
    echo -e "\n=== 数字索引测试 ==="
    for i in {0..8}; do
        log "$i" "这是数字索引 $i 的消息"
    done
    
    echo -e "\n=== 单字母测试 ==="
    for c in d i w e f s q u x; do
        log "$c" "这是单字母 $c 的消息"
    done
    
    echo -e "\n=== 完整类型名测试 ==="
    log "debug" "调试消息"
    log "INFO" "信息消息"
    log "WARN" "警告消息"
    log "ERROR" "错误消息"
    log "SUCCESS" "成功消息"
    
    echo -e "\n=== 快捷函数测试 ==="
    debug "调试消息"
    info "信息消息"
    warn "警告消息"
    error "错误消息"
    success "成功消息"
    failure "失败消息"
}

# ----------------------------------------------------------------------------
# 帮助信息
# ----------------------------------------------------------------------------
_log_help() {
    cat <<EOF
日志系统使用说明:

基本用法:
  log <消息>                # 单参数，使用INFO类型
  log <类型> <消息>         # 双参数，指定类型

类型指定方式:
  数字: 0-8
    0: DEBUG    1: INFO     2: WARN
    3: ERROR    4: FATAL    5: STEP
    6: QUESTION 7: SUCCESS  8: FAILURE
  
  单字母: d i w e f s q u x
    d: DEBUG    i: INFO     w: WARN
    e: ERROR    f: FATAL    s: STEP
    q: QUESTION u: SUCCESS  x: FAILURE
  
  类型名: DEBUG INFO WARN ERROR FATAL STEP QUESTION SUCCESS FAILURE

快捷函数:
  debug "消息"     info "消息"     warn "消息"
  error "消息"     fatal "消息"    step "消息"
  question "消息"  success "消息"  failure "消息"

示例:
  log "操作开始"
  log 0 "调试信息"
  log "e" "错误发生"
  log "ERROR" "严重错误"
  error "文件不存在"
  success "操作完成"
EOF
}

# ----------------------------------------------------------------------------
# 主程序
# ----------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        "--test"|"-t")
            _log_test
            ;;
        "--help"|"-h")
            _log_help
            ;;
        *)
            echo "=== 快速测试 ==="
            log "欢迎使用日志系统"
            log 0 "调试消息"
            log 1 "信息消息"
            log 2 "警告消息"
            log 3 "错误消息"
            log "d" "单字母调试"
            log "i" "单字母信息"
            log "e" "单字母错误"
            echo ""
            echo "更多选项:"
            echo "  $0 --test    运行完整测试"
            echo "  $0 --help    显示帮助"
            ;;
    esac
fi
