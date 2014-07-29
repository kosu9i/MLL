#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'mechanize'
require 'fileutils'

def get_html(agent, link)
  ken = link.node.text
  FileUtils.mkdir_p("./data/html/#{ken}")

  rosen_page = agent.get(link.href)
  

  f = File.open("./data/html/#{ken}/#{ken}_rosen.html", "w")
  f.write(rosen_page.body.toutf8)
  f.close

  e_form = rosen_page.search('form#prg-flowRosen')

  e_form.css('label').each do |e_label|
    next if e_label.css('a').nil? or e_label.css('a')[0].nil?

    link_line = e_label.css('a')[0]['href']
    eki_page = agent.get(link_line)
    rosen_name = ken + "_" + e_label.css('a').text
    f = File.open("./data/html/#{ken}/#{rosen_name}.html", "w")
    f.write(eki_page.body.toutf8)
    f.close
    sleep 15
  end

end

agent = Mechanize.new

page = agent.get("http://www.homes.co.jp/chintai/")

links = []

page.links.each do |link|
  # 路線検索へのリンクのみ抽出
  if link.href =~ /.*line.*/
    links << link
 end
end

links.each do |link|
  get_html(agent, link)
end

