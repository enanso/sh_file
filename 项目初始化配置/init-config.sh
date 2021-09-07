#!/usr/bin/env bash

#Config Color
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

#配置所在路径
configPath=$1
#product
product=$2

#更新资源
updateResources() {
    echo -e "${GREEN}开始注入图片资源${NC}⏰⏰⏰"
    #appIcon
    newPath=$(find ${configPath} -type d -name "AppIcon.appiconset")
    if test -z "newPath"; then
        exit 1
    fi
    oldPath=$(find ./ProjectName -type d -name "AppIcon.appiconset")

    if test -z "oldPath"; then
        exit 1
    fi
    cp -R ${newPath}/ ${oldPath}

    #更新图标
    pics=$(ls ${configPath})
    for filename in $pics; do
        if [ "${filename##*.}"x = "png"x ] || [ "${filename##*.}"x = "jpg"x ] || [ "${filename##*.}"x = "jpeg"x ]; then
            ph=$(find ./ProjectName -type f -name "${filename}")
            cp -f ${configPath}/${filename} ${ph}
        fi
    done
    echo -e "${GREEN}完成注入图片资源${NC}🚀🚀🚀"

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
#编译配置文件
buildConfig() {
    echo -e "${GREEN}开始注入XCConfig文件${NC}⏰⏰⏰"
    result=$(find ${configPath} -type f -name "config.json")
    if test -z "${result}"; then
        exit 1
    fi
    allXCConfigs=(
        "ProjectName.debug.xcconfig"
        "ProjectName.release.xcconfig"
        "ProjectNameShareExtension.debug.xcconfig"
        "ProjectNameShareExtension.release.xcconfig")
    allPodXCConfigs=(
        "Pods-ProjectName.debug.xcconfig"
        "Pods-ProjectName.release.xcconfig"
        "Pods-Share.debug.xcconfig"
        "Pods-Share.release.xcconfig")

    tempArray=("QYC_appStoreId" "QYC_bd" "QYC_rcd" "QYC_rcr" "QYC_privacyURL" "QYC_test" "QYC_test1" "QYC_domain")
    for ((i = 0; i < ${#allXCConfigs[@]}; i++)); do
        podXCConfigPath=$(find Pods -type f -name "${allPodXCConfigs[i]}")
        xcconfig=$(find ./ -type f -name "${allXCConfigs[i]}")
        echo >${xcconfig}
        pod="#include \"${podXCConfigPath}\""
        echo ${pod} >>${xcconfig}
        array=$(cat ${result} | jq 'keys')
        count=$(cat ${result} | jq 'keys | length')
        for ((j = 0; j < ${count}; j++)); do
            name=$(cat ${result} | jq 'keys' | jq -r --arg INDEX $j '.[$INDEX|tonumber]')
            value=$(cat ${result} | jq -r --arg NAME ${name} '.[$NAME]')
            if [[ ${allXCConfigs[i]} == "ProjectNameShareExtension.debug.xcconfig" ]] || [[ ${allXCConfigs[i]} == "ProjectNameShareExtension.release.xcconfig" ]]; then
                if [[ $name == "QYC_bundleId" ]]; then
                    value="${value}.Share"
                fi
            fi
            if [[ ! -z $value ]];then
            
                if [[ "${tempArray[@]}"  =~ "${name}" ]]; then
                    aass=$(base64_encrypt "${value}")
                    echo "${name} = ${aass}" >>${xcconfig}
                else
                    echo "${name} = ${value}" >>${xcconfig}
                fi
            fi
        done
    done
    echo -e "${GREEN}完成注入XCConfig文件${NC}🚀🚀🚀"
}
#infoPlist配置
infoPlistConfig() {
    echo -e "${GREEN}开始将变量注入infoPlist文件${NC}⏰⏰⏰"
    result=$(find ${configPath} -type f -name "config.json")
    if test -z "${result}"; then
        exit 1
    fi
    array=$(cat ${result} | jq 'keys')
    count=$(cat ${result} | jq 'keys | length')
    for ((j = 0; j < ${count}; j++)); do
        name=$(cat ${result} | jq 'keys' | jq -r --arg INDEX $j '.[$INDEX|tonumber]')
        value=$(cat ${result} | jq -r --arg NAME ${name} '.[$NAME]')
        
        if [[ -z $value ]];then
            /usr/libexec/PlistBuddy -c "Delete :${name} string \${${name}}" ./ProjectName/Info.plist
            /usr/libexec/PlistBuddy -c "Delete :${name} string \${${name}}" ./Share/shareInfo.plist
        else
            /usr/libexec/PlistBuddy -c "ADD :${name} string \${${name}}" ./ProjectName/Info.plist
            /usr/libexec/PlistBuddy -c "ADD :${name} string \${${name}}" ./Share/shareInfo.plist
        fi
    done
    echo -e "${GREEN}完成将变量注入infoPlist文件${NC}🚀🚀🚀"
} 

#BundleID开启的能力
entitlementsConfig() {
    echo -e "${GREEN}开始配置Capitility${NC}⏰⏰⏰"
    result=$(find ${configPath} -type f -name "config.json")
    if test -z "${result}"; then
        exit 1
    fi
    entitlementsPath="./ProjectName/ProjectName.entitlements"
    shareEntitlementsPath="./Share/Share.entitlements"
    /usr/libexec/PlistBuddy -c "Clear dict" ${entitlementsPath}
    /usr/libexec/PlistBuddy -c "Clear dict" ${shareEntitlementsPath}
    if [[ $product == "ProjectName" ]]; then
         #ProjectName
         #推送
         /usr/libexec/PlistBuddy -c "ADD :aps-environment string development" ${entitlementsPath}
         #apple登录
         /usr/libexec/PlistBuddy -c "ADD :com.apple.developer.applesignin array" ${entitlementsPath}
         /usr/libexec/PlistBuddy -c "ADD :com.apple.developer.applesignin: string Default" ${entitlementsPath}
         #share
         /usr/libexec/PlistBuddy -c "ADD :com.apple.security.application-groups array" ${entitlementsPath}
         /usr/libexec/PlistBuddy -c "ADD :com.apple.security.application-groups: string \${QYC_appGroup}" ${entitlementsPath}

         #Share
         #推送
         /usr/libexec/PlistBuddy -c "ADD :aps-environment string development" ${shareEntitlementsPath}
         #share
         /usr/libexec/PlistBuddy -c "ADD :com.apple.security.application-groups array" ${shareEntitlementsPath}
         /usr/libexec/PlistBuddy -c "ADD :com.apple.security.application-groups: string \${QYC_appGroup}" ${shareEntitlementsPath}

    elif [[ $product == "safety" ]]; then
         #ProjectName
         #推送
         /usr/libexec/PlistBuddy -c "ADD :aps-environment string development" ${entitlementsPath}

         #share
         /usr/libexec/PlistBuddy -c "ADD :com.apple.security.application-groups array" ${entitlementsPath}
         /usr/libexec/PlistBuddy -c "ADD :com.apple.security.application-groups: string \${QYC_appGroup}" ${entitlementsPath}

         #Share
         #推送
         /usr/libexec/PlistBuddy -c "ADD :aps-environment string development" ${shareEntitlementsPath}
         #share
         /usr/libexec/PlistBuddy -c "ADD :com.apple.security.application-groups array" ${shareEntitlementsPath}
         /usr/libexec/PlistBuddy -c "ADD :com.apple.security.application-groups: string \${QYC_appGroup}" ${shareEntitlementsPath}
    elif [[ $product == "njxingong" ]]; then
        #ProjectName
         #推送
         /usr/libexec/PlistBuddy -c "ADD :aps-environment string development" ${entitlementsPath}

         #share
         /usr/libexec/PlistBuddy -c "ADD :com.apple.security.application-groups array" ${entitlementsPath}
         /usr/libexec/PlistBuddy -c "ADD :com.apple.security.application-groups: string \${QYC_appGroup}" ${entitlementsPath}

         #Share
         #推送
         /usr/libexec/PlistBuddy -c "ADD :aps-environment string development" ${shareEntitlementsPath}
         #share
         /usr/libexec/PlistBuddy -c "ADD :com.apple.security.application-groups array" ${shareEntitlementsPath}
         /usr/libexec/PlistBuddy -c "ADD :com.apple.security.application-groups: string \${QYC_appGroup}" ${shareEntitlementsPath}
    else
         #ProjectName
         #推送
         /usr/libexec/PlistBuddy -c "ADD :aps-environment string development" ${entitlementsPath}
         #share
         /usr/libexec/PlistBuddy -c "ADD :com.apple.security.application-groups array" ${entitlementsPath}
         /usr/libexec/PlistBuddy -c "ADD :com.apple.security.application-groups: string \${QYC_appGroup}" ${entitlementsPath}

         #Share
         #推送
         /usr/libexec/PlistBuddy -c "ADD :aps-environment string development" ${shareEntitlementsPath}
         #share
         /usr/libexec/PlistBuddy -c "ADD :com.apple.security.application-groups array" ${shareEntitlementsPath}
         /usr/libexec/PlistBuddy -c "ADD :com.apple.security.application-groups: string \${QYC_appGroup}" ${shareEntitlementsPath}
    fi
    echo -e "${GREEN}完成配置Capitility${NC}🚀🚀🚀"
    
}

#选择项目
selectProject(){
    echo "请选择配置项目"
    select name in "配置项目1" "配置项目2" "自定义"; do
        case $name in
        "配置项目1")
            Pro1=$(find ./ -maxdepth 2 -type d -name "ConfigFile")
            if [ -z "$Pro1" ]; then
                echo "资源配置目录不存在，请在项目根目录同级放入资源配置"
                exit 1
            fi
            configPath=$Pro1
            product="ProjectName"
            break
            ;;
        "配置项目2")
            safety=$(find ./ -maxdepth 2 -type d -name "Safety")
            if [ -z "$safety" ]; then
                echo "资源配置目录不存在，请在项目根目录同级放入资源配置"
                exit 1
            fi
            configPath=$safety
            product="safety"
            break
            ;;
        "自定义")
            echo "请输入配置资源路径"
            read p
            if [ ! -d "$p" ]; then
                echo "自定义路径不存在，请重新输入"
                exit 1
            fi
            configPath=$p
            product="other"
            break
            ;;
        *)
            initProject
            ;;
        esac
    done
    echo -e "${GREEN}找到配置资源${configPath}${NC}🚀🚀🚀"
    return
}

initProject() {

    #如果传参配置为空，则选择
    if [ -z "$configPath" ] || [ -z "$product" ]; then 
        selectProject
    fi
    
    #xconfig的配置
    buildConfig

    #添加infoPlist
    infoPlistConfig

    #
    entitlementsConfig

    #
    updateResources
}


#入口
initProject

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
