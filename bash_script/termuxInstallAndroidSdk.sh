#!/data/data/com.termux/files/usr/bin/bash
termuxInstallSdk() {
    # 核心路径配置
    local -r SDK_PATH="$HOME/android-sdk"
    local -r SDKMANAGER_PATH="$SDK_PATH/cmdline-tools/latest/bin/sdkmanager"
    local -r BACKUP_DIR="/storage/EFFC-5853/Android_Home/backup/termux_backup"
    local -r LOG_FILE="$HOME/.android_sdk_install.log"
    
    ########################################
    # 工具函数
    ########################################
    log_message() {
        local msg="$1"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $msg" | tee -a "$LOG_FILE" 2>/dev/null
    }
    
    ########################################
    configure_env() {
        local bashrc="$HOME/.bashrc"
        local block_start="# Android SDK配置开始"
        local block_end="# Android SDK配置结束"
        
        # 清理旧配置
        if [ -f "$bashrc" ]; then
            sed -i "/$block_start/,/$block_end/d" "$bashrc" 2>/dev/null
        else
            touch "$bashrc"
        fi
        
        # 写入新配置
        cat >> "$bashrc" << EOF
$block_start
export ANDROID_HOME="$SDK_PATH"
export ANDROID_SDK_ROOT="$SDK_PATH"
export PATH="\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools"
$block_end
EOF
        
        log_message "✅ 环境变量已配置"
    }
    
    ########################################
    # 检查下载文件的完整性
    ########################################
    check_zip_integrity() {
        local zip_file="$1"
        if [ ! -f "$zip_file" ]; then
            return 1
        fi
        
        # 尝试解压测试
        unzip -tq "$zip_file" >/dev/null 2>&1
        return $?
    }
    
    ########################################
    # 下载SDK
    ########################################
    download_sdk() {
        local zip_path="$1"
        local download_url="$2"
        local retry_count=3
        local retry_delay=5
        
        for i in $(seq 1 $retry_count); do
            log_message "📥 下载SDK (尝试 $i/$retry_count)..."
            
            if curl -L -C- -o "$zip_path" "$download_url" --progress-bar; then
                if check_zip_integrity "$zip_path"; then
                    log_message "✅ 下载完成且文件完整"
                    return 0
                else
                    log_message "⚠ 下载的文件损坏，重新下载..."
                    rm -f "$zip_path"
                fi
            else
                log_message "❌ 下载失败，等待 ${retry_delay}秒后重试..."
                sleep $retry_delay
            fi
        done
        
        return 1
    }
    
    ########################################
    # 从备份恢复
    ########################################
    restore_from_backup() {
        local backup_path="$1"
        local zip_path="$2"
        
        if [ -f "$backup_path" ] && check_zip_integrity "$backup_path"; then
            log_message "🔄 从备份恢复..."
            if cp "$backup_path" "$zip_path"; then
                log_message "✅ 备份恢复成功"
                return 0
            else
                log_message "❌ 备份恢复失败"
            fi
        fi
        
        return 1
    }
    
    ########################################
    # 备份SDK文件
    ########################################
    backup_sdk() {
        local zip_path="$1"
        
        if [ ! -f "$zip_path" ] || [ ! -s "$zip_path" ]; then
            return 1
        fi
        
        mkdir -p "$BACKUP_DIR" 2>/dev/null
        if [ -w "$BACKUP_DIR" ]; then
            if cp "$zip_path" "$BACKUP_DIR/"; then
                log_message "✅ SDK已备份到: $BACKUP_DIR"
                return 0
            else
                log_message "⚠ 备份失败 (权限不足或空间不够)"
            fi
        else
            log_message "⚠ 备份目录不可写: $BACKUP_DIR"
        fi
        
        return 1
    }
    
    ########################################
    # 安装SDK核心函数
    ########################################
    install_sdk() {
        local zip_file="commandlinetools-linux-11076708_latest.zip"
        local zip_path="$SDK_PATH/$zip_file"
        local download_url="https://dl.google.com/android/repository/$zip_file"
        local temp_dir
        
        # 检查是否已安装
        if [ -f "$SDKMANAGER_PATH" ]; then
            log_message "✅ SDK 已安装 ($SDKMANAGER_PATH)"
            return 0
        fi
        
        # 创建目录
        if ! mkdir -p "$SDK_PATH"; then
            log_message "❌ 无法创建SDK目录: $SDK_PATH"
            return 1
        fi
        
        # 检查备份
        local backup_path="$BACKUP_DIR/$zip_file"
        if ! restore_from_backup "$backup_path" "$zip_path"; then
            # 备份恢复失败，重新下载
            if ! download_sdk "$zip_path" "$download_url"; then
                log_message "❌ SDK下载失败，请检查网络连接"
                return 1
            fi
            
            # 备份新下载的文件
            backup_sdk "$zip_path"
        fi
        
        # 解压
        log_message "📦 解压文件..."
        
        # 清理旧目录
        rm -rf "$SDK_PATH/cmdline-tools" 2>/dev/null
        
        # 创建临时目录
        temp_dir=$(mktemp -d 2>/dev/null || echo "/tmp/android_sdk_$(date +%s)")
        if [ ! -d "$temp_dir" ]; then
            log_message "❌ 无法创建临时目录"
            return 1
        fi
        
        # 解压到临时目录
        if ! unzip -o "$zip_path" -d "$temp_dir" >/dev/null 2>&1; then
            log_message "❌ 解压失败，文件可能已损坏"
            rm -rf "$temp_dir" 2>/dev/null
            return 1
        fi
        
        # 处理不同的目录结构
        local moved_successfully=0
        
        if [ -d "$temp_dir/cmdline-tools" ]; then
            # 标准结构：ZIP包含cmdline-tools目录
            if mkdir -p "$SDK_PATH/cmdline-tools" 2>/dev/null && \
               mv "$temp_dir/cmdline-tools" "$SDK_PATH/cmdline-tools/latest" 2>/dev/null; then
                moved_successfully=1
                log_message "📁 检测到标准目录结构"
            fi
        elif [ -f "$temp_dir/bin/sdkmanager" ]; then
            # 直接解压的结构：ZIP内容在根目录
            if mkdir -p "$SDK_PATH/cmdline-tools/latest" 2>/dev/null && \
               mv "$temp_dir"/* "$SDK_PATH/cmdline-tools/latest/" 2>/dev/null; then
                moved_successfully=1
                log_message "📁 检测到扁平目录结构"
            fi
        else
            log_message "❌ 解压失败：未知的目录结构"
            log_message "临时目录内容:"
            ls -la "$temp_dir" 2>/dev/null >> "$LOG_FILE"
        fi
        
        # 清理临时目录
        rm -rf "$temp_dir" 2>/dev/null
        
        if [ $moved_successfully -eq 0 ]; then
            log_message "❌ 文件移动失败"
            return 1
        fi
        
        # 清理ZIP文件
        rm -f "$zip_path" 2>/dev/null
        
        # 验证安装
        if [ -f "$SDKMANAGER_PATH" ]; then
            chmod +x "$SDKMANAGER_PATH" 2>/dev/null
            chmod +x "$SDK_PATH/cmdline-tools/latest/bin/"* 2>/dev/null
            
            # 测试sdkmanager是否可以运行
            if "$SDKMANAGER_PATH" --version >/dev/null 2>&1; then
                log_message "✅ SDK 安装完成并验证通过"
                
                # 安装必要的包
                log_message "📦 正在安装必要的Android平台工具..."
                "$SDKMANAGER_PATH" "platform-tools" "platforms;android-34" "build-tools;34.0.0" \
                    --sdk_root="$SDK_PATH" >/dev/null 2>&1 &
                log_message "🚀 后台安装平台工具中..."
                
                return 0
            else
                log_message "⚠ SDK 已安装但验证失败"
                return 1
            fi
        fi
        
        log_message "❌ 安装失败：未找到 sdkmanager"
        log_message "当前目录结构:"
        find "$SDK_PATH" -type f 2>/dev/null | head -20 >> "$LOG_FILE"
        return 1
    }
    
    ########################################
    # 主执行流程
    ########################################
    
    log_message "🔧 开始安装Android SDK..."
    log_message "SDK路径: $SDK_PATH"
    log_message "备份路径: $BACKUP_DIR"
    
    # 初始化日志
    echo "=== Android SDK 安装日志 $(date '+%Y-%m-%d %H:%M:%S') ===" > "$LOG_FILE"
    
    # 安装核心步骤
    if configure_env && install_sdk; then
        log_message "🎉 Android SDK 安装完成！"
        log_message "请执行以下命令使环境变量生效:"
        echo "    source ~/.bashrc"
        echo ""
        log_message "或重新启动Termux会话"
        
        # 显示安装位置
        echo ""
        echo "安装位置: $SDK_PATH"
        echo "sdkmanager: $SDKMANAGER_PATH"
        echo "日志文件: $LOG_FILE"
        
        return 0
    else
        log_message "❌ Android SDK 安装失败"
        echo ""
        echo "请检查日志文件: $LOG_FILE"
        echo "常见问题:"
        echo "1. 网络连接问题"
        echo "2. 存储空间不足"
        echo "3. 备份文件损坏"
        
        return 1
    fi
}

########################################
# 执行函数
########################################
termuxInstallSdk
