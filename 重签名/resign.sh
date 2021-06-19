#!/bin/bash
#----------------------应用重签名----------------------
# 作者 ：JABase
#----------------------------------------------------
#重签名别人ipa：https://www.jianshu.com/p/ecba455911db
#https://blog.csdn.net/qq_36366758/article/details/102744715
#https://blog.csdn.net/HeroRazor/article/details/80351171

#Config Color
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No Color

##描述文件所在文件夹路径 (手动设置文件夹)
dir="${HOME}/Desktop/Provisioning Profiles/"
#目标描述文件路径
aimfilepath=""

#所有描述文件列表
filelist=`ls "${dir}"`
#描述文件删除匹配字段 (默认匹配Bundle Id，可手动填入配置（为空时，下方会提示选择处理）)
feild="application-identifier"
#删除匹配字段对应的值,【可手动填入配置（为空时，下方会提示输入）】
feildValue="com.zhihundaohe.WLDS"

#可匹配查询字段集合（可根据描述文件中的可匹配字段自行增加选项）
check=("AppIDName" "UUID" "application-identifier" "com.apple.developer.team-identifier" "TeamName" "BundleId" "all")

# 临时将xxx.mobileprovision转换成plist文件路径
temp_plist_path="./temp_profile.plist"

# 描述文件上传类型develepment、ad-hoc、appstore、enterprise
filetype="appstore"

