#!/bin/bash
set -e

########################################
# 1. 环境标记（只定义一次）
########################################
ENV_START='# ===== TERMUX_ANDROID_ENV_START ====='
ENV_END='# ===== TERMUX_ANDROID_ENV_END ====='
BASHRC="$HOME/.bashrc"

########################################
# 2. 确保 .bashrc 存在（关键修复）
########################################
[[ -f "$BASHRC" ]] || touch "$BASHRC"

########################################
# 3. 删除旧配置块
########################################
sed -i "/$ENV_START/,/$ENV_END/d" "$BASHRC"

########################################
# 4. 写入最新配置块
########################################
cat <<EOF >> "$BASHRC"

$ENV_START
export JAVA_HOME=\$PREFIX/lib/jvm/java-21-openjdk
export ANDROID_HOME=\$HOME/android-sdk
export PATH=\$JAVA_HOME/bin:\$ANDROID_HOME/cmdline-tools/latest/bin:\$PATH
$ENV_END
EOF

########################################
# 5. 立即生效
########################################
source "$BASHRC"

########################################
# 6. 安装系统依赖
########################################
echo "==> 安装基础依赖"
pkg update -y
pkg install -y openjdk-21 wget unzip git aapt aapt2 apksigner dx ecj gradle termux-tools

########################################
# 7. 安装 Android SDK
########################################
echo "==> 安装 Android SDK"
mkdir -p "$ANDROID_HOME/cmdline-tools"
cd "$TMPDIR"

wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-*.zip
mv cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"

########################################
# 8. 安装 SDK 组件
########################################
yes | sdkmanager --licenses > /dev/null
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

########################################
# 9. 强制 Gradle 使用 Termux 的 ARM64 aapt2
########################################
mkdir -p ~/.gradle
echo "android.aapt2FromMavenOverride=$PREFIX/bin/aapt2" > ~/.gradle/gradle.properties

########################################
# 10. 清理旧 Gradle 缓存
########################################
rm -rf ~/.gradle/caches

########################################
# 11. 验证环境
########################################
echo ""
echo "✅ Termux Android 编译环境已就绪"
java -version
sdkmanager --version
aapt2 version
gradle --version
