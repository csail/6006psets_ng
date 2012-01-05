#!/usr/bin/env rake
require 'rake/clean'
require 'csv'
require 'time'
require 'json'

SUB_PARTS = %w(name 1 2 late bonus code proof total proof_comment)

def init_score_hashes(csv_data, sols)
  start_line = 8
  name_col = 0
  username_col = 1
  score_hashes = {}
  csv_data[start_line..-1].each do |line|
    username =  line[username_col].strip
    h = {}
    SUB_PARTS.each { |k| h[k] = nil }
    h['name'] = line[name_col].strip
    sols.keys.each do |problem|
      h[problem] = {}
      sols[problem].keys.each { |part| h[problem][part] = { :ans => nil, 
                                                            :score => 0 } }
    end
    score_hashes[username] = h
  end
  score_hashes
end

def grade_one(file_path, score_hash, sols)
  ans_re = /%%%\s*PROBLEM\s*(\d)\((\w)\)\s*ANSWER\s*START\s*%%%(.*?)%%%\s*PROBL/m
  File.open(file_path, "r") do |f|
    contents = f.read
    contents.scan(ans_re).each do |problem, part, ans|
      part.downcase!
      # Removes leading and trailing whitespace (including line breaks)
      # in the answer.
      ans = ans.strip.split(/%/).first
      ans = ans && ans.strip
      raise "Unknown problem: #{problem}" if score_hash[problem].nil?
      if sols[problem][part] 
        score_hash[problem][part][:ans] = ans
        if ans =~ /^#{sols[problem][part][:ans]}$/
          score_hash[problem][part][:score] = sols[problem][part][:score]
        end
      end
    end
  end
end

def grade_and_fill(score_hashes, sols)
  Dir['files/raw/*'].sort.each do |filename| 
    username = File.basename(filename).scan(/\w+@mit\.edu/).first
    if score_hashes[username].nil?
      p "Unknown username in submission: #{username}" 
    else 
      grade_one filename, score_hashes[username], sols
    end
  end
end

def read_sol(sol_path)
  sols = {}
  File.open(sol_path, 'r') do |f|
    num_problems = f.gets.to_i
    num_problems.times do 
      inputs = f.gets.split.map(&:strip)
      raise RuntimeError, 'Invalid input!' if inputs.count != 2
      problem = inputs.first
      sols[problem] = {}
      num_subparts = inputs[1].to_i
      num_subparts.times do 
        sub_part = f.gets.split.map(&:strip)
        raise RuntimeError, 'Invalid input!' if sub_part.count != 3
        sols[problem][sub_part[0]] = {:score => sub_part[1].to_i, 
                                      :ans => sub_part[2]}
      end
    end
  end
  sols
end

def fill_late_penalty(filename, score_hashes)
  start_line = 1
  username_col = 0
  time_col = 3
  deadline = Time.local(2011, 'sep', 28, 0)
  late_penalty = {}
  File.open(filename, 'r') do |f|
    lines = f.readlines
    lines[start_line..-1].each do |line|
      line = line.split("\t")
      username = line[username_col].scan(/\w+@mit\.edu/).first
      penalty = -100
      time_string = line[time_col].strip
      unless time_string.empty?
        time = Time.parse time_string
        penalty = -[([time - deadline, 0].max / 360).floor, 100].min
      end
      if score_hashes[username].nil?
        p "Unknown username in late penalty: #{username}."
      else
        score_hashes[username]['late'] = penalty
      end
    end
  end
end

def fill_proof_grades(csv_data, score_hashes)
  start_line = 8
  username_col = 1
  points_col = 10
  comment_col = 14
  csv_data[start_line..-1].each do |line|
    username = line[username_col].scan(/\w+@mit\.edu/).first
    user_score = score_hashes[username] 
    if user_score.nil?
      p "Unknown username in proof grades: #{username}."
    else
      user_score['proof'] = line[points_col] && line[points_col].strip.to_i
      comment = line[comment_col]
      user_score['proof_comment'] = comment && comment.strip
    end
  end
end

def fill_code_grades(csv_data, score_hashes)
  start_line = 1
  username_col = 0
  points_col = 1
  csv_data[start_line..-1].each do |line|
    username = "#{line[username_col].strip}@mit.edu"
    user_score = score_hashes[username] 
    if user_score.nil?
      p "Unknown username in proof grades: #{username}."
    else
      user_score['code'] = line[points_col] && line[points_col].strip.to_i
    end
  end
end

def fill_bonus(json_data, score_hashes)
  json_data['students'].each do |username, answers|
    username.strip!
    if score_hashes[username].nil?
      p "Unknown username in Gradetacular: #{username}."
    elsif answers && !answers.empty?
      score_hashes[username]['bonus'] = 5
    end
  end
end

def full_comment(score_hash)
  wrong_ans = ["1", "2"].map do |p|
    wrong_parts = score_hash[p].keys.sort.select { |sp| score_hash[p][sp][:score] == 0 }
    wrong_parts.map { |sp| [p, sp].join '-' }
  end 
  comment = "PSet 2: wrong answers: #{wrong_ans.flatten!.join ' '}; "
  comment << "proof: #{score_hash['proof']}; proof comment: #{score_hash['proof_comment']}; "
  comment << "code: #{score_hash['code']}; late penalty: #{score_hash['late']}; bonus: #{score_hash['bonus']}"
end

## Generate summary for everything.

directory 'files/summary'

file 'sol.txt'
file 'files/summary/summary.csv'
file 'files/summary/summary-time.tsv'
file 'files/summary/summary-proof.csv'
file 'files/summary/code-scores.csv'
file 'files/json/pset.json'

CLOBBER.include('files/summary/summary-all.csv')

file 'files/summary/summary-all.csv' => ['files/summary/summary.csv',
                                         'files/summary/summary-time.tsv',
                                         'files/summary/summary-proof.csv',
                                         'files/summary/code-scores.csv',
                                         'files/json/pset.json',
                                         'sol.txt'] do |t|
  sols = read_sol 'sol.txt'
  score_hashes = init_score_hashes CSV.read('files/summary/summary.csv'), sols
  grade_and_fill score_hashes, sols
  fill_late_penalty 'files/summary/summary-time.tsv', score_hashes
  fill_proof_grades CSV.read('files/summary/summary-proof.csv'), score_hashes
  fill_code_grades CSV.read('files/summary/code-scores.csv'), score_hashes
  json_data = JSON.load File.read('files/json/pset.json')
  fill_bonus(json_data, score_hashes)
  
  CSV.open(t.name, 'wb') do |csv|
    header =  []
    probs = sols.keys.sort!
    prob_parts = probs.map do |prob|
                   sols[prob].keys.map do |part| 
                     sols[prob][part].keys.map { |c| [prob, part, c].join('-') }
                   end
                 end
    header << 'username' << SUB_PARTS << prob_parts.flatten!.sort! << 'comment'
    csv << header.flatten!
    score_hashes.sort.each do |username, score_hash|
      line = []
      line << username << score_hash['name']
      scores = probs.map { |prob| score_hash[prob].values.inject(0) { |sum, v| sum += v[:score] } }
      SUB_PARTS[3..-3].each { |p| scores << score_hash[p] }
      line << scores
      line << [[scores.inject(0) { |sum, s| sum += s.to_i }, 0].max, 100].min 
      line << score_hash['proof_comment']
      prob_parts.each do |p|
        prob, part, c = p.split '-'
        line << score_hash[prob][part][c.to_sym]
      end
      line << full_comment(score_hash)
      csv << line.flatten!
    end
  end 
end

task :summary => 'files/summary/summary-all.csv'

task :default => :summary