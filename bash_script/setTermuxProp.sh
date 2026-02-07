#!/data/data/com.termux/files/usr/bin/bash

setTermuxProp() {
    [ -z "$TERMUX_VERSION" ] && { echo "请在 Termux 中运行此脚本"; return 1; }
########################################
    local -r PROP_FILE="$HOME/.termux/termux.properties"
    local -r name="${FUNCNAME[0]}"
    local -r BLOCK_MARKER="# ====== 由 $name 自动生成 ======"
    local -r BLOCK_END="# ====== 由 $name 配置结束 ======"
    local blockFlag=false
    local -r tmp=$(mktemp "${PROP_FILE}.XXX")
    trap 'rm -f "$tmp"' EXIT
    local -r keys=(
        extra-keys extra-keys-text-all-caps allow-external-apps
        soft-keyboard-toggle-behaviour shortcut.create-session
        shortcut.next-session shortcut.previous-session shortcut.rename-session
    )
########################################
    backup_termux_prop() {
        [[ -f "$PROP_FILE" ]] || return
        [[ ! -f "${PROP_FILE}_default.bak" ]] && cp "$PROP_FILE" "${PROP_FILE}_default.bak"
        # cp "$PROP_FILE" "${PROP_FILE}_$(date +"%Y%m%d_%H%M%S").bak"
    }
########################################
    generate_extra_keys() {
        local keys=(
"ESC" "ESC" "CTRL t" "CTRL t"
"Ctrl" "CTRL" "CTRL 1" "CTRL 1"
"shift" "SHIFT" "CTRL 2" "CTRL 2"
"Alt" "ALT" "CTRL n" "CTRL n"
"\$()" "ALT b \$( ALT f )" "\${}" "ALT b \${ ALT f }"
"句⌫" "CTRL u" "⌦句" "CTRL k"
"AltB" "ALT b" "CtrlW" "CTRL w"
"AltF" "ALT f" "AltD" "ALT d"
"⌦行" "CTRL e CTRL u" "清屏" "CTRL l"
"编辑" "CTRL x CTRL e" "nano保" "CTRL xy ENTER"
"撤销" "CTRL _" "CtrlY" "CTRL y"
"⌨" " KEYBOARD" "💣" "CTRL d"
"TAB" "TAB" "!!" "!! ENTER"
"cd~" "cd SPACE ~ SPACE ENTER" "cd -" "cd SPACE - SPACE ENTER"
"进程" "ps SPACE aux SPACE ENTER" "进程筛" "ps SPACE aux SPACE | SPACE grep SPACE "
"find" "CTRL a find SPACE CTRL e SPACE -type SPACE " "ALT ." "ALT ."
"大写" "ALT b ALT u" "小写" "ALT b ALT l"
"⬅" "LEFT" "行首" "HOME"
"⬇" "DOWN" "下页" "PGDN"
"⬆" "UP" "上页" "PGUP"
"➡" "RIGHT" "行尾" "END"
"历史" "history ENTER" "搜历史" "CTRL r"
"列表" "ls SPACE ENTER" "详列表" "ls SPACE -la SPACE ENTER"
"⏎" "ENTER" "xfce4" "termux-x11 SPACE :1 SPACE -xstartup SPACE \"dbus-launch SPACE --exit-with-session SPACE xfce4-session\" & SPACE ENTER" 
        )
        local config=() rows=2 cols=12
        for ((r=0; r<rows; r++)); do
            local row_items=()
            for ((c=0; c<cols; c++)); do
                local i=$(( (c + cols * r) * 4))
                if (( i+3 < ${#keys[@]} )); then
                    row_items+=("{display:'${keys[i]}',macro:'${keys[i+1]}',popup:{display:'${keys[i+2]}',macro:'${keys[i+3]}'}}")
                else
                    row_items+=("{display:'',macro:'',popup:{display:'',macro:''}}")
                fi
            done
            config+=("[$(IFS=,; echo "${row_items[*]}")]")
        done
        echo "extra-keys = [$(IFS=,; echo "${config[*]}")]"
    }
########################################
    generate_config() {
        cat << EOF
$BLOCK_MARKER
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')

$(generate_extra_keys)
extra-keys-text-all-caps = false
allow-external-apps = true
soft-keyboard-toggle-behaviour = enable/disable
shortcut.create-session = ctrl + t
shortcut.next-session = ctrl + 2
shortcut.previous-session = ctrl + 1
shortcut.rename-session = ctrl + n

$BLOCK_END
EOF
    }
########################################
    mkdir -p "$HOME/.termux"
    backup_termux_prop
    [[ -f "$PROP_FILE" ]] && while IFS= read -r line; do
        if [[ "$line" == "$BLOCK_MARKER" ]]; then
            blockFlag=true
            continue
        elif [[ "$blockFlag" == true && "$line" == "$BLOCK_END" ]]; then
            blockFlag=false
            continue
        elif [[ "$blockFlag" == true ]]; then
            continue
        fi
        for k in "${keys[@]}"; do
            [[ "$line" =~ ^[[:space:]]*"$k"[[:space:]]*= ]] && continue 2
        done
        echo "$line"
    done < "$PROP_FILE" > "$tmp"
    generate_config >> "$tmp"
    mv "$tmp" "$PROP_FILE" || { echo "❌ 移动文件失败"; return 1; }
    termux-reload-settings || { echo "❌ 重载设置失败，请手动执行: termux-reload-settings"; return 1; }
    echo -e "\033[1;32m✓ $(basename $PROP_FILE)已更新\033[0m
\033[2m✓ 位置: $PROP_FILE
✓ 大小: $(wc -l < "$PROP_FILE") 行\033[0m"
}

# 如果脚本直接运行，则执行函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setTermuxProp "$@"
fi
