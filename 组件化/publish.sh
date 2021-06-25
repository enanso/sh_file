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

#替换podspec的Tag
updatePodspec() {
    echo -e "${GREEN}\n第二步：修改 s.version = ${tag} ${NC}⏰⏰⏰"
    sed -i '' s/"s.version[[:space:]]*=[[:space:]]*\'[0-9a-zA-Z.]*\'"/"s.version = \'${tag}\'"/g ${SpecName}
}

#本地验证Lib
localVerifyLib(){
    echo -e "${GREEN}\n第三步：开始本地验证：pod lib lint ${NC}⏰⏰⏰"
    if ! pod lib lint --skip-import-validation --allow-warnings --use-libraries --sources="${source1}"; then echo -e "${RED}验证失败${NC}🌧🌧🌧"; exit 1; fi
    echo -e "${GREEN}验证成功${NC}🚀🚀🚀"
}

#push代码，tag
pushAndTag(){
    echo -e "${GREEN}\n第四步：准备提交代码${NC}⏰⏰⏰"
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

    echo -e "${GREEN}\n第五步：准备打Tag${NC}⏰⏰⏰"
    if git tag ${tag}
    then
        git push --tags
        echo -e "${GREEN}打Tag成功${NC}🚀🚀🚀"
    else
        echo -e "${RED}打Tag失败${NC}🌧🌧🌧"
        exit 1
    fi
}

#远程验证
remoteVerifyLib(){
    echo -e "${GREEN}\n可省步：开始远程验证：pod spec lint ${NC}⏰⏰⏰"
    if ! pod spec lint --skip-import-validation --allow-warnings --use-libraries --sources="${source1}"; then echo -e "${RED}验证失败${NC}🌧🌧🌧"; exit 1; fi
    echo -e "${GREEN}验证成功${NC}🚀🚀🚀"
}

#发布库
publishLib(){
    echo -e "${GREEN}\n第六步：准备发布${tag}版本${NC}⏰⏰⏰"
    if ! pod trunk push ${SpecName} --allow-warnings; then echo -e "${RED}发布${tag}版本失败${NC}🌧🌧🌧"; exit 1; fi
    echo -e "${GREEN}发布${tag}版本成功${NC}🚀🚀🚀"
}

#发布二进制
publishBinary(){
    echo -e "${GREEN}\n第七步：准备发布${tag}二进制版本${NC}⏰⏰⏰"

    echo -e "${GREEN}发布${tag}二进制版本成功${NC}🚀🚀🚀"
}

# 判断文件是否存在
function hasfile(){
    # -f 参数判断 $1 是否存在
    if [ -f "$1" ]; then
      echo "YES"
    fi
      #touch "$1"
}
# 判断文件中是否包含某内容
function filehasword(){

    if [[ -z $2 ]]; then
        echo "$2值不能为空"
        return
    fi
    if [[ -n $(hasfile "$1") ]]; then

        if cat "$1" | grep "$2" > /dev/null
        then
            echo "$1中已存在$2"
            continue
        fi
    else
        echo "$1文件不存在"
    fi
}
publish(){
    # .gitignore文件件中追加内容
    if [[ -z $(filehasword ".gitignore" "Example/Pods") ]]; then
        # > 为覆盖内容 >>为追加内容
        echo "Example/Pods">>".gitignore"
        echo "Example/Podfile.lock">>".gitignore"
    fi
    #
    echo -e "${GREEN}请输入提交内容:${NC}"
    read a
    commitText=${a}
    
    #
    echo -e "${GREEN}请输入tag:${NC}"
    read b
    tag=${b}
    
    #
    if [ -z "$commitText" ]; then
        echo -e "${RED}提交内容不能为空${NC}🌧🌧🌧"
        exit 1
    fi

    if [ -z "$tag" ]; then
        echo -e "${RED}提交Tag不能为空${NC}🌧🌧🌧"
        exit 1
    fi

    if [ -z "$SpecName" ]; then
        echo -e "${RED}请配置podspec的名称${NC}🌧🌧🌧"
        exit 1
    fi
    
    #
    pull

    #
    updatePodspec
    
    #
    localVerifyLib

    #
    pushAndTag

    #
    remoteVerifyLib

    #
    publishLib

    #
    publishBinary

}

publish
