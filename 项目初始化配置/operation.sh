#!/bin/bash
#
#--------------------------------------------
# 功能1：随机字符串取值;
# 功能2：字符串Base64加密;
# 功能2：位运算
# 作者：JABase
#--------------------------------------------


# 脚本入口
function init(){

    aass=$(base64_encrypt "com")
    echo "====输出结果：$aass"
    DD=`echo "$aass" | base64 -d`
    echo "==解码：$DD"
    
#  let "value=4<<2"
#  echo "====4左移2位：${value}"
#  let "value=4>>2"
#  echo "====4右移2位：${value}"
#
#  let "value=10^3"
#  echo "====10^3异或：${value}"
#
#  let "value=~10"
#  echo "====10取反：${value}"
#
#  let "value=8|4"
#  echo "====8|4或运算：${value}"
#
#  let "value=8&4"
#  echo "====8&4与运算：${value}"
}

: '
    /// - 指定字符串范围随机拼接9位长度的字符
    /// - Parameter
    ///   - MATRIX: 字符串执行范围
    ///   - LENGTH: 返回字符串长度
    /// - echo 返回LENGTH长度字符串
'
# 指定字符内随机取9位字符组合
function str_random() {
    # 取随机数：$RANDOM
    # 特殊字符~!@#$%^&*()_+=
    MATRIX="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    LENGTH="9"
    while [ "${n:=1}" -le "$LENGTH" ]
    do
        PASS="$PASS${MATRIX:$(($RANDOM%${#MATRIX})):1}"
        let n+=1
    done
    echo "$PASS"
}
# 加盐随机字符串
salt=$(str_random)

# base64加密和解密
function base64_encrypt(){

    # 传参为空，直接返回
    if [[ -z $1 ]];then
      return
    fi

    if [[ -z $2 ]];then
      temp=${salt}
    else
      temp=${2}
    fi
    
    # 取传参值
    value=$1
    # 判断长度（长度大于3时，在第三位以后加入盐，并最终在末尾再加一次盐）
    if [ ${#value} -gt 3 ];then
        # 末尾加盐,并随机夹入9位，取值时去除盐后，再删除后9位（位数与str_random保持一致）
        value=${value:0:3}${salt}${value:3}$(str_random)${salt}
    fi
    echo $value | base64
    
    : '
    #echo $value | md5
    # 加密一
    AA=$(printf "%s""$value" | base64)  # 加密
    echo "==加密一：$AA"
    # 加密二
    BB=$( base64 <<< "$value")  # 加密
    echo "==加密二：$BB"
    # 加密三
    BB1=`echo $value | base64`  # 加密
    echo "==加密三：$BB1"

    # 解码一
    CC=$( base64 -d <<< $AA= )
    echo "\n==解码一：$CC"
    # 解码二
    DD=`echo "$BB1" | base64 -d`
    echo "==解码二：$DD"
    '
}
## 脚本启动
init $1


: '

OC中需要配套写的取值逻辑

// 配置加密结果还原
- (NSString *)configRestore:(NSString *)key {
    
    NSString *str = [[NSBundle mainBundle] objectForInfoDictionaryKey:key]?:@"";

    NSString *value = [self string64:str];
    if (value.length > 12) {
        //取出最后9位
        NSString *sub = [value substringWithRange:NSMakeRange(3, 9)];
        if ([value hasSuffix:sub]) {
            value = [value stringByReplacingOccurrencesOfString:sub withString:@""];
            if (value.length > 9) {
                value = [value substringToIndex:value.length - 9];
            }
        }
    }
    // xcconfig中添加带有“://”需要处理为":/$()/"
    value = [value stringByReplacingOccurrencesOfString:@":/$()/" withString:@"://"];

    return value;
}

// 读取配置中的base64字符串
- (NSString *)string64:(NSString *)str {

    if (![str isKindOfClass:NSString.class] || str.length == 0) {
        return str;
    }
    NSData *data = [[NSData alloc] initWithBase64EncodedString:str options:0];
    NSString *value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (value.length == 0) {
        return str;
    }
    // 去除首尾换行符
    return [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

`
