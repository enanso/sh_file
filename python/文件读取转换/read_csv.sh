#!/bin/bash
#当前所在路径
curPath=$(cd `dirname $0`; pwd)
#当前文件名
dirname="${curPath##*/}"

#csv文件路径
SYNC_TABLE_NAMES="${curPath}/file.csv"


#awk -F "\"*,\"*" '{
#    {if(length($1)>0) print($1" "$3" "$2" "$4)}
#} ' $SYNC_TABLE_NAMES | awk 'NR>0'

#echo "=====第一种方法====="
#for line in `cat $SYNC_TABLE_NAMES  | awk 'NR>1'`
#do
#  echo $line
#done

check=("module" "startTag" "endTag" "branchName")
while read table
do
    str=$table
    OLD_IFS="$IFS" #保存旧的分隔符
    IFS="," #逗号分割数组（csv文件格式特性）
    array=($str)
    IFS="$OLD_IFS" #将IFS恢复成原来的
    
    echo "\n=====开始=====\n"
    for ((i=0;i<${#array[@]};i++))
    do
        #遍历取值
        value=${array[$i]}
        #判断是否为查询的key
        res=$(echo "${check[@]}" | grep -wq "${value}" &&  echo "yes" || echo "no")
        if [ "${res}" == "yes" ];then
           #终止当前遍历
           break
        fi

        if [ $i == 0 ];then
            echo "module: ${value}"
        elif [ $i == 1 ];then
            echo "startTag: ${value}"
        elif [ $i == 2 ];then
            echo "endTag: ${value}"
        elif [ $i == 3 ];then
            echo "branchName: ${value}"
        else
            echo "other: ${value}"
        fi
    done

#    #构建JSON格式对象
#    printf "{\n"
#    printf '\t"data":[\n'
#    for ((i=0;i<${#array[@]};i++))
#    do
#        printf '\t\t{\n'
#        if [ $i == 0 ];then
#            printf "\t\t\t\"module\":\"${array[$i]}\"}\n"
#        elif [ $i == 1 ];then
#            printf "\t\t\t\"startTag\":\"${array[$i]}\"}\n"
#        elif [ $i == 2 ];then
#            printf "\t\t\t\"endTag\":\"${array[$i]}\"}\n"
#        elif [ $i == 3 ];then
#            printf "\t\t\t\"branchName\":\"${array[$i]}\"}\n"
#        else
#            printf "\t\t\t\"other\":\"${array[$i]}\"},\n"
#        fi
#    done
#    printf "\t]\n"
#    printf "}\n"

done < $SYNC_TABLE_NAMES | awk 'NR>2'

exit