# 持续创建文件目录
createfolder(){
    if [ ! -d "$1" ];then
        mkdir $1
    else
        rm -rf $1
    fi
    # 判断如果不是文件目录，删除持续创建
    if [ ! -d "$1" ];then
        rm $1
        createfolder "$1"
    fi
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
# 判断证书类型
findtype(){

  # 读取文件
  readfile "$1" "$2"

  #ad-hoc、debug独有
  ProvisionedDevices=$(/usr/libexec/PlistBuddy -c "print ProvisionedDevices" $temp_plist_path)
  ProvisionedDevices_txt_len=${#ProvisionedDevices}
  if [ $ProvisionedDevices_txt_len -gt 0 ]; then
    # echo "debug --- adhoc"
      get_task_allow=$(/usr/libexec/PlistBuddy -c "print Entitlements:get-task-allow" $temp_plist_path)
      if [ $get_task_allow == "false" ]; then
          echo "ad-hoc"
          return 1
      else
        echo "develepment"
        return 2
      fi
  else
      #enterprise 独有
      ProvisionsAllDevices=$(/usr/libexec/PlistBuddy -c "print ProvisionsAllDevices" $temp_plist_path)
      ProvisionsAllDevices_txt_len=${#ProvisionsAllDevices}
      # echo "enterprise --appstore"
      #true=4 false=5
      if [ $ProvisionsAllDevices_txt_len -gt 0 -a $ProvisionsAllDevices_txt_len == 4 ]; then
          echo "enterprise"
          return 3
      else
        echo "appstore"
        return 4
      fi
  fi
}
# 时间格式处理
formattime(){
    #过期时间格式处理用" "替换掉”T“，并删除所有的大写英文字符（详细sed指令语法）
    echo `echo "${1/T/ }" | sed 's/[A-Z]*//g'`
}

#处理查询（使用egrep正则匹配）
dealCheck(){

    if [ "$(emptyfilepath "$dir")" = "" ];then
       echo "\n==== 操作目录不存在:${RED}${dir}${NC} ="
       return
    fi
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
    echo "========= 匹配字段值：${RED}${feildValue}${NC} =========\n"
    
    # 定义记录符合筛选条件的数组
    filtrate_arr=()
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
        
        #描述文件过期时间
        ExDate=$(formattime `egrep -a -A 2 ExpirationDate "${PROFILE_FILE}" | grep date | sed -e 's/<date>//' -e 's/<\/date>//'`)
        # 当前时间
        nowDate=$(date "+%Y-%m-%d %H:%M:%S")
        t1=`date -j -f "%Y-%m-%d %H:%M:%S" "${nowDate}" "+%s"`
        t2=`date -j -f "%Y-%m-%d %H:%M:%S" "$ExDate" "+%s"`
        # 过期时间比较（当前时间大于或等于过期时间，即视为过期）
        if [ $t1 -gt $t2 ] || [ $t1 -eq $t2 ]; then
                #描述文件创建时间
                CreDate=$(formattime `egrep -a -A 2 CreationDate "${PROFILE_FILE}" | grep date | sed -e 's/<date>//' -e 's/<\/date>//'`)
                echo "当前:$nowDate 大于 过期:$ExDate 文件已过期：${filename} 名称：${Name} 创建:$CreDate"
                exdate_arr[${#exdate_arr[*]}]="${PROFILE_FILE}"
                #自动删除过期描述文件
                rm "${PROFILE_FILE}"
            else
                # 筛选Id
                IdentifierPrefix=`egrep -a -A 2 application-identifier "${PROFILE_FILE}" | grep string | sed -e 's/<string>//' -e 's/<\/string>//' -e 's/ //'`
                #第一次出现小数点时截取，作为BundleId
                BundleId=${IdentifierPrefix#*.}

                if [ ${BundleId} == ${feildValue} ] && [ ${feildValue} != "" ]
                then
                   # 记录符合查询结果数据
                   filtrate_arr[${#filtrate_arr[*]}]="${PROFILE_FILE}"
                fi
        fi
    done

    echo "\n==描述文件：${count}个 ==筛选：${#filtrate_arr[*]}个 ==过期：${#exdate_arr[*]}个\n"

    # 遍历筛选结果
    for(( i=0;i<${#filtrate_arr[@]};i++)) do
        # 读取数组元素
        element=${filtrate_arr[i]}
        echo "===${GREEN}筛选出的：${element}${NC}"
        # 描述文件类型
        cre_time=$(getcreatetime "$element")
        Type=$(findtype "${element}")
        if [[ $Type == "develepment" ]]; then
            dev_path=$(deletedoublefile "${element}" "${dev_path}")
        elif [[ $Type == "ad-hoc" ]]; then
            hoc_path=$(deletedoublefile "${element}" "${hoc_path}")
        elif [[ $Type == "appstore" ]]; then
            aps_path=$(deletedoublefile "${element}" "${aps_path}")
        elif [[ $Type == "enterprise" ]]; then
            ep_path=$(deletedoublefile "${element}" "${ep_path}")
        fi
    done;
    
    if [[ ! -z $filetype ]];then
       case $filetype in
        "ad-hoc")
        # 拷贝描述文件
        copyfile "$hoc_path" "./"
        aimfilepath=${hoc_path##*/}
            break;;
        "appstore")
        # 拷贝描述文件
        copyfile "$aps_path" "./"
        aimfilepath=${aps_path##*/}
            break;;
        # 拷贝描述文件
        "enterprise")
        copyfile "$ep_path" "./"
        aimfilepath=${ep_path##*/}
            break;;
        *)
        # 拷贝描述文件
        copyfile "$dev_path" "./"
        aimfilepath=${dev_path##*/}
        break;;
        esac
    fi
    echo "${GREEN}
    \n===保留: ${filetype}===描述文件: ${aimfilepath}\n"
}

# 判断描述文件是否过期
isxpiration(){
    if [[ ! -z "$1" ]];then
        #描述文件过期时间
        get_ex_date=$(formattime `egrep -a -A 2 ExpirationDate "${1}" | grep date | sed -e 's/<date>//' -e 's/<\/date>//'`)
        # 当前时间
        get_now_date=$(date "+%Y-%m-%d %H:%M:%S")
        t1=`date -j -f "%Y-%m-%d %H:%M:%S" "${get_now_date}" "+%s"`
        t2=`date -j -f "%Y-%m-%d %H:%M:%S" "$get_ex_date" "+%s"`
        # 过期时间比较（当前时间大于或等于过期时间，即视为过期）
        if [ $t1 -gt $t2 ] || [ $t1 -eq $t2 ]; then
           echo "YES"
        fi
    fi
}
# 文件拷贝（$1为目标文件，$2为目标目录）
copyfile(){
    if [[ ! -z "$1" ]]&&[[ ! -z "$2" ]];then
        cp "$1" "$2"
    fi
}
# 删除重复的描述文件，只留一个
deletedoublefile(){
    if [[ ! -z $1 ]]&&[[ ! -z $2 ]];then
        # 读取创建时间，保留最新创建的文件
        t1=`date -j -f "%Y-%m-%d %H:%M:%S" "$(getcreatetime "$1")" "+%s"`
        t2=`date -j -f "%Y-%m-%d %H:%M:%S" "$(getcreatetime "$2")" "+%s"`
        # 时间比较
        if [ $t1 -gt $t2 ] || [ $t1 -eq $t2 ]; then
            #移除
            rm "$2"
            echo "$1"
        else
            #移除
            rm "$1"
            echo "$2"
        fi
    else
        if [[ ! -z $1 ]];then
            echo "$1"
        elif [[ ! -z $2 ]];then
            echo "$2"
        else
            echo ""
        fi
    fi
}
# 读取文件的创建时间
getcreatetime(){
    echo "$(formattime `egrep -a -A 2 CreationDate "$1" | grep date | sed -e 's/<date>//' -e 's/<\/date>//'`)"
}

# 查找当前文件夹文件
findfile(){
    aim_temp=""
    number=0
    for file in $(ls ./)
    do
        if [ "${file##*.}" = "$1" ]; then
            #        mv ${file} ${file%.*}.sh
            aim_temp=${file}
            let number++
        fi
    done
    if [[ ${number} = 1 ]];then
        echo "${aim_temp}"
    else
        echo "no"
    fi
}
#初始化
init(){

    ipafile=$(findfile "ipa")
    if [ "${ipafile}" = "no" ]; then
        echo "===${RED}请保留一个ipa文件${NC}==="
        return
    fi
    
    # 判断是否为描述文件
    if [ "${aimfilepath##*.}" != "mobileprovision" ];then
        # 置为空
        aimfilepath=$(findfile "mobileprovision")
        if [ "${aimfilepath}" = "no" ]; then
            echo "===${RED}请保留一个描述文件${NC}==="
            return
        fi
    fi
    # 判断描述文件在不在
    if [ ! -f "$aimfilepath" ]; then
        #处理查询
        dealCheck
    fi
    
    # 判断描述文件是否已过期
    if [ "$(isxpiration "$aimfilepath")" = "YES" ];then
        echo "===${RED}描述文件已过期${NC}==="
        return
    fi

    # 清除临时文件
    if [ -f "$temp_plist_path" ];then
       rm -f $temp_plist_path
    fi
    # 读取并生成到本都
    TeamName=$(readfile "$aimfilepath" "TeamName")

    echo "========${RED}拷贝${GREEN}【${TeamName}】${RED}证书下的十六进制字符串填充${GREEN} Signing Identity: ${NC}========"
#    fastlane sigh resign

#    keychaininfo
}

# 钥匙串中的证书薪资
keychaininfo(){

    #https://www.cnblogs.com/meitian/p/7764420.html
    keychain="${HOME}/Library/Keychains/login.keychain"
    identities="Apple Distribution: XXXX Co., Ltd. (PHSNY7Y3VJA)"

    pem_path="./certs2.pem"
    #直接查找证书导并出为pem文件：grep筛选条件
    # # # # # # # # # # # # # # # # # # #
    # -a: 全部的证书
    # -c: 过滤关键词 iPhone
    # -p: 以pem格式输出
    # # # # # # # # # # # # # # # # # # #
    #方法一:后面可拼接筛选条件（  | grep "Subject:"）
    security find-certificate -a -c "${identities}" -p | openssl x509 -text
    #方法二:
#    security find-certificate -a -c "${identities}" -p > "${pem_path}"
#    # 输出证书过期时间-dates（具体信息-text）
#    openssl x509 -in "${pem_path}" -noout -text

#    echo "==证书信息：$(security find-identity -p codesigning)"

    #方法三:（导出p12文件后转pem后读取证书信息）
#    p_file="./temp.p12"
#    p_pw=""
#    #指定导出证书导出p12文件（-P为密码设置）
#    security export -f pkcs12 -k  "${keychain}" -o "${p_file}" -P "${p_pw}" -t identities "${identities}"
#    openssl pkcs12 -clcerts -nokeys -in "${p_file}" -out "${pem_path}"  -passin pass:"${p_pw}"
#    # 输出证书过期时间-dates（具体信息-text）
#    openssl x509 -in "${pem_path}" -noout -text
}
# 判断文件夹是否为空
emptyfilepath(){
    if [ "`ls -A "$1"`" = "" ];then
       echo ""
    else
      echo "$1"
    fi
}
# 打开非空文件夹
opennonempty(){
    if [ "$(emptyfilepath "$1")" != "" ];then
       open "$1"
    fi
}
#循环输入直到有值为止
inputValue(){
    echo "\n=========请输入值=========\n"
    read p
    if [[ -z $p ]]; then
        inputValue
    fi
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
init $1
