#!/usr/bin/ruby
# -*- coding: utf-8 -*-
require 'csv'

class Lda

  def initialize(alpha, beta, k, loop_num, file_path)
    @alpha = alpha.to_f
    @beta  = beta.to_f
    @k = k.to_i
    @loop_num = loop_num.to_i
    @docs = Array.new(1, [])
    @words = {}
    @topic_history = []

    # doc_id インデックスに
    # インデックス；トピックID、値；単語の数
    # の配列を格納
    @n_dt = []
    # トピックID インデックスに
    # キー：単語表記、値：そのトピックに
    @n_tw = []
    # インデックス：トピックID、値：トピックIDに属する単語の数
    @n_t = Array.new(@k, 0)
    
    open_docs(file_path)
    initialize_topic
    count_n
  end

  def open_docs(file_path)
    doc_id_now = 0
    # NOTE: 今回使用するデータは文書 ID でソートされている前提
    CSV.foreach(file_path) do |row|
      # 今回使用するデータの文書 ID が 1-origin のため減算
      doc_id = row[0].to_i - 1
      word = row[1]
      count = row[2].to_i

      # 次の文書
      if doc_id_now != doc_id
        @docs[doc_id] = Array.new()
        doc_id_now = doc_id
      end

      # トピックを格納する配列を確保
      @words[word] = Array.new(@k, 0) unless @words.has_key?(word)

      # 単語出現回数だけ登録
      count.times do
        @docs[doc_id_now] << word
      end

    end
  end

  def initialize_topic
    @docs.each_with_index do |doc, doc_id|
      @topic_history[doc_id] = Array.new(doc.size){Array.new(@loop_num, 0)}
      doc.each_with_index do |word, word_id|
        # 初期値(ランダム値)を格納
        @topic_history[doc_id][word_id][0] = rand(@k)
      end
    end
  end

  def count_n 
    @topic_history.each_with_index do |doc, doc_id|
      @n_dt[doc_id] = Array.new(@k, 0)
      doc.each_with_index do |topic_history, word_id|

        # n_dt のカウント
        @n_dt[doc_id][topic_history[0]] += 1
        
        # n_tw は @words を利用して算出する
        @words[@docs[doc_id][word_id]][topic_history[0]] += 1

        # n_t のカウント
        @n_t[topic_history[0]] += 1
      end
    end
  end

  def reallocation 
    @loop_num.times do |l|
      @docs.each_with_index do |doc, doc_id|
        doc.each_with_index do |word, word_id|

          old_topic = @topic_history[doc_id][word_id][l]
          new_topic = calc_p(doc_id, word, word_id) 

          if new_topic != old_topic
            @n_dt[doc_id][old_topic] -= 1
            @words[word][old_topic] -= 1
            @n_t[old_topic] -= 1
            @n_dt[doc_id][new_topic] += 1
            @words[word][new_topic] += 1
            @n_t[new_topic] += 1
          end

          @topic_history[doc_id][word_id][l + 1] = new_topic
        end
      end
    end
  end

  def calc_p (doc_id, word, word_id)
    max_p = 0
    new_topic = 0
    @k.times do |topic_id|
      # 計算式
      p = (@alpha + @n_dt[doc_id][topic_id].to_i - 1)*
        (@beta + @words[word][topic_id].to_i - 1)/(@beta * @words.size + @n_t[topic_id].to_i - 1)
      if p.to_f > max_p.to_f
        max_p = p
        new_topic = topic_id
      end
    end
    return new_topic
  end

  def print_result
    result = []
    @topic_history.each_with_index do |doc, doc_id|
      result[doc_id] = {}
      doc.each_with_index do |word, word_id|
        result[doc_id][@docs[doc_id][word_id]] = Array.new(@k, 0) unless result[doc_id].has_key?(@docs[doc_id][word_id])
        word.each do |topic_id|
          result[doc_id][@docs[doc_id][word_id]][topic_id] += 1
        end
      end
    end

    result.each_with_index do |doc, doc_id|
      doc_id += 1

      doc.each do |word, topics|
        sum = 0
        topics.each do |topic|
          sum += topic
        end

        print "#{doc_id},#{word}"

        topics.each_with_index do |val, topic_id|
          p = val.to_f/sum.to_f
          doc[word][topic_id] = p
          print ",#{p}"
        end
        puts ""
      end
    end
  end

end

def usage
  puts "USAGE: ./lda.rb alpha beta k loop_num input_file"
  exit 1
end

usage unless ARGV.size == 5

alpha = ARGV[0]
beta = ARGV[1]
k = ARGV[2]
loop_num = ARGV[3]
file_path = ARGV[4]

obj = Lda.new(alpha, beta, k, loop_num, file_path)
obj.reallocation
obj.print_result
