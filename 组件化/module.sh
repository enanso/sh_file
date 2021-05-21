#!/bin/bash
#----------------------iOS读取git管理代码库信息----------------------
#
#  1.主工程（组件的壳工程）文件目录与各组件库目录放于同一文件夹 ( project )下
#
#  2.手动设置文件夹路径, 就可以手动拖拽文件夹替换dir的值
#       例：dir="${HOME}/project/"
#
#  3.需求跌更新业务组件时，主工程分支、各组件分支命名同一标准构造成相同关键字前缀：
#       例：主工程分支 branch/fileChange
#        组件A分支    branch/fileChange_tag
#        组件B分支    branch/fileChange_tag1
#        此时构建出公用前缀：branch/fileChange
#
#  4.设置匹配关键词：match_Value="branch/fileChange"
#
#  5.执行脚本，筛选出本地拉出的同期需求修改组件
#
#  6.根据需要和个人习惯可自行修改内容
#
#----------------------------------------------------------

SPACE="=====  "
R_SPACE="  ====="
LINE="============================================================"
#Config Color
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No Color

#手动设置文件夹路径
dir="${HOME}/project/"

#所有描述文件列表
filelist=`ls "${dir}"`

#设置匹配值,【可手动填入配置（为空时，下方会提示输入）】
match_Value="project/ZhongHuaPortModule"
#match_Value=""

##替换podspec的Tag
#updatePodspec() {
#    echo -e "${GREEN}\n第二步：修改 s.version = ${tag} ${NC}⏰⏰⏰"
#    sed -i '' s/"s.version[[:space:]]*=[[:space:]]*\'[0-9a-zA-Z.]*\'"/"s.version = \'${tag}\'"/g ${SpecName}
#        FILE="${PROFILE_FILE}/${filename}.podspec"
#        echo "===文件$FILE"
#        sed -n "/s.version/p" FILE
#        sed -n '' s/"s.version[[:space:]]*=[[:space:]]*\'[0-9a-zA-Z.]*\'"/"s.version = \'${tag}\'"/g ${SpecName}
        #sed -i '' s/"s.version[[:space:]]*=[[:space:]]*\'[0-9a-zA-Z.]*\'"/"s.version = \'${tag}\'"/g ${SpecName}
#}


#查询文件
checkFile(){
    #文件总数量
    count=0
    #匹配文件集合
    changeArr=()
    
    echo ${LINE}
    echo "\n${SPACE}开始读取本地文件文件${R_SPACE}\n"

    #遍历文件夹
    for filename in $filelist
        do
        #主工程(IOS)和flutter编译配置文件不参与读取输出
        if [ ${filename} == "IOS" ]||[ ${filename} == "flutter" ];then
           continue
        fi
        #数量自增
        let count++

        #文件路径
        PROFILE_FILE="${dir}${filename}"

        #打开文件夹路径
        cd $PROFILE_FILE

#       清理本地无效分支git命令(远程已删除本地没删除的分支): git fetch -p

#########===============================获取当前分支名===============================

        current_branch=$(git rev-parse --abbrev-ref HEAD)
        #当前分支开头匹配及判断为同一个迭代修改
        if [[ $current_branch == $match_Value* ]]&&[ ${match_Value} != "" ];then
                #记录添加变化文件名称
                changeArr[${#changeArr[@]}]=${filename}
                check_branch=$current_branch
            else
                #模糊查询分支
                check_branch=$(git branch | grep ${match_Value})
                if [ "$check_branch" != "" ];then
                    #记录添加变化文件名称
                    changeArr[${#changeArr[@]}]=${filename}
                    echo "\n${RED}${SPACE}本地文件:【 ${filename} 需要切换分支:${check_branch} 】${NC}\n"
                fi
        fi

#########===============================查询到结果后判断===============================

        if [ "$check_branch" != "" ];then
            #判断是否存在英文字符和小数点数字（tag）
            if echo "${check_branch}"|grep "[a-zA-Z]" >/dev/null && echo "${check_branch}"|grep "[0-99]\.[0-99]\.[0-99]" >/dev/null
            then
            #以"_"截取保留右侧的值为tag
            tag=${check_branch#*_}
            echo "${SPACE}【${filename}】${GREEN}${tag}${NC} 分支: ${check_branch}\n"
            else
            echo "${SPACE}${RED}【${filename}】分支: ${check_branch}${NC}\n"
            fi
        fi

#########===============================直接筛选值匹配查询===============================

#        if [ ${match_Value} != "" ];then
#            #模糊查询分支
#            check_branch=$(git branch | grep ${match_Value})
#            if [ "$check_branch" != "" ];then
#                #记录添加变化文件名称
#                changeArr[${#changeArr[@]}]=${filename}
#                echo "\n==文件:【 ${filename} 分支:${check_branch} 】\n"
#            fi
#        fi

#########===============================分支其他信息延伸===============================

#        echo "\n\n=================== 分支:${current_branch} ==================="
#        #HEAD提交的SHA1值
#        commit_seql=$(git rev-parse HEAD)
#        echo "\n==SHA1值: ${commit_seql}"
#        #HEAD提交的SHA1值(简写的)
#        commit_seq=$(git rev-parse --short HEAD)
#        echo "\n==SHA1(简写的)值: ${commit_seq}"
#        #倒序显示所有版本号
#        commit_cnt=$(git rev-list --all --count)
#        echo "\n==所有版本号: ${commit_cnt}"
#        提交日志
#        git_log=$(git log)
#        echo "\n==提交日志: ${git_log}"
#        获取所有分支名
#        branchs=$(git branch)
#        echo "\n==所有分支名称: ${branch}"
        done
        
    echo ${LINE}
    echo "\n${SPACE}本地文件数量：【${count}】\n"
    echo "${SPACE}匹配文件数量：【${#changeArr[*]}】\n";
    echo "${SPACE}匹配文件名称：${changeArr[*]}\n";
}
#初始化
init(){

    echo "\n${SPACE}操作文件目录: ${dir} 时间: `date "+%Y-%m-%d %T"`${R_SPACE}\n"
    #判断匹配值是否为空
    if [[ -z $match_Value ]];then
       #执行循环输入
       inputValue
       #赋值操作
       match_Value=${p}
    fi
    echo "${SPACE}匹配字段值：${match_Value}${R_SPACE}\n"
    #处理查询文件
    checkFile
}

#循环输入直到有值为止
inputValue(){
    echo "\n${SPACE}请输入值${R_SPACE}\n"
    read p
    if [[ -z $p ]]; then
        inputValue
    fi
}
#脚本启动入口init
init
