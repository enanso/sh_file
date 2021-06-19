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

#脚本接收第一个一个参数是ipa路径 第二个参数是版本号
bundleVersion="CFBundleVersion"
shortVersion="CFBundleShortVersionString"

project_path=$(cd `dirname $0`; pwd)
#echo "===$project_path"
IPA_NAME="HBuilder.ipa"
#ipa路径
IPA_PATH="$project_path/HBuilder.ipa"

#解压路径
IPA_DIR="$project_path/ChangeIPAFile"

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

        # 修改plist文件
        changePlist "$bundleVersion" $2

#        # 打开文件
#        open $InfoPlist
        
        #将修改完的文件打包成ipa
        zipipa
    fi
}
# 压缩ipa文件
zipipa(){
    echo "===即将打开路径：${IPA_DIR} ===$IPA_NAME"
    
#    return
    cd ${IPA_DIR}
    zip -r -q "new_${IPA_NAME}" Payload
    if [[ $? != 0 ]]; then
        echo "===${RED}压缩Payload失败${NC}==="
        exit 2
    else
        # 打开生成后的文件
        open ${IPA_DIR}
        cp "${IPA_DIR}/new_${IPA_NAME}" "${project_path}"
        #删除Payload成功
        if [[ -d "$IPA_DIR/Payload" ]]; then
            rm -rf "$IPA_DIR/Payload"
        fi
        # 删除Symbols
        if [[ -d "$IPA_DIR/Symbols" ]]; then
            rm -rf "$IPA_DIR/Symbols"
        fi
    fi

}
# 修改plist (新增或者修改$1为key,$2为值)
function changePlist {

    value=`/usr/libexec/PlistBuddy -c "Print :${1}" $InfoPlist`
    #修改plist文件
    if [[ -n $value ]]; then
        if [ ${1} == ${bundleVersion} ];then
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

# 入口($1为ipa文件路径)
init $1  $2
