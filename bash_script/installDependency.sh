#!/data/data/com.termux/files/usr/bin/bash
readonly JNI_PACKAGES=(clang make openjdk-17 ndk-sysroot libandroid-support cmake pkg-config binutils)
########################################
installDependency() {
    local missing_packages=()
    local packages_array=("$@")
    ########################################
    for pkg in "${packages_array[@]}"; do
        if dpkg -s "$pkg" &> /dev/null; then
            echo -e "\033[1;32m✓ 已安装: $pkg\033[0m"
        else 
            echo -e "\033[1;33m✗ 未安装: $pkg\033[0m"
            missing_packages+=("$pkg")
        fi
    done
    if [ "${#missing_packages[@]}" -gt 0 ]; then
        echo -e "\033[1;34m需要安装: ${missing_packages[*]}\033[0m"
        echo -e "\033[1;36m开始安装...\033[0m"
        if pkg i "${missing_packages[@]}"; then
            echo -e "\033[1;32m✓ 安装成功！\033[0m"
            return 0
        else
            echo -e "\033[1;31m✗ 安装失败！\033[0m"
            return 1
        fi
    fi
}
########################################
installDependency "$@"

