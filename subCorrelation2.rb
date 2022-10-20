# coding: utf-8

require 'sqlite3'
require 'pp'

work_dir='/Users/om/aura/timeFiles/data'
db_file="%s/%s" % [work_dir,'timeFiles.db']

subsystems = []

stop = ["","Микроядро ДБО","Конструктор документов","Служебные утилиты"]
SQLite3::Database.new( db_file ) do |db|
  db.execute( 'SELECT subName,count(distinct date) FROM dateSubsytem GROUP BY 1 ORDER BY 2 DESC' ) do |row|
    subsystems << ( row[0] || "" ) unless stop.any?(row[0])
  end
end

matrix_count = Hash.new(0)
matrix_sum = Hash.new(0)

#!!!!  UPDATE dateSubsytem SET subName="" WHERE subName IS NULL;
subsystems.each do |subsystem|

  dates = []
  SQLite3::Database.new( db_file ) do |db|
    db.execute( 'SELECT date FROM dateSubsytem WHERE subName = ? ORDER BY 1', [subsystem] ) do |row|
      dates << row[0]
    end
  end

  dates[0..-2].zip( dates[1..-1] ).each { |interval|
    SQLite3::Database.new( db_file ) do |db|
      matrix_count[ subsystem ] += 1
      db.execute( %q|SELECT cast( julianday(min(date)) - julianday(?) as int ) days, subName FROM dateSubsytem WHERE date >= ? and date < ? and subName != ? GROUP BY 2 ORDER BY 1,2|,
                  [ interval[0], interval[0], interval[1], subsystem ] ) do |row|
        matrix_sum[ [subsystem,row[1]].sort ] += 1.0 / ( row[0] + 1 )
      end
    end
  }
end

subsystems.each do |col|
  subsystems.each do |row|
    idx = [col,row].sort
    count = matrix_count[col] + matrix_count[row]
    value = count > 0 ? ( 1.0 * matrix_sum[idx] / count ) : ""
    puts [col,row,value].join ';'
  end
end

exit 0

puts ["",subsystems].join ';'
subsystems.each do |col|
  puts [col,subsystems.map { |row|
    idx = [col,row].sort
    count = matrix_count[col] + matrix_count[row]
    count > 0 ? ( 1.0 * matrix_sum[idx] / count ) : ""
  }].join ';'
end


# SELECT subName,count(distinct date) FROM dateSubsytem GROUP BY 1 ORDER BY 2 DESC ;
# SELECT date FROM dateSubsytem WHERE subName = "Настраиваемый штамп" ORDER BY 1;
# SELECT cast( julianday(min(date)) - julianday('2021-09-20') as int ) days, subName FROM dateSubsytem WHERE date >= '2021-09-20' and date < '2021-09-22' and subName != "Электронный офис" GROUP BY 2 ORDER BY 1,2;