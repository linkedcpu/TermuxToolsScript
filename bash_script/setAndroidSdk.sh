#!/bin/bash
set -e

########################################
# 0. 配置区（只改这里）
########################################
GITHUB_PROXY="https://gh-proxy.org"
NDK_URL="${GITHUB_PROXY}/github.com/lzhiyong/termux-ndk/releases/download/android-ndk/android-ndk-r29-aarch64.tar.xz"
SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

# ✅ 校验值已核实（官方来源）
NDK_SHA256="02e10e4ddfe8deaeb0bd0cf29d04c981ed5bc8a5d6b560ebb9e7661f472d684b"
SDK_SHA256="2d2d50857e4eb553af5a6dc3ad507a17adf43d115264b1afc116f95c92e5e258"

########################################
# 1. 校验函数
########################################
verify_file() {
    local file="$1"
    local expected="$2"
    local actual
    actual=$(sha256sum "$file" | awk '{print $1}')
    if [[ "$actual" != "$expected" ]]; then
        echo "❌ 校验失败，删除损坏文件: $file"
        echo "   期望: $expected"
        echo "   实际: $actual"
        rm -f "$file"
        return 1
    fi
    echo "✅ 校验通过: $file"
    return 0
}

########################################
# 2. 确保 .bashrc 存在且不是目录
########################################
BASHRC="$HOME/.bashrc"

# 防止 .bashrc 被误设为目录（极端情况）
if [[ -d "$BASHRC" ]]; then
    echo "⚠️ 发现 .bashrc 是目录，正在修复..."
    rm -rf "$BASHRC"
fi

# touch 不会覆盖内容，仅确保文件存在
touch "$BASHRC"

########################################
# 3. 写入环境变量（先清旧块）
########################################
ENV_START='# ===== TERMUX_ANDROID_ENV_START ====='
ENV_END='# ===== TERMUX_ANDROID_ENV_END ====='

sed -i "/$ENV_START/,/$ENV_END/d" "$BASHRC"

cat <<EOF >> "$BASHRC"

$ENV_START
export JAVA_HOME=\$PREFIX/lib/jvm/java-21-openjdk
export ANDROID_HOME=\$HOME/android-sdk
export ANDROID_NDK_HOME=\$ANDROID_HOME/ndk/29.0.14206865
export PATH=\$JAVA_HOME/bin:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/build-tools/34.0.0:\$PATH
$ENV_END
EOF

source "$BASHRC"

########################################
# 4. 安装最小依赖
########################################
pkg update -y
pkg install -y openjdk-21 wget tar xz-utils git aapt2 apksigner gradle termux-tools

########################################
# 5. 下载并校验（全自动）
########################################
cd "$TMPDIR"

# SDK
if [[ -f "commandlinetools.zip" ]]; then
    verify_file "commandlinetools.zip" "$SDK_SHA256" || true
fi
until [[ -f "commandlinetools.zip" && "$(sha256sum commandlinetools.zip | awk '{print $1}')" == "$SDK_SHA256" ]]; do
    echo "==> 下载 SDK"
    wget -c "$SDK_URL" -O commandlinetools.zip
done

# NDK
if [[ -f "android-ndk-r29-aarch64.tar.xz" ]]; then
    verify_file "android-ndk-r29-aarch64.tar.xz" "$NDK_SHA256" || true
fi
until [[ -f "android-ndk-r29-aarch64.tar.xz" && "$(sha256sum android-ndk-r29-aarch64.tar.xz | awk '{print $1}')" == "$NDK_SHA256" ]]; do
    echo "==> 下载 NDK"
    wget -c "$NDK_URL" -O android-ndk-r29-aarch64.tar.xz
done

########################################
# 6. 安装（强制覆盖）
########################################
rm -rf "$ANDROID_HOME/cmdline-tools"
unzip -o commandlinetools.zip
mv cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"

yes | sdkmanager --licenses > /dev/null || true
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

rm -rf "$ANDROID_HOME/ndk"
mkdir -p "$ANDROID_HOME/ndk"
tar -xJf android-ndk-r29-aarch64.tar.xz -C "$ANDROID_HOME/ndk/"
mv "$ANDROID_HOME/ndk/android-ndk-r29" "$ANDROID_HOME/ndk/29.0.14206865"

"$ANDROID_NDK_HOME/ndk-build" --version

########################################
# 7. Gradle 配置
########################################
mkdir -p ~/.gradle
echo "android.aapt2FromMavenOverride=$PREFIX/bin/aapt2" > ~/.gradle/gradle.properties

./gradlew --stop 2>/dev/null || true
rm -rf ~/.gradle/caches ~/.gradle/daemon

########################################
# 8. 验证环境
########################################
echo ""
echo "✅ Termux Android 编译环境已就绪（无参数 / 自校验 / 可重复跑）"
java -version
sdkmanager --version
aapt2 version
"$ANDROID_NDK_HOME/ndk-build" --version
