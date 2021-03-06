##!/bin/bash
#
##----------------------date时间转换成数字字符串----------------------
## 用例：sh date2timestamp.sh '2017-10-13 14:38:30'
## 作者：JABase
##----------------------------------------------------------
#

function usage(){
    echo "-h --help \n" \
         "  将本地时间转换为13位时间戳(毫秒时间戳) \n"\
         "  只有1个参数:本地时间，参数格式：'%Y-%m-%d %H:%M:%S' \n"\
         "  默认值：当前时间向后5min \n"\
         "  e.g. 2017-01-01 16:00:00 \n"
    exit 1
}

##时间采用正则匹配
time_pattern="^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2} [0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2}"
os_platform=`uname -s`

if [[ $# -le 0 ]]; then
    echo "默认按照当前时间向后5min取值"
    if [[ "${os_platform}" = "Darwin" ]];then
        echo `date -v+5M +%s`000
    elif [[ "${os_platform}" = "Linux" ]];then
        echo `date -d +5min +%s`000
    fi
else
    case $1 in
      -h|--help)
          usage
      ;;
      *)
          dateStr=${1}
          echo 传参时间:${dateStr}
          if [[ "${dateStr}" =~ ${time_pattern} ]];then
              if [[ "${os_platform}" = "Darwin" ]];then
                  echo `date -j -f "%Y-%m-%d %H:%M:%S" "${dateStr}" +%s`000
              elif [[ "${os_platform}" = "Linux" ]];then
                  echo `date -d "${dateStr}" +%s`000
              fi
          else
              echo "时间格式不正确，请按照'%Y-%m-%d %H:%M:%S'格式输入，如'2017-01-01 16:00:00' "
          fi
      ;;
    esac
fi
