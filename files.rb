
require 'open3'

def readFile(src)
  f = File.open(src, "r")
  f.each_line do |line|
    yield line.sub(/\s+/,"").split(/;/)
  end
  f.close
end

def numStat(key,repo)
  Open3.popen3('git show --numstat %s --pretty=format:"%%as"' % key, :chdir=>"FOLDER/repos/%s" % repo) { |i,o,e,t|
    date = o.gets.chomp
    while ln = o.gets
      yield date, ln.chomp
    end
  }
end

(src, dst) = ARGV

File.open(dst, 'w') do |file|
  readFile(src) { |repo, key|
    numStat(key, repo) { |date, ln|
      next unless ln.match(/^\d+\s+/)
      next unless ln.match(/\.groovy\s*$/) || ln.match(/\.java\s*$/)  || ln.match(/\.js\s*$/) || ln.match(/\.xsd\s*$/)
      file.puts(([repo, key, date] + ln.split(/\s+/)).join ";")
    }
  }
end
