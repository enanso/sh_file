#!/bin/bash
#----------------------模拟器安卓并打开ipa包----------------------
# 功能：使用x-code编译模拟器版本的ipa包，解压后的.app安装到模拟器，打开测试
# 作者 ：JABase
#-----------------------------------------------------------------------

#Config Color
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 当前文件目录
project_path=$(cd `dirname $0`; pwd)

# 模拟器设备名称
simulator=""

# 模拟器设备名称
APP_PATH=""

# 循环输入直到有值为止
inputValue(){
    read -p "请输入【$1】: " word
    if [[ -z $word ]]; then
        inputValue "$1"
    fi
}

start(){
  
    # 是否包含app后缀
    if echo "$1" | grep -q -E '\.app$'
    then
        APP_PATH=$1
        #IPA_NAME=${1##*/}
        #project_path=${1%/*}
        #echo "==外部传入文件：$IPA_NAME===路径：$project_path"
    else
        for file in $(ls "$project_path")
        do
            if [ "${file##*.}" = "app" ]; then
                APP_PATH=$project_path/${file}
                echo "===自动读取文件夹中的app文件：${APP_PATH}"
                break
            fi
        done
    fi
    
    if [[ $APP_PATH != *".app" ]];then
        echo "===不存在.app文件==="
        return
    fi
    
    # 查看文件路径
    path=$(which ios-sim -g)
    if [[ -z $path ]];then
        echo "====安装工具‘ios-sim -g’===="
        npm install ios-sim -g
    fi
    # 读取plist文件
    InfoPlist="${APP_PATH}/Info.plist"
    # 读取Bundle Id的值
    BudleId=`/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" $InfoPlist`

    # 查看模拟器列表(Booted)
    # xcrun simctl list devices
    # xcrun simctl list

    echo "===点击模拟器，command+Q杀掉模拟器进程==="
    #开启模拟器
    open -a Simulator
    # 运行起来
    xcrun simctl launch booted "${BudleId}"
    if [ $? -ne 0 ]; then
        echo "程序启动失败，模拟器启动成功后后重新安装"
        # 安装指定的app
        xcrun simctl install booted "${APP_PATH}"
    fi
}
# 入口
start $1
