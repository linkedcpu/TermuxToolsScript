#!/data/data/com.termux/files/usr/bin/bash
########################################
readonly SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
########################################
readonly setPS1="$SCRIPT_DIR/setPS1.sh"
readonly setTermuxProp="$SCRIPT_DIR/setTermuxProp.sh"
readonly changeTermuxRepo="$SCRIPT_DIR/changeTermuxRepo.sh"
########################################
main() {
    echo "欢迎使用初始化脚本"
    ehco "正在换源中..."
    bash "$changeTermuxRepo"
    ehco "设置PS1中..."
    bash "$setPS1"
    ehco "设置termux.prop中..."
    bash "$setTermuxProp"
}
########################################

main
