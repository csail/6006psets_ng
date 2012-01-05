#!usr/bin/env ruby
require 'csv'

class ProblemSet
  ANSWER_MARKER = /%%% PROBLEM (\d)\((\w)\) ANSWER START %%%\s(.*?)\s%%% PROBL/m
  START_LINE = 8
  USERNAME_COL = 1
  POINTS_COL = 10
  
  def initialize(pset_path, sol_path, summary_path)
    @sol = read_sol sol_path
    @pset_path = pset_path
    @summary_path = summary_path
  end
  
  def grade_one(file_path)
    score = Array.new @num_problems, 0
    File.open(file_path, "r") do |f|
      contents = f.read
      contents.scan(ANSWER_MARKER).each do |a|
        problem, part, ans = a[0].to_i, a[1], a[2].strip
        if @sol[problem][part] && ans =~ /^#{@sol[problem][part][:sol]}$/
          score[problem - 1] += @sol[problem][part][:score]
        end
      end
    end
    score  
  end
  
  def grade()
    pset_dir = Dir.new @pset_path
    scores = {}
    pset_dir.each do |filename| 
      file_path = File.expand_path filename, @pset_path
      unless File.directory? file_path 
        username = filename.scan(/\w+@mit\.edu/)[0]
        scores[username] = grade_one file_path
      end
    end
    fill_summary scores
  end
  
  def fill_summary(scores)
    (1..@num_problems).each do |problem|
      summary = CSV.read @summary_path
      (START_LINE...summary.count).each do |line|
        username = summary[line][USERNAME_COL]
        score = 0
        score = scores[username][problem - 1] if scores[username]
        summary[line][POINTS_COL] = score
      end
      filename = @summary_path.chomp File.extname(@summary_path) 
      filename << problem.to_s << '.csv'
      CSV.open(filename, 'w') do |csv|
        summary.each { |line| csv << line}
      end
    end
  end
  
  def read_sol(sol_path)
    sols = {}
    File.open(sol_path, "r") do |f|
      @num_problems = f.gets.to_i
      @num_problems.times do 
        inputs = f.gets.split.map(&:strip)
        raise RuntimeError, 'Invalid input!' if inputs.count != 2
        problem = inputs[0].to_i
        sols[problem] = {}
        num_subparts = inputs[1].to_i
        num_subparts.times do 
          sub_part = f.gets.split.map(&:strip)
          raise RuntimeError, 'Invalid input!' if sub_part.count != 3
          sols[problem][sub_part[0]] = {:score => sub_part[1].to_i, 
                                        :sol => sub_part[2]}
        end
      end
    end
    sols
  end
end

ProblemSet.new(ARGV.first, ARGV[1], ARGV[2]).grade if __FILE__ == $0
