#!/usr/bin/env bash

setBashrc() {
    [ -z "$TERMUX_VERSION" ] && { 
        echo "请在 Termux 中运行此脚本" >&2
        exit 1
    }
    ########################################
    local -r BASHRC_FILE="${HOME}/.bashrc"
    local -r BASHRC_BACKUP="${BASHRC_FILE}.bak"
    ########################################
    local -r FUNC_NAME="${FUNCNAME[0]}"
    local -r BLOCK_START="# ====== 由 ${FUNC_NAME} 自动生成 ======"
    local -r BLOCK_END="# ====== 由 ${FUNC_NAME} 配置结束 ======"
    local is_in_block=false
    ########################################
    local -r FILTERED_VARS="JAVA_HOME|ANDROID_HOME|ANDROID_NDK_HOME|{PATH"
    ########################################
    local -r TEMP_FILE=$(mktemp "${BASHRC_FILE}.XXXXXXXXXX")
    trap 'rm -f "$TEMP_FILE"' EXIT INT TERM
    ########################################
    if [[ -f "$BASHRC_FILE" ]] && [[ ! -f "$BASHRC_BACKUP" ]]; then
        cp "$BASHRC_FILE" "$BASHRC_BACKUP"
        echo "已创建备份: $BASHRC_BACKUP" >&2
    fi
    ########################################
    while IFS= read -r line; do
        if [[ "$line" == "$BLOCK_START" ]]; then
            is_in_block=true
            continue
        elif [[ "$is_in_block" == true && "$line" == "$BLOCK_END" ]]; then
            is_in_block=false
            continue
        elif [[ "$is_in_block" == true ]]; then
            continue
        fi
        
        if [[ "$line" =~ ^[[:space:]]*(export[[:space:]]+)?($FILTERED_VARS)= ]]; then
            continue
        fi
        
        echo "$line"
    done < "$BASHRC_FILE" > "$TEMP_FILE"
    ########################################
    if [[ $# -gt 0 ]]; then
        local new_content=""
        printf -v new_content '%s\n' "$@"
        new_content="${new_content%$'\n'}"  
    fi
    cat >> "$TEMP_FILE" << EOF
${BLOCK_START}
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# 脚本名称: ${FUNC_NAME}

${new_content}

${BLOCK_END}
EOF
    ########################################
    if ! mv "$TEMP_FILE" "$BASHRC_FILE"; then
        echo "错误: 无法更新 $BASHRC_FILE" >&2
        return 1
    fi
    ########################################
    local -i line_count
    line_count=$(wc -l < "$BASHRC_FILE" 2>/dev/null || echo 0)
    echo -e "\033[1;32m✓ $(basename "$BASHRC_FILE") 已更新\033[0m
\033[2m位置: $BASHRC_FILE
行数: "${line_count}"
备份: ${BASHRC_BACKUP}\033[0m"
}
########################################
t1="export JAVA_HOME=\$PREFIX/lib/jvm/java-17-openjdk
export ANDROID_HOME=\$PREFIX/share/android-sdk
export ANDROID_NDK_HOME=\$PREFIX/share/android-ndk
export PATH=\$PATH:\$ANDROID_HOME/tools/bin:\$ANDROID_HOME/platform-tools:\$JAVA_HOME\bin"


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setBashrc "$@" "$t1"
fi
