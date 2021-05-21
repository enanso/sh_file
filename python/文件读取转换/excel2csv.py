#!/usr/bin/env python
#引入Excel库的xlrd
import xlrd
import csv
import os
#生成的csv文件名
csv_file_name = 'excel_to_csv.csv'
def get_excel_list():
  #获取Excel文件列表
  excel_file_list = []
  file_list = os.listdir(os.getcwd())
  for file_name in file_list:
    if file_name.endswith('xls'):
      excel_file_list.append(file_name)
  return excel_file_list
def get_excel_header(excel_name_for_header):
  #获取表头，并将表头全部变为小写
  workbook = xlrd.open_workbook(excel_name_for_header)
  table = workbook.sheet_by_index(0)
  #row_value = table.row_values(0)
  row_value = [i.lower() for i in table.row_values(0)]
  return row_value
def read_excel(excel_name):
  #读取Excel文件每一行内容到一个列表中
  workbook = xlrd.open_workbook(excel_name)
  table = workbook.sheet_by_index(0) #读取第一个sheet
  nrows = table.nrows
  ncols = table.ncols
  # 跳过表头，从第一行数据开始读
  for rows_read in range(1,nrows):
    #每行的所有单元格内容组成一个列表
    row_value = []
    for cols_read in range(ncols):
      #获取单元格数据类型
      ctype = table.cell(rows_read, cols_read).ctype
      #获取单元格数据
      nu_str = table.cell(rows_read, cols_read).value
      #判断返回类型
      # 0 empty,1 string, 2 number(都是浮点), 3 date, 4 boolean, 5 error
      #是2（浮点数）的要改为int
      if ctype == 2:
        nu_str = int(nu_str)
      row_value.append(nu_str)
    yield row_value
 
def xlsx_to_csv(csv_file_name,row_value):
  #生成csv文件
  with open(csv_file_name, 'a', encoding='utf-8',newline='') as f: #newline=''不加会多空行
    write = csv.writer(f)
    write.writerow(row_value)
if __name__ == '__main__':
  #获取Excel列表
  excel_list = get_excel_list()
  #获取Excel表头并生成csv文件标题
  xlsx_to_csv(csv_file_name,get_excel_header(excel_list[0]))
  #生成csv数据内容
  for excel_name in excel_list:
    for row_value in read_excel(excel_name):
      xlsx_to_csv(csv_file_name,row_value)
  print('Excel文件转csv文件结束 ')

