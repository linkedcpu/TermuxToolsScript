#!/data/data/com.termux/files/usr/bin/bash
changeTrmuxRepo() {
    local -r TARGET_DOMAIN="mirrors.tuna.tsinghua.edu.cn"
    local -r MIRROR_PATH="${PREFIX}/etc/termux/mirrors/chinese_mainland/${TARGET_DOMAIN}"
    [ -f "$MIRROR_PATH" ] || { echo -e "\033[1;31mpath不存在:$MIRROR_PATH\033[0m";exit 1; }
    local -r CHOSEN_MIRROR_LINK="${PREFIX}/etc/termux/chosen_mirrors"
    [ -L ${CHOSEN_MIRROR_LINK} ] && { echo -e "\033[1;33m移除软链接: ${CHOSEN_MIRROR_LINK}\033[0m";
         unlink ${CHOSEN_MIRROR_LINK}; }
    echo -e "\033[1;32m更新软链接: $(ln -sv ${MIRROR_PATH} ${CHOSEN_MIRROR_LINK})\033[0m"
    pkg --check-mirror update
}
########################################
main() {
    changeTrmuxRepo
    yes|pkg up
    changeTrmuxRepo
    echo -e "\033[1;32mtermux镜像源更新成功\033[0m"
}
########################################
main "$@"