#!/data/data/com.termux/files/usr/bin/bash
# Android 项目创建脚本 - 使用国内源
# 解决 ClassNotFoundException 问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_mirror() { echo -e "${CYAN}[MIRROR]${NC} $1"; }

# 国内镜像配置
setup_mirror_sources() {
    local mirror_name="$1"
    
    case "$mirror_name" in
        aliyun)
            GRADLE_MIRROR="https://mirrors.aliyun.com/gradle"
            MAVEN_MIRROR="https://maven.aliyun.com/repository/public"
            WRAPPER_JAR_URL="https://mirrors.aliyun.com/gradle/gradle-wrapper.jar"
            ;;
        huawei)
            GRADLE_MIRROR="https://mirrors.huaweicloud.com/gradle"
            MAVEN_MIRROR="https://repo.huaweicloud.com/repository/maven"
            WRAPPER_JAR_URL="https://repo.huaweicloud.com/gradle/gradle-wrapper.jar"
            ;;
        tencent)
            GRADLE_MIRROR="https://mirrors.cloud.tencent.com/gradle"
            MAVEN_MIRROR="https://mirrors.cloud.tencent.com/nexus/repository/maven-public"
            WRAPPER_JAR_URL="https://mirrors.cloud.tencent.com/gradle/gradle-wrapper.jar"
            ;;
        163)
            GRADLE_MIRROR="https://mirrors.163.com/gradle"
            MAVEN_MIRROR="https://mirrors.163.com/maven/repository/maven-public"
            WRAPPER_JAR_URL="https://mirrors.163.com/gradle/gradle-wrapper.jar"
            ;;
        ustc)
            GRADLE_MIRROR="https://mirrors.ustc.edu.cn/gradle"
            MAVEN_MIRROR="https://mirrors.ustc.edu.cn/nexus/content/repositories/jcenter"
            WRAPPER_JAR_URL="https://mirrors.ustc.edu.cn/gradle/gradle-wrapper.jar"
            ;;
        *)
            GRADLE_MIRROR="https://services.gradle.org/distributions"
            MAVEN_MIRROR="https://repo.maven.apache.org/maven2"
            WRAPPER_JAR_URL="https://github.com/gradle/gradle/raw/v8.5/gradle/wrapper/gradle-wrapper.jar"
            print_warning "使用默认国际源，下载可能较慢"
            ;;
    esac
    
    print_mirror "使用镜像: $mirror_name"
    print_mirror "Gradle 镜像: $GRADLE_MIRROR"
    print_mirror "Maven 镜像: $MAVEN_MIRROR"
}

