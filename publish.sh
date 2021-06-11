#!/usr/bin/env bash

#Config Color
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

#const
source1=https://github.com/CocoaPods/Specs.git
commitText=""
tag=""
result=`find ./ -maxdepth 1 -type f -name "*.podspec"`
SpecName=${result}


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

#push代码，tag
pushAndTag(){
    echo -e "${GREEN}\n第三步：准备提交代码${NC}⏰⏰⏰"
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

#    echo -e "${GREEN}\n第五步：准备打Tag${NC}⏰⏰⏰"
#    if git tag ${tag}
#    then
#        git push --tags
#        echo -e "${GREEN}打Tag成功${NC}🚀🚀🚀"
#    else
#        echo -e "${RED}打Tag失败${NC}🌧🌧🌧"
#        exit 1
#    fi
}

#远程验证
remoteVerifyLib(){
    echo -e "${GREEN}\n可省步：开始远程验证：pod spec lint ${NC}⏰⏰⏰"
    if ! pod spec lint --skip-import-validation --allow-warnings --use-libraries --sources="${source1}"; then echo -e "${RED}验证失败${NC}🌧🌧🌧"; exit 1; fi
    echo -e "${GREEN}验证成功${NC}🚀🚀🚀"
}


publish(){
    #
    echo -e "${GREEN}请输入提交内容:${NC}"
    read a
    commitText=${a}
    
    #
    if [ -z "$commitText" ]; then
        echo -e "${RED}提交内容不能为空${NC}🌧🌧🌧"
        exit 1
    fi
    
    #拉取远程库
    pull

    #推送代码
    pushAndTag
}

publish
