#!/bin/bash
#----------------------删除iOS描述文件mobileprovision----------------------
# 功能1：删除iOS本地存储的已经过期（设置是否允许删除）
# 功能2：删除iOS本地存储指定描述文件（通过字段匹配）
# 作者 ：JABase
#----------------------------------------------------------

#https://blog.csdn.net/qq_36366758/article/details/102744715
#https://blog.csdn.net/HeroRazor/article/details/80351171

SPACE="=============="
#Config Color
RED="${SPACE}\033[0;31m"
GREEN="${SPACE}\033[0;32m"
NC="\033[0m" # No Color

#描述文件所在文件夹路径 (X-code默认为位置)
#dir="${HOME}/Library/MobileDevice/Provisioning Profiles/"

#描述文件所在文件夹路径 (手动设置文件夹)
dir="${HOME}/Desktop/mobileprovision/"

#所有描述文件列表
filelist=`ls "${dir}"`

#描述文件删除匹配字段 (默认匹配Bundle Id)
#feild="application-identifier"
#描述文件删除匹配字段 (#可手动填入配置（为空时，下方会提示选择处理）)
feild="application-identifier"
#删除匹配字段对应的值,【可手动填入配置（为空时，下方会提示输入）】
feildValue="cn.com.ay.tianhuagong"

#可匹配查询字段集合（可根据描述文件中的可匹配字段自行增加选项）
check=("AppIDName" "UUID" "application-identifier" "com.apple.developer.team-identifier" "TeamName" "BundleId" "all")

#处理查询（使用egrep正则匹配）
dealCheck(){

    # 定义记录即将删除文件的数组
    del_arr=()
    # 定义记录已经过期的文件数组
    exdate_arr=()
    #描述文件总数量
    count=0
    for filename in $filelist
        do
        #数量自增
        let count++
        #文件路径
        PROFILE_FILE="${dir}${filename}"
        #开发团队
        TeamName=`egrep -a -A 2 TeamName "${PROFILE_FILE}" | grep string | sed -e 's/<string>//' -e 's/<\/string>//' -e 's/ //'`
        # app Id 名称
        AppIDName=`egrep -a -A 2 AppIDName "${PROFILE_FILE}" | grep string | sed -e 's/<string>//' -e 's/<\/string>//' -e 's/ //'`
        
#        # 描述文件名称
#        Name=`/usr/libexec/PlistBuddy -c "Print Name" /dev/stdin <<< $(security cms -D -i $PROFILE_FILE)`
        #筛选Id
        IdentifierPrefix=`egrep -a -A 2 application-identifier "${PROFILE_FILE}" | grep string | sed -e 's/<string>//' -e 's/<\/string>//' -e 's/ //'`
        #第一次出现小数点时截取，作为BundleId
        BundleId=${IdentifierPrefix#*.}

        if [ ${BundleId} == ${feildValue} ] && [ ${feildValue} != "" ]
        then
           echo "\n${SPACE}符合文件：${RED}${filename}${NC}${SPACE}${Name}"
           del_arr[${#del_arr[*]}]="${PROFILE_FILE}"
        fi

        #描述文件创建时间
        CreationDate=`egrep -a -A 2 CreationDate "${PROFILE_FILE}" | grep date | sed -e 's/<date>//' -e 's/<\/date>//'`

        #描述文件过期时间
        ExpirationDate=`egrep -a -A 2 ExpirationDate "${PROFILE_FILE}" | grep date | sed -e 's/<date>//' -e 's/<\/date>//'`

        #过期时间格式处理用" "替换掉”T“，并删除所有的大写英文字符（详细sed指令语法）
        ExDate=`echo "${ExpirationDate/T/ }" | sed 's/[A-Z]*//g'`
        if [ ${#ExDate} -eq 20 ];then
           ExDate=${ExDate:1}
        fi
        # 当前时间
        nowDate=$(date "+%Y-%m-%d %H:%M:%S")
        t1=`date -j -f "%Y-%m-%d %H:%M:%S" "${nowDate}" "+%s"`
        t2=`date -j -f "%Y-%m-%d %H:%M:%S" "$ExDate" "+%s"`
        # 过期时间比较（当前时间大于或等于过期时间，即视为过期）
        if [ $t1 -gt $t2 ] || [ $t1 -eq $t2 ]; then
            CreDate=`echo "${CreationDate/T/ }" | sed 's/[A-Z]*//g'`
            echo "当前:$nowDate 大于 过期:$ExDate 文件已过期：${filename} 名称：${Name} 创建:$CreDate"
            exdate_arr[${#exdate_arr[*]}]="${PROFILE_FILE}"
            #自动删除过期描述文件
            rm "${PROFILE_FILE}"
        fi
        done

    echo "\n=========描述文件总数量：${count}"
    echo "\n=========符合筛选文件路径：${del_arr[*]}"
    echo "=========筛选数量：${#del_arr[*]}\n"
    echo "=========过期数量：${#exdate_arr[*]}\n"
}

#初始化
init(){
#2021-12-22T10:19:52Z、nowDate=$(date "+%Y-%m-%dT%H:%M:%SZ")
    echo "\n====操作目录:${dir}====时间:`date "+%Y-%m-%d %T"`====\n"

    #判断筛选字段是否为空
    if [[ -z $feild ]];then
        choosefeild
    fi

    #判断匹配值是否为空
    if [[ -z $feildValue ]];then
       #执行循环输入
       inputValue
       #赋值操作
       feildValue=${p}
    fi
    echo "=========匹配字段值：${feildValue}=========\n"
    #处理查询
    dealCheck
}

#循环输入直到有值为止
inputValue(){
    echo "\n=========请输入值=========\n"
    read p
    if [[ -z $p ]]; then
        inputValue
    fi
}
#字符串拆分数组
cutStr(){
    str="x_y_z"
    ## 定义空数组
    arr=()

    ## 将str变量拆开分别添加到数组变量arr
    line=($(echo ${str} | sed 's/_/ /g'))
    for i in ${line[*]}
    do
        arr[${#arr[*]}]=${i}
    done
    echo 数组变量arr的值为:"${arr[*]}"
}
#选择筛选字段
choosefeild(){
    echo "=========请选择匹配字段========="

    select item in ${check[@]}; do
    
    case $item in
        "all")
            feild=""
            #遍历删除多个元素
            delete=("BundleId" "all")
            for del in ${delete[@]}
            do
               check=( ${check[*]/$del} )
            done
            #删除单个元素
            #check=( ${check[*]/all} )
            break;;
        "BundleId")
            feild="application-identifier"
            break;;
        *)
            feild=${item}
        break;;
        esac
     done
     
    echo "===匹配字段：${feild}===";
    echo "===check数组个数：【${#check[*]}】 元素：${check[*]}===";
}

#脚本启动入口init
init
