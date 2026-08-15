#!/data/data/com.termux/files/usr/bin/bash
########################################
readonly SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
########################################
readonly setPS1="$SCRIPT_DIR/setPS1.sh"
readonly setTermuxProp="$SCRIPT_DIR/setTermuxProp.sh"
readonly changeTermuxRepo="$SCRIPT_DIR/changeTermuxRepo.sh"
readonly setNvimConfig="$SCRIPT_DIR/setNvimConfig.sh"
readonly setAndroidSdk="$SCRIPT_DIR/setAndroidSdk.sh"
########################################
main() {
    echo "欢迎使用初始化脚本"
    echo "正在换源中..."
    bash "$changeTermuxRepo"
    echo "设置PS1中..."
    bash "$setPS1"
    echo "设置termux.prop中..."
    bash "$setTermuxProp"
    echo "设置nvim配置中..."
    bash "$setNvimConfig"
    echo "设置AndroidSdk中..."
    bash "$setAndroidSdk"
    
}
########################################

main
