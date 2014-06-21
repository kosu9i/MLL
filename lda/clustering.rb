#!/usr/bin/ruby
# -*- coding: utf-8 -*-
require 'csv'

file = ARGV[0]
doc_topic = []
word_topic = {}
doc_word = []
topic_num = 0

CSV.foreach(file) do |row|
  topic_num = row.size - 2

  # 今回使用するデータは 1-origin のため減算しておく
  doc_id = row[0].to_i - 1
  doc_topic[doc_id] = Array.new(topic_num, 0.0) if doc_topic[doc_id].nil?
  doc_word[doc_id] = Array.new() if doc_word[doc_id].nil?

  word = row[1] 
  doc_word[doc_id] << word

  topic_num.times do |num|
    word_topic[word] = Array.new(topic_num, 0.0) unless word_topic.has_key?(word)

    # TODO: 確率って足していくで正しいのか...?
    word_topic[word][num] += row[num + 2].to_f
    doc_topic[doc_id][num] += row[num + 2].to_f

  end
end

cluster_doc = Array.new(topic_num){Array.new()}
cluster_word = Array.new(topic_num){Array.new()}

doc_topic.each_with_index do |topics, doc_id|
  topic_id = topics.index(topics.max) 

  cluster_doc[topic_id].concat(doc_word[doc_id])
  cluster_doc[topic_id] << "\n"

end

word_topic.each do |word, topics|
  topic_id = topics.index(topics.max)
  cluster_word[topic_id] << word
end

cluster_doc.each_with_index do |words, topic_id|
  puts "===== topic #{topic_id} ====="
  words.each do |word|
    print "#{word}, "
  end
  print "\n"
end

cluster_word.each_with_index do |words, topic_id|
  puts "===== topic #{topic_id} ====="
  words.each do |word|
    print "#{word}, "
  end
  print "\n"
end




