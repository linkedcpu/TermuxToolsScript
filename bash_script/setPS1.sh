#!/data/data/com.termux/files/usr/bin/bash

setPS1() {
    [ -z "$TERMUX_VERSION" ] && { echo "请在 Termux 中运行此脚本"; exit 1; }
########################################
    local -r BASHRC_FILE="${PREFIX}/etc/bash.bashrc"
    local -r funcName="${FUNCNAME[0]}"
    local -r BLOCK_MARKER="# ====== 由 $funcName 自动生成 ======"
    local -r BLOCK_END="# ====== 由 $funcName 配置结束 ======"
    local blockFlag=false
    local -r temp_file=$(mktemp "${BASHRC_FILE}.XXX")
    trap 'rm -rf "$temp_file"' EXIT
########################################
    local -r blue='\[\e[0;34m\]'
    local -r blueB='\[\e[1;34m\]'
    local -r blueI='\[\e[3;34m\]'
    local -r cyanI='\[\e[3;1;36m\]'
    local -r greenB='\[\e[1;32m\]'
    local -r greyB='\[\e[1;30m\]'
    local -r redB='\[\e[1;31m\]'
    local -r yellow='\[\e[1;33m\]'
    local -r magenta='\[\e[1;35m\]'
    local -r end='\[\e[0m\]'
    local -r user=" ${greenB}\u${end}${greyB}@${end}${cyanI}\h${end} "
    local -r date="${yellow}\$(date +\"%Y年%m月%d日%H时%M分%S秒\")${end}"
    local -r isOk="\$([ \$? == 0 ] && echo \"${greenB}ok\" || echo \"${redB}error\")"
    local -r isRoot="\$([ \$UID -eq 0 ] && echo \"\[\e[1;31m\]\\\$\[\e[0m\]\" || echo \"\[\e[1;32m\]\\\$\[\e[0m\]\")"
    local -r cwd="${magenta} \${PWD} ${end}"
    local -r isGitBranch='$(git branch 2>/dev/null | sed -e '/^[^*]/d' -e "s/*\\\(.*\\\)/\[\e[0;34m\][\[\e[1;33m\]🐙\1 \[\e[0;34m\]]-/")'
########################################
    [[ -f "${BASHRC_FILE}" ]] && [[ ! -f "${BASHRC_FILE}.bak" ]] && cp "${BASHRC_FILE}"{,.bak}
    while IFS= read -r line; do
        if [[ "$line" == "$BLOCK_MARKER" ]]; then
            blockFlag=true
            continue
        elif [[ "$blockFlag" == true && "$line" == "$BLOCK_END" ]]; then
            blockFlag=false
            continue
        elif [[ "$blockFlag" == true ]]; then
            continue
        fi
        if [[ "$line" =~ ^[[:space:]]*export[[:space:]]+(PS1|LANG|VISUAL|EDITOR)=.* ]] || [[ "$line" =~ ^[[:space:]]*bind[[:space:]].*menu-complete.* ]];
        then
            continue
        fi
        echo "$line"  
    done < "$BASHRC_FILE" >"$temp_file"
    cat >> "$temp_file" << EOF
$BLOCK_MARKER
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')

export PS1='${blue}┏[${end}${isOk}${blue}]-[${end}${user}${blue}]-[${end}${date}${blue}]\n┣[${end}${cwd}${blue}]\n${blue}┗${end}${isGitBranch}${blue}[${end}${isRoot}${blue}]${end} '
export LANG="zh_CN.UTF-8"
export VISUAL="nano"
export EDITOR="nano"
# 只在交互式 shell 中启用 bind
if [[ \$- == *i* ]] && [ -n "\$PS1" ]; then
    bind '"\t":menu-complete'
fi

$BLOCK_END
EOF
    mv "$temp_file" "$BASHRC_FILE"
    echo -e "\033[1;32m✓ $(basename $BASHRC_FILE)已更新\033[0m
\033[2m✓ 位置: $BASHRC_FILE
✓ 大小: $(wc -l < "$BASHRC_FILE") 行\033[0m"
}

setPS1
