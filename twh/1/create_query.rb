#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'csv'

# 検索条件のテーブルファイル
f = File.open("./data/query/cond_table.tsv", "w")

# その他検索条件
CSV.foreach("./data/query/other_cond.tsv", {:col_sep => "\t"}) do |row|
  row.delete(nil)

  next unless row[0] =~ /value/

  row[0].sub!("value", "")
  f.write row.join("\t")
  f.write "\n"
end

# 駅の検索条件
CSV.foreach("./data/query/station_cond.tsv", {:col_sep => "\t"}) do |row|
  row.delete(nil)

  # 駅ID が取得できない行は無視
  next unless row.index("nil").nil?

  # 駅名, 検索ID, 0, 1
  f.write row[1] + "-" + row[3] + "\t" + row[5] + "\t" + "0" + "\t" + "1" + "\n"
end

f.close

cond_table = []

CSV.foreach("./data/query/cond_table.tsv", {:col_sep => "\t"}) do |row|
  cond = []
  cond << row[1]
  cond << row[0]
  cond << row[2..(row.size - 1)]
  cond_table << cond
end

virtual_data = []

# 検索名行(ヘッダ)を格納
row = []
cond_table.each do |c|
  row << c[1]
end
virtual_data << row

# 検索ID行(ヘッダ)を格納
row = []
cond_table.each do |c|
  row << c[0]
end
virtual_data << row

# 仮想検索データを格納
500.times do
  row = []
  cond_table.each do |c|
    row << c[2][rand(c[2].size)]
  end
  virtual_data << row 
end

# 仮想検索データをTSVに出力
f = File.open("./data/query/virtual_query.tsv", "w")
virtual_data.each do |data|
  f.write data.join("\t")
  f.write "\n"
end
f.close

#CSV.foreach("./data/query/virtual_query.tsv", {:col_sep => "\t"}) do |row|
#  p row.size
#end
