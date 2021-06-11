import os

tags = {"Name": False,
        "UUID": False,
        "TeamName": False}
        
def get_target_tag(key, l):
    global tags
    if tags[key]:
        #剔除多余的字符
        print(key+': ' + l.replace(r"b'\t<string>",'').replace(r"</string>\n'",''))
        tags[key] = False
    if ('<key>%s</key>'%key) in l:
        tags[key] = True
        
def get_mobileprovision_files(path):
    for f in os.listdir(path):
        if f.endswith('.mobileprovision'):
            yield f
    
if __name__ == '__main__':
    #打开同级目录'.'
    for f in get_mobileprovision_files('.'):
        r=open(f,'rb')
        lines=r.readlines()
        for l in lines:
            for k in tags.keys():
                get_target_tag(k,str(l))
        r.close()