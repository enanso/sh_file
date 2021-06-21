## 注意事项
1.可配置config.json文件修改info.plist文件；

    a.配置文件config.json格式：
    {
        "Version":"6.7.3",
        "Build":"1.2"
    }
    b.字段可以新增、修改、删除；
       新增：plist文件中不存在的key；
       修改：plist文件中已存在的key；
       删除：plist文件中已存在的key，配置文件中值为“”时；
           
2.将ipa、embedded.mobileprovision.mobileprovision、resign.sh、changeinfo.sh（config.json根据需要创建）放在同级目录下；

    脚本changeinfo.sh用途：
     1.内部解压ipa包 (非同级目录时传传参：$1为ipa文件路径[必传]，$2为build指定值[可不传，内部自增])；
     2.根据config.json修改plist文件，无config.json或者config.json不包含Build字段时，可实现Build自增1；
     3.修改info.plist文件后压缩，并拷贝至当前文件夹下；
     4.如果存在resign.sh，会自动执行，传参告知ipa文件名（$1）和Bundel Id值（$2）。
             
    脚本resign.sh用途：
     1.当前文件目录下的ipa ($1传如或者自查唯一的ipa包：ipafile，$2为ipa的Bundle Id);
     2.自动检测同级目录下的ipa包和描述文件，描述文件不存在时，将feildValue设置为Bundle Id并设置filetype类型，
       将从本地X-code中自动找到最新版本的描述文件，并copy至当前目录下改名为embedded.mobileprovision；
     3.自动查找X-code中的描述文件时，会自动删除过期描述文件及是否仅保留最新描述文件（设置keepLatest）；
     4.自动筛选出匹配描述文件的证书，在执行重签提示选择填充“Signing Identity:”值的证书。
     
3.生成新的ipa包即为重签收的包，手动操作上传（后期可补充自动上传ipa包功能）