# 检查并安装依赖
check_dependencies() {
    print_info "检查系统依赖..."
    
    # 检查 Termux 环境
    if [ -f "/data/data/com.termux/files/usr/bin/pkg" ]; then
        # Termux 环境
        if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
            print_info "安装下载工具..."
            pkg update && pkg install -y wget curl
        fi
        
        if ! command -v java &> /dev/null; then
            print_info "安装 Java..."
            pkg install -y openjdk-17
        fi
        
        if ! command -v unzip &> /dev/null; then
            print_info "安装 unzip..."
            pkg install -y unzip
        fi
    else
        # 非 Termux 环境
        local missing=()
        for cmd in java wget curl unzip; do
            if ! command -v $cmd &> /dev/null; then
                missing+=("$cmd")
            fi
        done
        
        if [ ${#missing[@]} -gt 0 ]; then
            print_error "缺少必要工具: ${missing[*]}"
            exit 1
        fi
    fi
    
    print_success "系统依赖检查通过"
}

# 从国内镜像下载 wrapper.jar
download_wrapper_from_mirror() {
    local target_file="$1"
    local mirror_name="$2"
    
    print_info "从国内镜像下载 Gradle wrapper.jar..."
    
    # 获取镜像 URL
    setup_mirror_sources "$mirror_name"
    
    # 国内镜像源列表（按优先级）
    local mirror_urls=(
        "$WRAPPER_JAR_URL"
        "https://mirrors.aliyun.com/gradle/gradle-wrapper.jar"
        "https://repo.huaweicloud.com/gradle/gradle-wrapper.jar"
        "https://mirrors.cloud.tencent.com/gradle/gradle-wrapper.jar"
        "https://mirrors.163.com/gradle/gradle-wrapper.jar"
    )
    
    # 如果指定了镜像但不是国内源，添加官方 GitHub
    if [[ "$mirror_name" == "official" ]]; then
        mirror_urls=("https://github.com/gradle/gradle/raw/v8.5/gradle/wrapper/gradle-wrapper.jar")
    fi
    
    local downloaded=false
    for url in "${mirror_urls[@]}"; do
        print_info "尝试下载: $(echo "$url" | cut -d'/' -f3)"
        
        if command -v wget &> /dev/null; then
            if wget -q --timeout=20 --tries=1 -O "$target_file.tmp" "$url"; then
                if [ -s "$target_file.tmp" ]; then
                    mv "$target_file.tmp" "$target_file"
                    downloaded=true
                    print_success "下载成功: $(basename "$url")"
                    break
                fi
            fi
        elif command -v curl &> /dev/null; then
            if curl -s -f -L -o "$target_file.tmp" --connect-timeout 20 "$url"; then
                if [ -s "$target_file.tmp" ]; then
                    mv "$target_file.tmp" "$target_file"
                    downloaded=true
                    print_success "下载成功: $(basename "$url")"
                    break
                fi
            fi
        fi
        
        rm -f "$target_file.tmp" 2>/dev/null
    done
    
    if [ "$downloaded" = false ]; then
        print_error "所有国内镜像下载失败"
        return 1
    fi
    
    # 验证文件
    if [ -f "$target_file" ] && [ -s "$target_file" ]; then
        local file_size=$(du -h "$target_file" | cut -f1)
        print_success "wrapper.jar 下载完成 ($file_size)"
        return 0
    else
        print_error "下载的文件无效"
        return 1
    fi
}

# 从 Gradle 发行版提取 wrapper
extract_wrapper_from_distribution() {
    local target_file="$1"
    local mirror_name="$2"
    local gradle_version="8.5"
    
    print_info "从 Gradle 发行版提取 wrapper..."
    
    setup_mirror_sources "$mirror_name"
    
    # 创建临时目录
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # 发行版下载 URL
    local distribution_url="${GRADLE_MIRROR}/gradle-${gradle_version}-bin.zip"
    
    print_info "下载发行版: $distribution_url"
    
    if command -v wget &> /dev/null; then
        wget -q --timeout=30 -O gradle.zip "$distribution_url"
    elif command -v curl &> /dev/null; then
        curl -s -L -o gradle.zip "$distribution_url"
    fi
    
    if [ ! -f "gradle.zip" ] || [ ! -s "gradle.zip" ]; then
        print_warning "发行版下载失败，尝试备用URL..."
        
        # 备用URL列表
        local backup_urls=(
            "https://mirrors.aliyun.com/gradle/gradle-${gradle_version}-bin.zip"
            "https://repo.huaweicloud.com/gradle/gradle-${gradle_version}-bin.zip"
            "https://mirrors.cloud.tencent.com/gradle/gradle-${gradle_version}-bin.zip"
        )
        
        for url in "${backup_urls[@]}"; do
            print_info "尝试备用源: $(echo "$url" | cut -d'/' -f3)"
            if command -v wget &> /dev/null; then
                wget -q --timeout=20 -O gradle.zip "$url" && break
            elif command -v curl &> /dev/null; then
                curl -s -L -o gradle.zip "$url" && break
            fi
        done
    fi
    
    if [ -f "gradle.zip" ] && [ -s "gradle.zip" ]; then
        # 解压
        unzip -q gradle.zip 2>/dev/null || true
        
        # 查找 wrapper.jar
        local found_wrapper=$(find . -name "gradle-wrapper.jar" -type f 2>/dev/null | head -1)
        
        if [ -n "$found_wrapper" ] && [ -f "$found_wrapper" ]; then
            cp "$found_wrapper" "$target_file"
            print_success "从发行版提取成功"
        else
            print_error "在发行版中未找到 wrapper.jar"
        fi
        
        # 清理
        rm -f gradle.zip
    else
        print_error "无法下载发行版"
    fi
    
    cd - >/dev/null
    rm -rf "$temp_dir"
}

# 创建 gradlew 启动脚本
create_gradlew_script() {
    print_info "创建 Gradle 启动脚本..."
    
    cat > gradlew << 'EOF'
#!/usr/bin/env bash

# Gradle 启动脚本 - 国内镜像优化版

# 设置环境
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 查找 Java
JAVACMD=java
if [ -n "$JAVA_HOME" ]; then
    if [ -x "$JAVA_HOME/bin/java" ]; then
        JAVACMD="$JAVA_HOME/bin/java"
    fi
fi

# 检查 wrapper.jar
WRAPPER_JAR="gradle/wrapper/gradle-wrapper.jar"
if [ ! -f "$WRAPPER_JAR" ]; then
    echo "错误: 未找到 gradle-wrapper.jar"
    echo "请检查文件是否存在: $WRAPPER_JAR"
    exit 1
fi

if [ ! -s "$WRAPPER_JAR" ]; then
    echo "错误: gradle-wrapper.jar 文件为空或损坏"
    exit 1
fi

# JVM 参数
JVM_OPTS="-Xmx64m -Xms64m"

# 设置国内镜像加速下载
GRADLE_OPTS="-Dorg.gradle.wrapper.url=https://mirrors.aliyun.com/gradle"
GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.daemon=false"
GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.console=plain"

# Termux 环境优化
if [ -d "/data/data/com.termux" ]; then
    GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.jvmargs=-Xmx1024m"
    GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.parallel=false"
fi

# 执行 Gradle
exec "$JAVACMD" \
    $JVM_OPTS \
    $GRADLE_OPTS \
    -classpath "$WRAPPER_JAR" \
    org.gradle.wrapper.GradleWrapperMain \
    "$@"
EOF
    
    chmod +x gradlew
    
    # Windows 版本
    cat > gradlew.bat << 'EOF'
@echo off
@rem Gradle 启动脚本 for Windows
@rem 国内镜像优化版

set DIRNAME=%~dp0
if "%DIRNAME%"=="" set DIRNAME=.
set APP_HOME=%DIRNAME%

set WRAPPER_JAR=%APP_HOME%\gradle\wrapper\gradle-wrapper.jar

if not exist "%WRAPPER_JAR%" (
    echo Error: gradle-wrapper.jar not found
    pause
    exit /b 1
)

if %~z0 LSS 0 (
    echo Error: gradle-wrapper.jar is empty or corrupted
    pause
    exit /b 1
)

@rem 设置国内镜像
set GRADLE_OPTS=%GRADLE_OPTS% -Dorg.gradle.wrapper.url=https://mirrors.aliyun.com/gradle

java -Xmx64m -Xms64m %GRADLE_OPTS% -classpath "%WRAPPER_JAR%" org.gradle.wrapper.GradleWrapperMain %*
EOF
    
    print_success "启动脚本创建完成"
}

# 创建 wrapper 配置文件
create_wrapper_config() {
    local gradle_version="$1"
    local mirror_name="$2"
    
    print_info "创建 wrapper 配置文件..."
    
    setup_mirror_sources "$mirror_name"
    
    # 生成 distribution URL
    local distribution_url="${GRADLE_MIRROR}/gradle-${gradle_version}-bin.zip"
    
    # 转义 URL 中的冒号
    distribution_url=$(echo "$distribution_url" | sed 's/:/\\\\:/g')
    
    cat > gradle/wrapper/gradle-wrapper.properties << EOF
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=$distribution_url
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
    
    print_success "Wrapper 配置完成"
    print_mirror "下载地址: $(echo "$distribution_url" | sed 's/\\\\:/:/g')"
}

# 创建 Gradle 属性文件
create_gradle_properties() {
    local mirror_name="$1"
    
    setup_mirror_sources "$mirror_name"
    
    cat > gradle.properties << EOF
# Gradle 属性配置 - 国内镜像优化
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.daemon=true
org.gradle.configureondemand=true

# 国内镜像设置
systemProp.org.gradle.wrapper.url=https://mirrors.aliyun.com/gradle
systemProp.maven.aliyun.url=https://maven.aliyun.com/repository/public

# 网络超时设置
systemProp.org.gradle.internal.http.connectionTimeout=120000
systemProp.org.gradle.internal.http.socketTimeout=120000
systemProp.org.gradle.download.socketTimeout=60000
systemProp.org.gradle.download.connectionTimeout=60000

# Android 配置
android.useAndroidX=true
android.enableJetifier=true
EOF
    
    print_success "Gradle 属性文件创建完成"
}

# 创建 Android 项目结构
create_android_project_structure() {
    local project_name="$1"
    local package_name="$2"
    local mirror_name="$3"
    
    print_info "创建 Android 项目结构..."
    
    setup_mirror_sources "$mirror_name"
    
    # 创建目录
    mkdir -p app/src/main/{java,res/{layout,values,drawable}}
    local java_path="app/src/main/java/$(echo "$package_name" | tr '.' '/')"
    mkdir -p "$java_path"
    
    # settings.gradle.kts
    cat > settings.gradle.kts << EOF
pluginManagement {
    repositories {
        maven { url = uri("$MAVEN_MIRROR") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        maven { url = uri("$MAVEN_MIRROR") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}
rootProject.name = "$project_name"
include(":app")
EOF
    
    # 根 build.gradle.kts
    cat > build.gradle.kts << EOF
buildscript {
    repositories {
        maven { url = uri("$MAVEN_MIRROR") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
    }
}
tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
EOF
    
    # app/build.gradle.kts
    cat > app/build.gradle.kts << EOF
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}
android {
    namespace = "$package_name"
    compileSdk = 34
    
    defaultConfig {
        applicationId = "$package_name"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }
    
    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    
    kotlinOptions {
        jvmTarget = "11"
    }
}
dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.10.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
}
EOF
    
    # 创建 Android 文件
    create_android_files "$package_name"
    
    print_success "项目结构创建完成"
}

create_android_files() {
    local package_name="$1"
    local java_path="app/src/main/java/$(echo "$package_name" | tr '.' '/')"
    
    # MainActivity.kt
    cat > "$java_path/MainActivity.kt" << EOF
package $package_name

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.widget.Button
import android.widget.Toast

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        findViewById<Button>(R.id.button).setOnClickListener {
            Toast.makeText(this, "Hello from China Mirror!", Toast.LENGTH_SHORT).show()
        }
    }
}
EOF
    
    # AndroidManifest.xml
    cat > app/src/main/AndroidManifest.xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/Theme.AppCompat.Light">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF
    
    # 布局文件
    cat > app/src/main/res/layout/activity_main.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:gravity="center"
    android:orientation="vertical"
    android:padding="16dp">
    
    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="中国镜像版 Android 项目"
        android:textSize="20sp"
        android:textStyle="bold" />
        
    <Button
        android:id="@+id/button"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="16dp"
        android:text="点击测试"
        android:padding="12dp" />
</LinearLayout>
EOF
    
    # 字符串资源
    cat > app/src/main/res/values/strings.xml << EOF
<resources>
    <string name="app_name">中国镜像项目</string>
</resources>
EOF
}

# 验证 wrapper
verify_gradle_wrapper() {
    print_info "验证 Gradle Wrapper..."
    
    if [ ! -f "gradle/wrapper/gradle-wrapper.jar" ]; then
        print_error "❌ wrapper.jar 不存在"
        return 1
    fi
    
    if [ ! -s "gradle/wrapper/gradle-wrapper.jar" ]; then
        print_error "❌ wrapper.jar 文件为空"
        return 1
    fi
    
    # 检查文件类型
    if file "gradle/wrapper/gradle-wrapper.jar" | grep -q "Java archive"; then
        print_success "✓ wrapper.jar 是有效的 JAR 文件"
    else
        print_warning "⚠️ wrapper.jar 可能不是有效的 JAR 文件"
    fi
    
    # 检查文件大小 (应该 > 50KB)
    local file_size=$(stat -c%s "gradle/wrapper/gradle-wrapper.jar" 2>/dev/null || stat -f%z "gradle/wrapper/gradle-wrapper.jar" 2>/dev/null || du -b "gradle/wrapper/gradle-wrapper.jar" | cut -f1)
    if [ "$file_size" -gt 50000 ]; then
        print_success "✓ wrapper.jar 大小正常 ($((file_size/1024)) KB)"
    else
        print_warning "⚠️ wrapper.jar 可能太小 ($((file_size/1024)) KB)"
    fi
    
    # 测试运行
    print_info "测试运行 Gradle..."
    if ./gradlew --version 2>&1 | grep -q "Gradle"; then
        print_success "✅ Gradle Wrapper 验证通过！"
        return 0
    else
        print_warning "⚠️ Gradle 运行测试失败，但文件存在"
        return 1
    fi
}

# 显示帮助
show_help() {
    echo "Android 项目创建工具 - 国内镜像版"
    echo ""
    echo "使用方法: $0 [选项] <项目名> [包名]"
    echo ""
    echo "选项:"
    echo "  -m, --mirror <源>   指定镜像源 (默认: aliyun)"
    echo "  -v, --version <版本> 指定 Gradle 版本 (默认: 8.5)"
    echo "  -h, --help          显示帮助"
    echo ""
    echo "支持的镜像源:"
    echo "  aliyun    阿里云镜像 (推荐，速度最快)"
    echo "  huawei    华为云镜像"
    echo "  tencent   腾讯云镜像"
    echo "  163       网易镜像"
    echo "  ustc      中科大镜像"
    echo "  official  官方国际源"
    echo ""
    echo "示例:"
    echo "  $0 MyApp com.example.app"
    echo "  $0 -m huawei MyApp"
    echo "  $0 --mirror tencent --version 8.5 MyApp com.company.app"
    echo ""
}

# 主函数
main() {
    local project_name=""
    local package_name="com.example.myapp"
    local mirror_name="aliyun"
    local gradle_version="8.5"
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -m|--mirror)
                mirror_name="$2"
                shift 2
                ;;
            -v|--version)
                gradle_version="$2"
                shift 2
                ;;
            *)
                if [ -z "$project_name" ]; then
                    project_name="$1"
                elif [ -z "$package_name" ]; then
                    package_name="$1"
                fi
                shift
                ;;
        esac
    done
    
    if [ -z "$project_name" ]; then
        print_error "错误: 需要指定项目名"
        show_help
        exit 1
    fi
    
    echo ""
    echo "========================================"
    echo "    🚀 Android 项目创建工具"
    echo "        国内镜像加速版"
    echo "========================================"
    echo "项目名: $project_name"
    echo "包名: $package_name"
    echo "Gradle 版本: $gradle_version"
    echo "镜像源: $mirror_name"
    echo "========================================"
    echo ""
    
    # 检查依赖
    check_dependencies
    
    # 创建项目目录
    if [ -d "$project_name" ]; then
        print_warning "目录已存在: $project_name"
        echo "是否覆盖? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_info "操作取消"
            exit 0
        fi
        rm -rf "$project_name"
    fi
    
    mkdir -p "$project_name"
    cd "$project_name" || exit
    
    # 创建 wrapper 目录
    mkdir -p gradle/wrapper
    
    # 步骤1: 下载 wrapper.jar
    print_info "下载 Gradle wrapper.jar..."
    if ! download_wrapper_from_mirror "gradle/wrapper/gradle-wrapper.jar" "$mirror_name"; then
        print_warning "直接下载失败，尝试从发行版提取..."
        extract_wrapper_from_distribution "gradle/wrapper/gradle-wrapper.jar" "$mirror_name"
    fi
    
    # 如果还是失败，创建最小可用的 wrapper
    if [ ! -f "gradle/wrapper/gradle-wrapper.jar" ] || [ ! -s "gradle/wrapper/gradle-wrapper.jar" ]; then
        print_error "无法下载有效的 wrapper.jar"
        print_info "创建最小可用的 wrapper..."
        create_minimal_wrapper_fallback
    fi
    
    # 步骤2: 创建 wrapper 配置
    create_wrapper_config "$gradle_version" "$mirror_name"
    
    # 步骤3: 创建启动脚本
    create_gradlew_script
    
    # 步骤4: 创建 Gradle 属性文件
    create_gradle_properties "$mirror_name"
    
    # 步骤5: 验证 wrapper
    if ! verify_gradle_wrapper; then
        print_warning "Wrapper 验证失败，但继续创建项目结构..."
    fi
    
    # 步骤6: 创建项目结构
    create_android_project_structure "$project_name" "$package_name" "$mirror_name"
    
    # 步骤7: 创建 .gitignore
    cat > .gitignore << 'EOF'
