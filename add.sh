#!/usr/bin/env bash

#Config Color
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 提交内容
commitText=""

#加速器
export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890

# 循环输入直到有值为止
inputValue(){
    read -p "请输入【$1】: " word
    if [[ -z $word ]]; then
        inputValue "$1"
    fi
}

#pull代码
pull() {
    echo -e "${GREEN}\n第一步：准备pull代码${NC}⏰⏰⏰"
    #先拉代码
    if git pull; then
        echo -e "${GREEN}pull代码成功${NC}🚀🚀🚀"
    else
        echo -e "${RED}pull代码失败，请手动解决冲突${NC}🌧🌧🌧"
        exit 1
    fi
}

#push代码
push(){
    echo -e "${GREEN}\n第二步：准备提交代码${NC}⏰⏰⏰"
    git add .
    if ! git commit -m ${commitText}
    then
        echo -e "${RED}git commit失败${NC}🌧🌧🌧"
        exit 1
    fi
    if ! git push
    then
        echo -e "${RED}git push失败${NC}🌧🌧🌧"
        exit 1
    fi
    echo -e "${GREEN}提交代码成功${NC}🚀🚀🚀"
}

start(){

    # 是否带入参数
    if [[ ! -z $1 ]];then
       commitText=$1
    fi
    
    if [[ -z $commitText ]];then
       #执行循环输入
       inputValue "请输入提交内容"
       #赋值操作
       commitText=${word}
    fi
    #拉取远程库
    pull
    #推送代码
    push
}

# 入口
start $1
