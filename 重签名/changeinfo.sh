#!/bin/sh
#----------------------ipa修改信息----------------------
# 参数：$1为ipa文件路径  $2为ipa版本（CFBundleVersion）值
# 用例：sh changeinfo.sh "xxx.ipa" "1.0.1"
# 作者 ：JABase
#----------------------------------------------------
#重签名别人ipa：https://www.jianshu.com/p/ecba455911db
#Config Color
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No Color

# 当前文件目录
project_path=$(cd `dirname $0`; pwd)

# ipa名称
IPA_NAME="Payload.ipa"

#ipa路径
IPA_PATH="$project_path/Payload.ipa"

#解压路径
IPA_DIR="$project_path/ChangeIPAFile"

# 是否允许打开plist文件,如果不打开，将自动删除多余文件(ture为打开)
canopen="false"

# 是否允许打开修改过后的ipa文件路径
canfile="false"

# plist配置文件
configFile="config.json"

init(){

    # 是否传参进来
    if [[ ! -z $1 ]]; then
        IPA_PATH=$1
    fi
    
    # 是否包含ipa后缀
    if echo "$IPA_PATH" | grep -q -E '\.ipa$'
    then
        echo "存在.ipa后缀"
    else
        # 是否以"/"结尾
        if echo "$IPA_PATH" | grep -q -E '\/$'
        then
            IPA_PATH="$IPA_PATH$IPA_NAME"
        else
            IPA_PATH="$IPA_PATH/$IPA_NAME"
        fi
    fi
    
    # 判断文件是否存在
    if [ ! -f "$IPA_PATH" ]; then
        echo "== ${RED}${IPA_PATH} 不存在${NC} =="
        return
    fi
    # 路径读取文件
    IPA_NAME=${IPA_PATH##*/}
    
    #删除临时解包目录
    if [ -d "$IPA_DIR" ]; then
        rm -rf "${IPA_DIR}"
    else
        mkdir -p "${IPA_DIR}"
    fi
    
    #解包IPA
    if [[ -f "$IPA_PATH" ]]; then
        #ipa解压
        unzip -q "$IPA_PATH" -d "$IPA_DIR"
        
        if [[ $? != 0 ]]; then
            echo "===${RED}ipa解压 $IPA_PATH 失败${NC}==="
            exit 2
        fi

        # 定位到*.app目录
        appDir="$IPA_DIR/Payload/`ls "$IPA_DIR/"Payload`"

        # 读取plist文件
        InfoPlist="${appDir}/Info.plist"
        
        if [ ${canopen} == "true" ];then
            # 打开文件
            open $InfoPlist
        fi
        
        # 修改plist配置文件
        infoPlistConfig
        #将修改完的文件打包成ipa
        zipipa
    fi
}

#infoPlist配置
infoPlistConfig() {
    # 当前目录下查找配置json文件
    result=$(find "./" -type f -name "${configFile}")
    echo "\n==== ${GREEN}开始通过【${configFile}】修改plist文件${NC}⏰⏰⏰ ${result}"
    
    if test -z "${result}"; then
        # 修改plist文件（$2无值时，自增）
        changePlist "CFBundleVersion" $2
        exit 1
    fi
    
    # 是否已修改build
    hasbuild="false"
    # 读取长度
    count=$(cat ${result} | jq 'keys | length')
    for ((j = 0; j < ${count}; j++)); do
        # 读取配置的key
        name=$(cat ${result} | jq 'keys' | jq -r --arg INDEX $j '.[$INDEX|tonumber]')
        # 读取配置的value
        value=$(cat ${result} | jq -r --arg NAME ${name} '.[$NAME]')
        
        # 更正key
        if [ ${name} == "Version" ] || [ ${name} == "version" ];then
            name="CFBundleShortVersionString"
        elif [ ${name} == "Build" ] || [ ${name} == "build" ];then
            name="CFBundleVersion"
        fi
        
        if [ ${name} == "CFBundleVersion" ];then
            hasbuild="true"
        fi
        # 原始值
        temp=`/usr/libexec/PlistBuddy -c "Print :${name}" $InfoPlist`

        # 判断plist文件是否已经存在值
        if [[ -n ${temp} ]]; then
            # 判断值是否为空
            if [[ ! -z ${value} ]];then
                `/usr/libexec/PlistBuddy -c "Set :${name} ${value}" $InfoPlist`
                echo "\n==修改:${GREEN}${name}${NC}==新值:${GREEN}${value}${NC}==旧值:${RED}${temp}${NC}"
            else
                `/usr/libexec/PlistBuddy -c "Delete :${name} ${value}" $InfoPlist`
                echo "\n==删除:${RED}${name}${NC}==旧值:${RED}${temp}${NC}"
            fi
        else
            if [[ ! -z ${value} ]];then
                `/usr/libexec/PlistBuddy -c "Add :${name} ${value}" $InfoPlist`
                echo "\n==新增:${GREEN}${name}${NC}==值:${GREEN}${value}${NC}"
            fi
        fi
        
    done
    
    # 未修改build
    if [ ${hasbuild} == "false" ];then
        # 修改plist文件（$2无值时，自增）
        changePlist "CFBundleVersion" $2
    fi
    echo "\n==== ${GREEN}plist完成修改${NC}🚀🚀🚀\n"
}

# 当前径下是否包含某文件
hasfile(){
    if [[ ! -z $1 ]]; then
        for file in `ls -a ${project_path}`
        do
            if [ "${file}" = "$1" ]; then
                echo "YES"
            fi
        done
    fi
}
# 压缩ipa文件
zipipa(){

    cd ${IPA_DIR}
    
    NEW_IPA_NAME="new_${IPA_NAME}"
    
    zip -r -q "${NEW_IPA_NAME}" Payload
    if [[ $? != 0 ]]; then
        echo "===${RED}压缩Payload失败${NC}==="
        exit 2
    else
        # 读取Bundle Id的值
        BudleId=`/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" $InfoPlist`
        
        # ipa拷贝至当前目录下
        cp "${IPA_DIR}/${NEW_IPA_NAME}" "${project_path}"
        
        if [ ${canfile} == "true" ];then
            # 打开生成后的文件
            open ${IPA_DIR}
            #注意此处这是两个反引号，表示运行系统命令
            for file in `ls -a ${IPA_DIR}`
            do
                # 删除所有非ipa文件
                if [ "${file##*.}" != "ipa" ]&&[ "${file}" != "." ]&&[ "${file}" != ".." ];then
                    if [ ${canopen} == "true" ];then
                        if [ ${file} != "Payload" ];then
                            rm -rf $file
                        fi
                    else
                        rm -rf $file
                    fi
                fi
            done
        else
            # 移除所有文件
            rm -rf $IPA_DIR
        fi

        #回到当前目录执行
        cd ${project_path}
        if [ $(hasfile "resign.sh") = "YES" ];then
            read -p "输入回车、空格及 y 以外的值拒绝重签名: " res
            if [ -z ${res} ]||[ ${res} == "y" ]||[ ${res} == "Y" ];then
                # 执行签名脚本
                sh resign.sh "${NEW_IPA_NAME}" "$BudleId"
            fi
        fi
    fi

}
# 修改plist (新增或者修改$1为key,$2为值)
function changePlist {

    value=`/usr/libexec/PlistBuddy -c "Print :${1}" $InfoPlist`
    #修改plist文件
    if [[ -n $value ]]; then
        if [ ${1} == "CFBundleVersion" ];then
            if [[ -n $2 ]]; then
              result=`/usr/libexec/PlistBuddy -c "Set :${1} ${2}" $InfoPlist`
            else
                # 将value中的“.”替换成“_”,并拆分成数组
                line=($(echo ${value//./_} | sed 's/_/ /g'))
                last=${#line[*]}-1
                FINAL=${line[last]}
                let FINAL++
                line[last]=${FINAL}
                FINAL=""
                for i in ${line[*]}
                do
                    if [[ -n $FINAL ]]; then
                        FINAL="${FINAL}.${i}"
                    else
                        FINAL=${i}
                    fi
                done
                result=`/usr/libexec/PlistBuddy -c "Set :${1} ${FINAL}" $InfoPlist`
            fi
            
        else
            result=`/usr/libexec/PlistBuddy -c "Set :${1} ${2}" $InfoPlist`
        fi
    else
        result=`/usr/libexec/PlistBuddy -c "Add :${1} ${2}" $InfoPlist`
        echo "新增完成${result}"
    fi
}

# 入口($1为ipa文件路径，$2为build指定值)
init $1  $2
