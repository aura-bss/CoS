# coding: utf-8

require 'pp'
require 'sqlite3'

work_dir='/Users/om/aura/timeFiles/data'
db_file="%s/%s" % [work_dir,'timeFiles.db']


def distance(a,b)
  (a[0]-b[0]).abs + (a[1]-b[1]).abs + (a[2]-b[2]).abs
end

def cost(list,data,medoids)
  cost = 0
  cnt = 0

  # Разделить системы по кластерам
  list.filter { |a| ! medoids.key?(a) }.each do |a|
    m = medoids.keys.max { |m1,m2| data[[a,m1]] <=> data[[a,m2]] }
    cost += data[[a,m]]
    cnt += 1
  end
  return cost / cnt
end

###############################

stop = ["","Микроядро ДБО","Конструктор документов","Служебные утилиты"]

data = Hash.new(0)
points = Hash.new
SQLite3::Database.new( db_file ) do |db|
  db.execute( %q|SELECT * FROM systemFullCouple| ) do |row|
    next if stop.any?(row[0]) || stop.any?(row[1])
    data[[ row[0],row[1] ]] = row[2]
    points[row[0]] = 1
    points[row[1]] = 1
  end
end

list = points.keys.sort

# BUILD
medoids = Hash.new
k = 12

# Выбрать кластера
(1..k).each { |idx|
  max_weight = 0
  max_point = nil
  items = list.filter { |a| ! medoids.key?(a) }
  items.each { |a|
    weight = 0
    items.each { |b|
      weight += data[[a,b]]
    }
    if weight > max_weight
      max_weight = weight
      max_point = a
    end
  }

  medoids[max_point] = []
}

# Разделить системы по кластерам
list.filter { |a| ! medoids.key?(a) }.each do |a|
  m = medoids.keys.max { |m1,m2| data[[a,m1]] <=> data[[a,m2]] }
  medoids[m].push a
end

# Вычислить стоимость ( data, medoids )
max_weight = cost(list,data,medoids)

(1..100).each { |iteration|
  candidat_medoid = nil
  candidat_point = nil

  # SWAP
  medoids.keys.each do |m|
    list.filter { |a| ! medoids.key?(a) }.each do |a|
      tmp_medoids = medoids.clone
      tmp_medoids.delete m
      tmp_medoids[a] = []
      tmp_cost = cost(list, data, tmp_medoids)
      if tmp_cost > max_weight
        max_weight = tmp_cost
        candidat_medoid = m
        candidat_point = a
      end
    end
  end

  break if candidat_point.nil?

  warn "%.2f SWAP %s => %s " % [ max_weight, candidat_medoid, candidat_point ]
  medoids.delete candidat_medoid
  medoids[candidat_point] = []
}


# Разделить системы по кластерам
medoids.each { |k, _| medoids[k] = [] }
list.filter { |a| !medoids.key?(a) }.each do |a|
  m = medoids.keys.max { |m1, m2| data[[a, m1]] <=> data[[a, m2]] }
  medoids[m].push a
end

medoids.each do |medoid,points|
  # puts "[[ %s ]]\n\n" % ( [ medoid,points ].join ", " )
end

idx = 1
medoids.each do |medoid,points|
  puts [medoid,idx].join ';'
  points.each { |p|
    puts [p,idx].join ';'
  }
  idx+=1
end
