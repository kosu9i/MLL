#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'csv'

class Node
  def initialize(data_set)
    @data_set = data_set
    @l = nil
    @r = nil
  end

  def add_l(node)
    @l = node
  end

  def add_r(node)
    @r = node
  end

  def set_branch(feature_id, threshold)
    @feature_id = feature_id
    @threshold = threshold
  end

  def get_branch
    return @feature_id, @threshold
  end
  
  def get_l
    @l
  end

  def get_r
    @r
  end

  # 一番多いクラスを返す
  def get_result
    result = {}
    @data_set.each do |data|
      result[data[-1]] = result.has_key?(data[-1]) ? result[data[-1]] + 1 : 1
    end
    
    result.max{|a, b| a[1] <=> b[1]}[0]
  end
end

class Cart
  def initialize(train_data, use_feature, depth)
    @train_data = train_data
    @feature_size = train_data[0].size - 1
    @use_feature = use_feature
    @depth = depth
  end

  def build
    depth = 0
    @tree = Node.new(@train_data)
    build_tree(@train_data, depth, @tree)
  end

  def build_tree(data_set, depth, node)
    return if depth >= @depth

    max_gain = 0
    max_gain_threshold = 0
    max_gain_feature = 0
    lset = []
    rset = []

    data_set.each do |data|
      @feature_size.times do |f|
        lset_tmp, rset_tmp, gain = get_gain(data_set, data[f], f)
        if gain > max_gain
          max_gain = gain if gain
          max_gain_threshold = data[f]
          max_gain_feature = f
          lset = lset_tmp
          rset = rset_tmp
        end
      end
    end

    node_l = Node.new(lset)
    node_r = Node.new(rset)

    node.add_l(node_l) unless lset.empty?
    node.add_r(node_r) unless rset.empty?
    node.set_branch(max_gain_feature, max_gain_threshold)

    depth += 1
    build_tree(lset, depth, node_l) unless lset.empty?
    build_tree(rset, depth, node_r) unless rset.empty?

  end


  def get_gain(data_set, threshold, f)
    l = {}
    r = {}
    c = {}
    gini_c = 1
    lset = []
    rset = []

    data_set.each do |data|
      if data[f].to_f < threshold.to_f
        l[data[-1]] = l.has_key?(data[-1]) ? l[data[-1]] + 1 : 1
        lset << data
      else
        r[data[-1]] = r.has_key?(data[-1]) ? r[data[-1]] + 1 : 1
        rset << data
      end
      c[data[-1]] = c.has_key?(data[-1]) ? c[data[-1]] + 1 : 1
    end

    c.each do |k, v|
      gini_c -= (v/data_set.size.to_f) ** 2
    end

    gini_l = 1
    gini_r = 1
    lsum = 0
    rsum = 0

    l.each do |k, v|
      lsum += v
    end
    r.each do |k, v|
      rsum += v
    end

    l.each do |k, v|
      gini_l -= (v/lsum.to_f) ** 2
    end
    r.each do |k, v|
      gini_r -= (v/rsum.to_f) ** 2
    end

    gain = (data_set.size/@train_data.size.to_f)*gini_c - 
      (lsum/@train_data.size.to_f)* gini_l -
      (rsum/@train_data.size.to_f)* gini_r

    return lset, rset, gain
  end


  def eval(target)
    _eval(target, @tree)
  end

  def _eval(target, node)
    result = nil

    # 葉の場合
    if (node.get_l.nil? && node.get_r.nil?)
      result = node.get_result
    else
      feature_id, threshold = node.get_branch
      if target[feature_id] < threshold
        result = _eval(target, node.get_l)
      else 
        result = _eval(target, node.get_r)
      end
    end
    
    return result
  end

  def print_tree
    node = @tree
    _print_tree(node)
    
  end

  def _print_tree(node)
    feature_id, threshold =  node.get_branch
    puts "feature_id: #{feature_id}"
    puts "threshold: #{threshold}"
    l = node.get_l
    r = node.get_r
    puts "left node"
    p l
    puts "right node"
    p r
    puts ""
    _print_tree(l) unless l.nil?
    _print_tree(r) unless r.nil?
  end

end

class RF 
  def initialize(bs, data_set, feature_num, label)
    @tree_set = []
    @label = label
    bs.each_with_index do |index_arr, i|
      # 特徴量をランダムに決定
      use_feature = (0..(@label.size - 2)).to_a.shuffle![0..(feature_num - 1)]
      data = []
      index_arr.each do |index|
        class_value = data_set.get_data[index][@label.size - 1]
        data << (data_set.get_data_with_column(index, use_feature) << class_value)
      end
      # 決定木の作成
      tree = Cart.new(data, use_feature, 2)
      tree.build
      puts "=== tree ==="
      tree.print_tree
      puts ""
      #train_data = Ai4r::Data::DataSet.new(:data_items => data)
      #tree_id3 = Ai4r::Classifiers::ID3.new.build(train_data)
      @tree_set << {:tree => tree, :feature => use_feature}
    end
  end

  def predict(target)
    result_set = {}
    result_set[:none] = 0
    @tree_set.each do |set|
      tree = set[:tree]
      feature = set[:feature]
      use_target = []
      feature.each do |i|
        use_target << target[i]
      end
      use_target << target[-1]
      begin
        result = tree.eval(use_target)
        unless result_set.has_key?(result.to_s)
          result_set[result.to_s] = 1 
        else
          result_set[result.to_s] += 1
        end
      rescue
        result_set[:none] += 1
      end
    end
    return result_set.max{|a, b| a[1] <=> b[1]}[0]
  end

end


class DataSet
  def initialize(input_file, test_data_num)
    @data_set = []
    @test_data = []
    CSV.foreach(input_file) do |row|
      @data_set << row
    end
    @data_set.shuffle!
    @test_data = @data_set.slice!(0, test_data_num)
  end

  def get_data_with_column(data_index, col_array)
    data = []
    col_array.each do |col|
      data << @data_set[data_index][col]
    end
    data
  end

  def get_data 
    @data_set
  end

  def get_test_data
    @test_data
  end

  def boot_strap(tree_num, sample_num)
    bs = Array.new(tree_num)
    bs.each_with_index do |sample, i|
      bs[i] = (0..(@data_set.size - 1)).to_a.shuffle![0..(sample_num - 1)]
    end
    bs
  end
end


data_set = DataSet.new(ARGV[0], 20)
bs = data_set.boot_strap(100, (data_set.get_data.size*(2/3.to_f)).to_i)
rf = RF.new(bs, data_set, 2, ["Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width", "Species"])
data_set.get_test_data.each do |test_data|
  result = rf.predict(test_data)
  if result == test_data[-1]
    puts "correct"
    #puts "result: #{result} predict: #{test_data[-1]}"
  else
    puts "incorrect"
    puts "result: #{result} predict: #{test_data[-1]}"
  end
end