*.apk
*.ap_
*.aab
.gradle/
build/
local.properties
*.log
.idea/
*.iml
.DS_Store
EOF
    
    # 显示结果
    echo ""
    echo "========================================"
    print_success "🎉 项目创建完成！"
    echo "========================================"
    echo ""
    echo "📁 项目位置: $(pwd)"
    echo "🔄 镜像源: $mirror_name"
    echo ""
    echo "🚀 快速开始:"
    echo "  1. cd $project_name"
    echo "  2. ./gradlew build          # 构建项目"
    echo "  3. ./gradlew assembleDebug  # 生成 APK"
    echo ""
    echo "💡 提示:"
    echo "  - 首次运行会自动从国内镜像下载依赖"
    echo "  - 如果下载慢，可修改 gradle/wrapper/gradle-wrapper.properties"
    echo "  - 需要 Android SDK 支持编译"
    echo ""
    echo "🔧 问题排查:"
    echo "  ./gradlew --version         # 验证安装"
    echo "  rm -rf ~/.gradle/wrapper    # 清理缓存"
    echo ""
    echo "========================================"
}

# 创建最小可用的 wrapper 备用方案
create_minimal_wrapper_fallback() {
    print_warning "创建最小可用的 wrapper.jar 备用方案..."
    
    # 创建一个能工作的最小 wrapper
    # 注意：这只是一个占位符，实际需要真正的 wrapper.jar
    cat > gradle/wrapper/gradle-wrapper.jar << 'EOF'
这是一个临时的 wrapper.jar 占位符
请手动运行以下命令修复:
1. 确保已安装 gradle: pkg install gradle
2. 运行: gradle wrapper --gradle-version 8.5
EOF
    
    print_info "已创建占位符，需要手动运行: gradle wrapper"
}

# 运行主程序
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

main "$@"
