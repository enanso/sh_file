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

echo "=====第二种方法====="
while read table
do
    str=$table
    OLD_IFS="$IFS" #保存旧的分隔符
    IFS="," #逗号分割数组
    array=($str)
    IFS="$OLD_IFS" #将IFS恢复成原来的
    
    #编码能力分割结果
    for i in "${!array[@]}"; do
        echo "$i=>${array[i]}"

#        if [ $i == 0 ];then
#        printf "module":"${array[$i]}"
#        elif [ $i == 1 ];then
#        printf "startTag":"${array[$i]}"
#        elif [ $i == 2 ];then
#        printf "endTag":"${array[$i]}"
#        elif [ $i == 3 ];then
#        printf "branchName":"${array[$i]}"
#        else
#        printf "other":"${array[$i]}"
#        fi
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
