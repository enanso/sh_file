#!/bin/bash
#----------------------下载远程库指定文件或指定路径下的文件----------------------
# 功能1：通过文件名称匹配下载（文件名后缀需要输入或者配置填写）
# 功能2：通配符查找指定文件夹下的文件（文件夹目录与文件名称后缀需要填写或配置）
# 参数：$1为文件名、$2为是否删除临时存储文件夹
# 外部调用示例：
#         1.标准：sh download.sh "项目维护/project.xls" true
#         2.内置文件名（true为删除）：sh download.sh true
# 作者 ：JABase
#----------------------------------------------------------

SPACE="=============="
#Config Color
RED="${SPACE}\033[0;31m"
GREEN="${SPACE}\033[0;32m"
NC="\033[0m" # No Color

#工程绝对路径
project_path=$(cd `dirname $0`; pwd)
echo "===当前路径：$project_path"
#添加梯子加速器环境变量
#export https_proxy=http://127.0.0.1:3850 http_proxy=http://127.0.0.1:3850 all_proxy=socks5://127.0.0.1:3850

# 是否需要拷贝
ISCOPY=true
# 下载后的文件文件夹名称或者文件夹路径
#filePath="~/Desktop/File/Repo"
filePath="File"
# 匹配到的文件
sub_file="其他脚本/file.txt"
# 远程库地址
remote_url="https://github.com/enanso/sh_file.git"

# 循环输入直到有值为止
inputValue(){
    read -p "请输入【$1】:" word
    if [[ -z $word ]]; then
        inputValue "$1"
    fi
}

# 执行脚本($1为文件名、$2为是否删除文件夹)
start(){
    #文件路径
    if [[ -z $filePath ]];then
       #执行循环输入
       inputValue "文件夹路径或名称"
       #赋值操作
       filePath=${word}
    fi

    # 判断是否以"/"开头的文件夹
    if [[ $filePath == /* ]] && [[ $filePath != "${HOME}"* ]];then
        if [ ! -d $filePath ];then
            filePath=$project_path$filePath
        fi
    fi

    # 判断是否以"~"开头的文件夹
    if [[ $filePath == ~* ]];then
        filePath=${HOME}${filePath: 1}
    fi


    # 存在两位参数时满足赋值文件名操作
    if [[ ! -z $1 ]] && [[ ! -z $2 ]];then
        sub_file=$1
    fi

    #查找文件
    if [[ -z $sub_file ]];then
       #执行循环输入
       inputValue "*/File/b1.jpeg 或 b1.jpeg 或 File "
       #赋值操作
       sub_file=${word}
    fi

    #查找文件
    if [[ -z $remote_url ]];then
       #执行循环输入
       inputValue "远程库地址"
       #赋值操作
       remote_url=${word}
    fi

    if [ -d ./${filePath} ];then
    
        if [[ $2 == true ]];then
           rm -rf $filePath
        else
            echo "${RED}${filePath}文件夹已存在，是否删除[ 1:是 其他:否] ${NC}${SPACE} "
            ##
            read result
            if [ ${result} == "1" ];then
                # 删除文件目录
                # sudo(直接删除整个目录,需输入管理员密码)
                # sudo rm -r -f $filePath
                # 递归删除目录下的所有文件
                rm -rf $filePath
                else
                time_now=$(date "+%Y.%m.%d+%H-%M-%S")
                filePath="$filePath/$time_now"
            fi
        fi
    fi

    # 创建本地空repo
    git init ${filePath} && cd ${filePath}
    #git init
    git remote add origin ${remote_url}
    # 设置允许git克隆子目录
    git config core.sparsecheckout true
    # 设置要克隆的仓库的子目录路径, “*” 是通配符，“!” 是反选
    #找出指定文件夹下的文件：*/文件/b1.jpeg
    #找出所有的文件：b1.jpeg
    echo "${sub_file}" >> .git/info/sparse-checkout
    #    echo official/resnet/* >> .git/info/sparse-checkout
    #    # 如果需要添加目录，就增加sparse-checkout的配置，再checkout master
    #    # echo another_folder >> .git/info/sparse-checkout
    # 用 pull 来拉取代码
    git pull origin master
    
    # 目标文件名称
    file_name=$(read_filename $sub_file)
    
    # 文件路径
    dir=$filePath
    
    if [[ $filePath != /* ]]&&[[ $filePath != ~/* ]];then
         dir=$project_path/$filePath
    fi
    
    if [[ $ISCOPY == true ]];then
        # 调用函数，并传参3位数($1文件目录、$2查询文件名称)
        read_dir $dir $file_name
    else
        echo "${GREEN}文件夹，是否拷贝到当前目录下[ 1:是 其他:否] ${NC}${SPACE} ${dir} "
        ##
        read result
        if [ ${result} == "1" ];then
            # 调用函数，并传参3位数($1文件目录、$2查询文件名称)
            read_dir $dir $file_name
        fi
    fi
            
    # 外部传参自动删除文件夹
    if [[ $2 == true ]] || ([[  -z $2 ]] && [[ $1 == true ]]);then
       rm -rf $dir
       echo "${RED}移除目录：$dir${NC}"
    fi
}

# 读取文件夹名称
read_filename(){
    # 目标文件名称
    filename=$(basename $1)
    echo $filename
}

# 递归读取所有文件目录
read_dir(){

    #注意此处这是两个反引号，表示运行系统命令
    for file in `ls -a $1`
    do
        #注意此处之间一定要加上空格，否则会报错
        if [ -d $1"/"$file ]
        then
            if [[ $file != '.' && $file != '..' ]]
            then
                read_dir $1"/"$file $2
            fi
        else
            #此处处理文件即可
            aim_path=$1"/"$file
            #查找目标文件
            if [[ $2 == $file ]];then
               echo 文件源路径：$aim_path
               # 拷贝文件到指定目录下
               cp $aim_path $project_path
               echo 拷贝后路径：$project_path/$2
               open $project_path
               break
            fi
        fi
    done
}

# 开始执行($1为文件名、$2为是否删除文件夹)
start $1 $2
