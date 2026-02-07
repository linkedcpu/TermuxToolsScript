#!/data/data/com.termux/files/usr/bin/bash
readonly  SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
########################################
source "$SCRIPT_DIR/logging.sh"
########################################
readonly setPS1="$SCRIPT_DIR/setPS1.sh"
readonly setTermuxProp="$SCRIPT_DIR/setTermuxProp.sh"
readonly changeTermuxRepo="$SCRIPT_DIR/changeTermuxRepo.sh"
########################################
readonly JNI_PACKAGES=(clang make openjdk-17 ndk-sysroot libandroid-support cmake pkg-config binutils)
readonly CUSTOM_PACKAGES=(tsu git ffmpeg)
########################################
main() {
log "欢迎使用初始化脚本"
log s "正在换源中..."
bash "$changeTermuxRepo"
log s "设置PS1中..."
bash "$setPS1"
log s "设置termux.prop中..."
bash "$setTermuxProp"
}
########################################

main
