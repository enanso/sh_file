#!/bin/bash
#----------------------删除iOS描述文件mobileprovision----------------------
# 功能1：删除iOS本地存储的已经过期（设置是否允许删除）
# 功能2：删除iOS本地存储指定描述文件（通过字段匹配）
# 功能3：删除iOS本地存储多余描述文件，保留最新一个（keepLatest设置为true）
# 作者 ：JABase
#-----------------------------------------------------------------------

#https://blog.csdn.net/qq_36366758/article/details/102744715
#https://blog.csdn.net/HeroRazor/article/details/80351171

SPACE="======"
#Config Color
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No Color

#描述文件所在文件夹路径 (X-code默认为位置)
#dir="${HOME}/Library/MobileDevice/Provisioning Profiles/"

##描述文件所在文件夹路径 (手动设置文件夹)
dir="${HOME}/Desktop/Provisioning Profiles/"

#所有描述文件列表
filelist=`ls "${dir}"`

#描述文件删除匹配字段 (默认匹配Bundle Id)
#feild="application-identifier"
#描述文件删除匹配字段 (#可手动填入配置（为空时，下方会提示选择处理）)
feild="application-identifier"
#删除匹配字段对应的值,【可手动填入配置（为空时，下方会提示输入）】
feildValue="com.njxingong.qycloud"

#可匹配查询字段集合（可根据描述文件中的可匹配字段自行增加选项）
check=("AppIDName" "UUID" "application-identifier" "com.apple.developer.team-identifier" "TeamName" "BundleId" "all")

# 临时将xxx.mobileprovision转换成plist文件路径
temp_plist_path="./temp_profile.plist"

# 保存文件夹
save="${HOME}/Desktop/Profiles_Save"

# 已删除文件夹
discard="${HOME}/Desktop/Profiles_Discard"

# 是否保留最新版本描述文件(true为保存)
keepLatest="true"

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
                # 描述文件名称
                Name=$(readfile "${PROFILE_FILE}" "Name")
                #描述文件创建时间
                CreDate=$(formattime `egrep -a -A 2 CreationDate "${PROFILE_FILE}" | grep date | sed -e 's/<date>//' -e 's/<\/date>//'`)
                echo "当前:${nowDate} 大于 过期:${RED}${ExDate}${NC} 自动删除已过期文件：${filename} 名称：${GREEN}${Name}${NC} 创建于:${GREEN}$CreDate${NC}"
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

    echo "\n== 描述文件：${GREEN}${count}${NC} 个 == 筛选：${GREEN}${#filtrate_arr[*]}${NC} 个 == 过期：${GREEN}${#exdate_arr[*]}${NC} 个\n"
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
    
    # 拷贝
    copyfile "$dev_path" "$save"
    copyfile "$hoc_path" "$save"
    copyfile "$aps_path" "$save"
    copyfile "$ep_path" "$save"
    
    #打开文件夹
    opennonempty "$save"
    opennonempty "$discard"
    echo "${GREEN}
    \n===保留develepment：${dev_path}
    \n===保留ad-hoc：${hoc_path}
    \n===保留appstore：${aps_path}
    \n===保留enterprise：${ep_path}\n${NC}"
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
            # 拷贝
            copyfile "$2" "$discard"
            if [ $keepLatest == "true" ]; then
                #移除
                rm "$2"
            fi
            echo "$1"
        else
            # 拷贝
            copyfile "$1" "$discard"
            if [ $keepLatest == "true" ]; then
                #移除
                rm "$1"
            fi
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
#初始化
init(){
 
    echo "\n==== 当前目录:${RED}${dir}${NC} ====时间: `date "+%Y-%m-%d %T"` ====\n"
    
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
    
    # 创建保存文件夹
    save="$save/${feildValue}"
    createfolder "$save"

    # 创建删除文件夹
    discard="$discard/${feildValue}"
    createfolder "$discard"
    
    #处理查询
    dealCheck
    
    # 删除空目录
    if [ "`ls -A $save`" = "" ];then
       rm -r $save
    fi
    
    # 删除空目录discard
    if [ "`ls -A $discard`" = "" ];then
       rm -r $discard
    fi
    
    # 临时文件若存在，需清除
    if [ -f "$temp_plist_path" ];then
       rm -f $temp_plist_path
    fi
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
