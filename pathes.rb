# coding: utf-8

require 'sqlite3'
require 'json'

work_dir='/Users/om/aura/timeFiles/data'

db_file="%s/%s" % [work_dir,'timeFiles.db']

data = {}

def data2out(level)
  out = []
  level.sort { |a,b| b[1][:value] <=> a[1][:value] }.each do |name, value|
    node = { text: name, tags: [value[:value]] }
    node[:nodes] = data2out( value[:nodes] ) if value[:nodes].is_a?(Hash) and value[:nodes].length() > 0
    out << node
  end
  out
end

SQLite3::Database.new( db_file ) do |db|
  #  db.execute( "select repo,file,cast( hours + 0.5 as int ) hours from gitFilesAM where repo='correqts-markswebb' and subName is null" ) do |row|
  db.execute( "select repo,file,cast( hours + 0.5 as int ) hours from gitFilesAM" ) do |row|
    path = [ row[0] ] + row[1].split('/')
    value = row[2].to_f

    cursor = data
    path.each { |x|
      cursor[x] ||= {}
      cursor[x][:text] = x
      cursor[x][:value] ||= 0.to_f
      cursor[x][:value] += value
      cursor[x][:nodes] ||= {}
      cursor = cursor[x][:nodes]
    }

    #    puts "%.2f\t%s\n" % [ value, path.join(':') ]
  end
end

out = data2out(data)
puts JSON.generate(out)
# JSON.generate( [ { text: "abc", "tags": ["10 Gb"], "nodes": [] } ] )