
##############################################
#
# 使用：读取excel
# pip3 install -xlrd执行“3”为本地python环境版本
# 或者提高权限：pip3 install -xlrd --user
# xlrd库版本：2.0.1，注意不支持xlsx
#
##############################################

#引入Excel库的xlrd

import xlrd
#1.读取Excel数据
# table = xlrd.open_workbook("project.xls","r")
# print("获取excel的所有标签:",table.sheets())
# for sheet in table.sheets():
#     print(sheet)

#2.读取第一个标签 第二个标签 ....
# table = xlrd.open_workbook("project.xls","r")
# sheetname = table.sheet_by_name("Sheet1")
# print("sheetname:",sheetname)
# sheetname1 = table.sheet_by_index(0)
# print("sheetname1:",sheetname1)

#3.读取excel数据指定的行数和列数 nrows 行数 ncols 列数
# table = xlrd.open_workbook("project.xls","r")
# sheet1 = table.sheet_by_index(0)
# print("Sheet1下面有{}行数据".format(sheet1.nrows))
# print("Sheet1下面有{}列数据".format(sheet1.ncols))

#4.获取指定的行数和列数 row_values 行数  col_values 列数
# table = xlrd.open_workbook("project.xls","r")
# sheet1 = table.sheet_by_index(0)
# onesheetrow = sheet1.row_values(0)
# print("第一行的数据:",onesheetrow) #第一行的数据: ['用户名', '密码', '预期结果']
# onesheetcol = sheet1.col_values(0)
# print("第一列的数据:",onesheetcol)
#第一列的数据: ['用户名', 18797813131.0, 18797813121.0, 18797813122.0, 18797813123.0, 18797813124.0]

#5.获取指定行和指定列的数据 cell
# table = xlrd.open_workbook("project.xls","r")
# sheet1 = table.sheet_by_index(0)
# row_col = sheet1.cell(0,0)
# print("第一行和第一列的数据:",row_col)
# row_col1 = sheet1.cell(2,1)
# print("第二行和第一列的数据:",row_col1)

#6.获取excel的用户名和密码
# table = xlrd.open_workbook("project.xls","r")
# sheet1 = table.sheet_by_index(0)
# rows = sheet1.nrows
# for i in range(1,rows): # 1,2,3,4,5
#     print("当前的用户名为:",sheet1.row_values(i)[0],
#           "密码为:",sheet1.row_values(i)[1],
#           "获取的登录信息为:",sheet1.row_values(i)[2])


#7.写一个方法,输入行数,返回该行的所有数据
# def read_user(nrow=0):
#     """读取用户名"""
#     table = xlrd.open_workbook("project.xls","r")
#     sheet1 = table.sheet_by_index(0)
#     return sheet1.row_values(nrow)[0]
#
# def read_passwd(nrow):
#     """读取密码"""
#     table = xlrd.open_workbook("project.xls", "r")
#     sheet1 = table.sheet_by_index(0)
#     return sheet1.row_values(nrow)[1]
#
# # print(read_user(1),read_passwd(1))
#
# row_number = int(input("请输入行数"))
# print("第{}行的数据是:{}".format(row_number,read_user(row_number)))

# #8.读取的数据存储在List的中
def readExcels():
    tables = xlrd.open_workbook("project.xls", "r")
    sheet = tables.sheet_by_index(0)
    nrow = [] #定义空列表
    for row in range(0,sheet.nrows):
        nrow.append(sheet.row_values(row,start_colx=0,end_colx=sheet.ncols))
    return nrow
print(readExcels())

