#!/bin/bash
#----------------------越狱手机连接SSH服务----------------------
# 功能1：连接SSH服务
# 功能2：自动创建rsa钥匙对儿
# 作者 ：JABase
#-----------------------------------------------------------------------

SPACE="======"
#Config Color
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No Color

# # # # # # # # # # # # # # # # # # # # # # # # # # #
# ================== 终端指令参考 =========================
# 当前路径：pwd
# 进程列表：ps -A
# 筛选进程：ps -A | grep
# iFunbox显示手机目录工具（AFC 2 完美越狱）
# # # # # # # # # # # # # # # # # # # # # # # # # # #

#脚本读取USB连接设备信息：https://www.jianshu.com/p/0f6725071ba8

# 当前文件目录
dir=$(cd `dirname $0`; pwd)

# iPhone连接网络的IP地址
IPHONE_LOCAL_IP="10.0..246"

# SSH【secure shell】登录密码（默认值）
ALPINE="alpine"

# 循环输入直到有值为止
function inputValue(){
    read -p "请输入【$1】: " word
    if [[ -z $word ]]; then
        inputValue "$1"
    fi
}

# 是否包含某文件
function hasfile(){
    
    if [[ ! -z $1 ]]&&[[ ! -z $2 ]]; then
        
        folder=$2
        # 文件夹更换家目录
        if [[ $folder == "~/"* ]];then
            folder=${HOME}${folder:1}
        fi
        for file in `ls -a ${folder}`
        do
            if [ "${file}" = "$1" ]; then
                echo "YES"
                break
            fi
        done
    fi
}

# 读取目录下的文件
function read_dir(){
    folder_path=$1
    # 文件夹更换家目录
    if [[ $folder_path == "~/"* ]];then
        folder_path=${HOME}${folder_path:1}
    fi

    # 遍历文件夹
    for file in `ls ${folder_path}` #反引号，表示运行系统命令
    do
        if [[ -d $1"/"$file ]];then #注意此处之间一定要加上空格，否则会报错
            # 递归读取
            read_dir $1"/"$file
        else
            echo "========= ${GREEN}存在文件：$1/$file${NC}"
            if [[ -n $2 ]];then
                # 查看文件
                cat $file
            fi
        fi
    done
}
# 脚本主入口
function entrance(){
    if [[ -n $1 ]];then
        IPHONE_LOCAL_IP=$1
    fi

    if [[ -z $IPHONE_LOCAL_IP ]];then
       #执行循环输入
       inputValue "手机连接网络IP地址"
       #赋值操作
       IPHONE_LOCAL_IP=${word}
    fi
    
    if [[ -z $IPHONE_LOCAL_IP ]];then
        echo "====== 请设置iPhone手机网络连接IP地址 ${NC}======"
        return
    else
        echo "====== ${GREEN} iPhone连接IP地址: ${IPHONE_LOCAL_IP} ${NC}======"
    fi
    
    # 进入.ssh目录下
    cd ~/.ssh

    # 判断是否存在id_rsa（钥匙对是否已经存在）
    if [[ -n $(hasfile "id_rsa" "~/.ssh") ]];then
        #遍历文件夹，$1为文件夹路径，$2输入任意值，可直接在终端输入文件内容
        read_dir "~/.ssh"
        else
        echo "===${RED} 当前没有私钥${NC}"
        # 1. 生成私钥(ssh-keygen -t rsa -C "your.email@example.com" 可省略直接使用ssh-keygen，密码可以自定义或者直接回车)
        echo "\n======${GREEN} ‘Enter file in which to save the key (${HOME}/.ssh/id_rsa):’${NC}直接回车，生成id_rsa文件，输入会生成私钥xxx和公钥xxx.pub"
        echo "\n======${GREEN} ‘Enter passphrase (empty for no passphrase):直接回车表示无密码生成rsa文件’${NC}"
        ssh-keygen
        # 2 .查看本地私钥
        cat id_rsa
        
        # 3. 清除旧的公钥信息
        #ssh-keygen -R "$IPHONE_LOCAL_IP"

        # 3.1 自动创建拷贝id_rsa.pub给SSH服务器
        # ssh-copy-id root@"$IPHONE_LOCAL_IP"
    
        # 3.1 将id_rsa.pub中的内容拷贝到 authorized_keys中
        cat id_rsa.pub >> authorized_keys
        
        # 设置authorized_keys权限
        chmod 600 authorized_keys
        # 设置.ssh目录权限
        chmod 700 -R .ssh
    fi
        
    echo "\n================== ${GREEN}已存在远程服务主机${NC} ==================\n"
    # 读取已经存在远程主机配置
    cat "${HOME}/.ssh/known_hosts"
    
        # 命令执行失败
    echo "\n======${RED} 1.如果出现'root@$IPHONE_LOCAL_IP: Permission denied (publickey,password,keyboard-interactive)'，非完美越狱设备建议重新刷机越狱${NC}"
    echo "======${RED} 2.如果出现'ssh: connect to host $IPHONE_LOCAL_IP port 22: Operation timed out'，请检查手机和Mac是否处于同一网络环境中${NC}"
        
    echo "\n======${RED} 连接成功后，输入exit或者ctrl+D退出登录(logout)${NC}"
    echo "======${RED} 待出现'root@$IPHONE_LOCAL_IP's password:'后，输入ssh默认登录password：${GREEN}${ALPINE}${NC}"
    # 链接手机
    ssh root@"$IPHONE_LOCAL_IP"
#    # 判断指定是否出错
#    if [ $? -ne 0 ]; then
#
#    fi

}

# 脚本启动入口
entrance $1
