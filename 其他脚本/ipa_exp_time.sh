#!/bin/sh
#----------------------ipa签名证书过期时间----------------------
# 参数：$1为ipa文件路径
# 用例：sh ipa_exp_time.sh "xxx.ipa"
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
IPA_NAME=""

#ipa路径
IPA_PATH="$project_path/"

#解压路径
IPA_DIR="$project_path/ChangeIPAFile"

# 临时将xxx.mobileprovision转换成plist文件路径
temp_plist_path="./temp_profile.plist"

init(){

    # 是否传参进来
    if [[ ! -z $1 ]]; then
        IPA_PATH=$1
    fi
    
    # 是否包含ipa后缀
    if echo "$IPA_PATH" | grep -q -E '\.ipa$'
    then
        # 路径读取文件
        IPA_NAME=${IPA_PATH##*/}
        project_path=${IPA_PATH%/*}
        echo "==外部传入文件：$IPA_NAME===路径：$project_path"
    else
        # 判断文件后缀
        if [ "${IPA_NAME##*.}" != "ipa" ];then
        for file in $(ls "$project_path")
        do
            if [ "${file##*.}" = "ipa" ]&&[ ${file} != new_* ]; then
                IPA_NAME=${file}
                echo "===自动读取文件夹中的ipa文件：${IPA_NAME}"
                break
            fi
        done
        fi
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
        echo "== ${RED}${IPA_PATH}${NC} 不存在 =="
        return
    fi
    
    
    #删除临时解包目录
    if [ -d "$IPA_DIR" ]; then
        rm -rf "${IPA_DIR}"
    else
        mkdir -p "${IPA_DIR}"
    fi
    
    #解包IPA
    if [[ -f "$IPA_PATH" ]]; then
        #ipa解压（unzip直接解压，遇到中文会报错）
        # unzip -q "$IPA_PATH" -d "$IPA_DIR"
        # 此种方法解压避免出现中文无法解压的情况
        ditto -V -x -k --sequesterRsrc "$IPA_PATH" "$IPA_DIR"
        
        if [[ $? != 0 ]]; then
            echo "===${RED}ipa解压 $IPA_PATH 失败${NC}==="
            exit 2
        fi

        # 定位到*.app目录
        appDir="$IPA_DIR/Payload/`ls "$IPA_DIR/"Payload`"

        # 读取plist文件
        InfoPlist="${appDir}/Info.plist"
        
        # 读取描述文件
        PROFILE_PATH="${appDir}/embedded.mobileprovision"
        #开发团队
        TeamName=`egrep -a -A 2 TeamName "${PROFILE_PATH}" | grep string | sed -e 's/<string>//' -e 's/<\/string>//' -e 's/ //'`
        
        # app Id 名称
        AppIDName=`egrep -a -A 2 AppIDName "${PROFILE_PATH}" | grep string | sed -e 's/<string>//' -e 's/<\/string>//' -e 's/ //'`
        #描述文件过期时间
        ExDate=$(formattime `egrep -a -A 2 ExpirationDate "${PROFILE_PATH}" | grep date | sed -e 's/<date>//' -e 's/<\/date>//'`)
        
         # 当前时间
        nowDate=$(date "+%Y-%m-%d %H:%M:%S")
        t1=`date -j -f "%Y-%m-%d %H:%M:%S" "${nowDate}" "+%s"`
        t2=`date -j -f "%Y-%m-%d %H:%M:%S" "$ExDate" "+%s"`
        # 计算时间差值
        diffValue=`expr $t2 - $t1`
        # 一天秒数计算
        oneDay=`expr 24 \* 60 \* 60` #<strong>必须在*前加\才能实现乘法,因为 * 有其它意义</strong>
        # 剩余过期天数
        ExpDays=`expr $diffValue / $oneDay`

        # 描述文件名称
        Name=$(readfile "${PROFILE_PATH}" "Name")

        echo "\n\nAppID名称：${RED}${AppIDName}${NC}"
        echo "开发者：${RED}${TeamName}${NC}"
        echo "描述文件名称：${RED}${Name}${NC}"
        echo "ipa路径：${IPA_PATH}"
        echo "过期时间：${RED}${ExDate}${NC} 剩余：${RED}${ExpDays}${NC} 天\n\n"
    fi
    
    # 临时文件若存在，需清除
    if [ -f "$temp_plist_path" ];then
       rm -f $temp_plist_path
    fi

    # IPA解压包文件夹，默认会被删除
    rm -rf $IPA_DIR
}

# 读取描述文件（$1为描述文件路径，$2为查询字段）
readfile(){
    #接收参数，也就是xxx.mobileprovision的路径
    profile_path=$1
    #删除之前存在的plist文件
    rm -rf $temp_plist_path
    #将xxx.mobileprovision转换成xxx.plist
    security cms -D -i "$profile_path" > $temp_plist_path

    #判断第二参数是否为空
    if [[ ! -z $2 ]];then
      result=$(/usr/libexec/PlistBuddy -c "print $2" $temp_plist_path)
      echo "$result"
    fi
}

# 时间格式处理
formattime(){
    #过期时间格式处理用" "替换掉”T“，并删除所有的大写英文字符（详细sed指令语法）
    echo `echo "${1/T/ }" | sed 's/[A-Z]*//g'`
}

# 入口($1为ipa文件路径)
init $1
