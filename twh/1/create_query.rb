#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'nokogiri'

def get_station(ken_dir_path, ken_name, rosen_name, rosen_id)
  ret = []

  target_path = ken_dir_path + "/" + ken_name + "_" + rosen_name + ".html"

  unless File.exist?(target_path)
    ret << [ken_name, rosen_name, rosen_id, "nil", "nil"]
    return ret
  end

  doc = Nokogiri::HTML(File.open(target_path))

  e_form = doc.css('form#prg-flowform')

  e_form.css('label').each do |e_label|
    # 路線名, 路線ID を取得
    e_label.css('span').remove
    next if e_label.css('input').nil? or 
      e_label.css('input')[0].nil? or
      (e_label.css('input')[0]['class'] != "prg-flowchk" and
       e_label.css('input')[0]['class'] != "count-zero")

    eki_id = e_label.css('input')[0]['value']
    eki_name = e_label.text.gsub("\n", "").gsub(" ", "")

    ret << [ken_name, rosen_name, rosen_id, eki_name, eki_id]
  end

  return ret

end

def get_line(rosen_file_path)
  ret = []
  ken_dir_path = File.dirname(rosen_file_path)
  ken_name = ken_dir_path.sub("./data/html/", "")

  doc = Nokogiri::HTML(File.open(rosen_file_path))

  e_form = doc.css('form#prg-flowRosen')

  e_form.css('label').each do |e_label|
    row = []
    rosen_name = nil
    rosen_id = nil
    # 路線名, 路線ID を取得
    unless e_label.css('input').attr('disabled').nil?
      e_label.css('span').remove
      rosen_name = e_label.text.gsub("\n", "").strip
      rosen_id = e_label.css('input').attr('value').value.to_i
    else
      rosen_name = e_label.css('a').text
      rosen_id = e_label.css('input').attr('value').value.to_i
    end

    # 駅名, 駅名ID を取得
    ret += get_station(ken_dir_path, ken_name, rosen_name, rosen_id)
  end

  return ret
end


# 都道府県名, 路線名, 路線ID, 駅名, 駅名ID
# を取得して TSV ファイルに出力
def get_scrape_tsv(rosen_file_path)
  infos = get_line(rosen_file_path)
  f = File.open("station_info.tsv", "a")
  infos.each do |info|
    f.write info.join("\t")
    f.write "\n"
  end
  f.close
end

#begin
#  File.unlink "./query.tsv"
#rescue
#  puts "rm tsv file error. But no problem!"
#end

# 検索条件分類名, 検索条件分類ID
def get_query(e_table)
  e_table.css('th').each do |e_th|
    e_th.text
    e_table.css('td > select').each do |e_select|
      p e_select['name']
    end
  end
end

def get_query_detail(e_table)
end

doc = Nokogiri::HTML(File.open("data/search_detail.html"))
e_form = doc.css('form#prg-flowform')

e_form.css('table').each do |e_table|
  if e_table['class'] == "prg-tblBasic01 vertical"
    get_query(e_table)

  elsif  e_table['class'] == "vertical prg-tblBasic01"
    get_query_detail(e_table)
  end
  ## 路線名, 路線ID を取得
  #e_label.css('span').remove
  #next if e_label.css('input').nil? or 
  #  e_label.css('input')[0].nil? or
  #  (e_label.css('input')[0]['class'] != "prg-flowchk" and
  #   e_label.css('input')[0]['class'] != "count-zero")
  # 
  #eki_id = e_label.css('input')[0]['value']
  #eki_name = e_label.text.gsub("\n", "").gsub(" ", "")
  # 
  #ret << [ken_name, rosen_name, rosen_id, eki_name, eki_id]
end

