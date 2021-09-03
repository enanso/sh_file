#!/bin/bash
#----------------------本地钥匙串证书过期提示----------------------
# 功能1：查看本地钥匙串中所有Apple证书过期时间，90内提示($1证书名称，只查一次)
# 功能2：证书自动导出pem及p12证书，默认设置密码为空（代码默认关闭）
# 作者 ：JABase
#----------------------------------------------------

#Config Color
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No Color

# 是否包含
function contains() {
    local n=$#
    local value=${!n}
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            echo "y"
            return 0
        fi
    }
    echo "n"
    return 1
}

# 时间月份字符替换
function replace(){
   # 月份时间表
   temp=("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
   
   for i in "${!temp[@]}"; do
    # 读取元素
    element=${temp[i]}
    # 删选符合证书格式字符串
    if [[ "$1" =~ $element ]];then
        num=`expr ${i} + 1`
        if [[ $num -gt 9 ]]; then
           echo "${1/$element/$num}"
        else
           # 个位补齐空格，否则格式报错
           echo " ${1/$element/$num}"
        fi
        # 结束遍历
        break
    fi
    done
}
# 启动函数
function init(){
    # 是否传参进来（筛选关键字，证书全称）
    if [[ ! -z "$1" ]]; then
        keychaincerinfo "$1"
        return
    fi
    # # # # # # # # # # # #
    #
    # 仅查看本地签名证书：security find-identity -p codesigning
    #
    # # # # # # # # # # # #
    
    # 查看本地所有证书，包括签名证书和推送证书信息
    CERS="$(security find-identity)"

    OLD_IFS="$IFS" # 保存旧的分隔符
    IFS="\"" # "分隔符
    array=($CERS)
    IFS="$OLD_IFS" # 将IFS恢复成原来的

    # 目标证书
    cer_arr=()

    for i in "${!array[@]}"; do
    # 读取元素
    element=${array[i]}
    # 删选符合证书格式字符串
    if [[ $element =~ "Apple" ]]||[[ $element =~ "iPhone" ]];then
        if [ $(contains "${cer_arr[@]}" "$element") != "y" ]; then
            cer_arr[${#cer_arr[*]}]=${element}
            # 读取证书信息
            keychaincerinfo "${element}"
        fi
    fi
    done
    echo "\n==== 本地证书数：${#cer_arr[@]}\n"
}

# 钥匙串中的证书信息
function keychaincerinfo(){

    # 是否传参进来（筛选关键字，证书全称）
    if [[ ! -z "$1" ]]; then
        identities="$1"
    else
        return
    fi

    #参考：https://www.cnblogs.com/meitian/p/7764420.html
    # 本地钥匙串路径
    keychain="${HOME}/Library/Keychains/login.keychain"

    # 本地存储的pem文件
    pem_path="./certs2.pem"
    rm -f $pem_path
    
#    #直接查找证书导并出为pem文件：grep筛选条件
#    # # # # # # # # # # # # # # # # # # #
#    #  security
#    #    -a: 全部的证书
#    #    -c: 过滤关键词 iPhone
#    #    -p: 以pem格式输出
#    #    > : 以pem格式输出的文件路径
#    #
#    #  openssl
#    #    -noout: 无其他输出
#    #    -dates: 输出过期时间
#    #    -text: 具体信息
#    # # # # # # # # # # # # # # # # # # #

    #方法一:后面可拼接筛选条件（  | grep "Subject:"）
    INFO=$(security find-certificate -a -c "${identities}" -p | openssl x509 -noout -dates)
    # 截取出证书过期时间
    EXP_DATE=$(replace "${INFO#*After=}")
    if [[ -z $EXP_DATE ]];then
    echo "====时间转换有误：$1"
       return
    fi
    # 过期时间转换成数字字符串
    t2=`date -j -f "%b %e %T %Y GMT" "${EXP_DATE}" "+%s"`
        
    # 当前时间
    nowDate=$(date -u '+%b %e %T %Y GMT')
    # 当前时间转换成数字字符串
    t1=`date -j -f "%b %e %T %Y GMT" "${nowDate}" "+%s"`

    # 计算时间差值
    diffValue=`expr $t2 - $t1`
    # 一天秒数计算
    oneDay=`expr 24 \* 60 \* 60` #<strong>必须在*前加\才能实现乘法,因为 * 有其它意义</strong>
    # 剩余过期天数`expr $diffValue / $oneDay + 1`
    ExpDays=`expr $diffValue / $oneDay`
    # 判断是否小于90天
    if [[ $ExpDays -lt "90" ]];then
        # # # # # # # # # # # # #
        # 拆分数组：
        # str="192.168.31.65"
        # array=(${str//\./ })
        # # # # # # # # # # # # #
        
        # 拆分后的时间数组
        TIME=(${EXP_DATE//\-/ })
        if [[ ${#TIME[@]} > 3 ]];then
           # 重构时间字符格式
           EXP_DATE="${TIME[3]}-${TIME[0]}-${TIME[1]} ${TIME[2]}"
        fi

       echo "\n==== 检测证书：${RED}${identities}${NC} ===="
       echo "     过期时间：${RED}${EXP_DATE}${NC} 剩余：${RED}${ExpDays}${NC} 天，请注意是否需要更换"
    fi

    # # # # # # # # # # # # # # # # # # #
    # # 等价方法一，本地会生成pem文件
    #  security find-certificate -a -c "${identities}" -p > "${pem_path}"
    #  # 输出证书过期时间-dates（具体信息-text）
    #  openssl x509 -in "${pem_path}" -noout -dates
    # # # # # # # # # # # # # # # # # # #

    #    #方法三:（导出p12文件后转pem后读取证书信息）
    #    p_file="./cer.p12" # 证书路径
    #    p_pw="" # 证书密码
    #    #指定导出证书导出p12文件（-P为密码设置）
    #    security export -f pkcs12 -k  "${keychain}" -o "${p_file}" -P "${p_pw}" -t identities "${identities}"
    #    openssl pkcs12 -clcerts -nokeys -in "${p_file}" -out "${pem_path}"  -passin pass:"${p_pw}"
    #    # 输出证书过期时间-dates（具体信息-text）
    #    openssl x509 -in "${pem_path}" -noout -dates
}

#脚本启动入口init （$1筛选关键字）
init $1
