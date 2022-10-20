# coding: utf-8

require 'pp'

def distance(a,b)
    (a[0]-b[0]).abs + (a[1]-b[1]).abs + (a[2]-b[2]).abs + (a[3]-b[3]).abs
    # (a[0] <=> b[0]).abs + (a[1] <=> b[1]).abs + (a[2] <=> b[2]).abs
end

def cost(list,data,medoids)
  cost = 0

  # Разделить системы по кластерам
  list.keys.filter { |a| ! medoids.key?(a) }.each do |a|
    m = medoids.keys.min { |m1,m2| data[[a,m1]] <=> data[[a,m2]] }
    cost += data[[a,m]]
  end
  return cost
end

###############################

stop = ["","Микроядро ДБО","Конструктор документов","Служебные утилиты"]

list = Hash.new
while ln=gets
  (a,c1,c2,c3,c4) = ln.chomp.split( /;/ ).map { |x| x.delete_prefix('"').delete_suffix('"') }
  next if stop.any?(a)
  list[a] = [c1.to_i,c2.to_i,c3.to_i,c4.to_i]
end

#pp list
#exit 0

data = Hash.new(0)
list.each do |k1, val1|
  list.each do |k2, val2|
    data[[k1,k2]] += distance(val1,val2)
  end
end


# BUILD
medoids = Hash.new
k = 6

# Выбрать кластера
(1..k).each { |idx|
  min_distance = 1_000_000_000
  min_point = nil
  items = list.keys.filter { |a| ! medoids.key?(a) }
  items.each { |a|
    distance = 0
    items.each { |b|
      distance += data[[a,b]]
    }
    if distance < min_distance
      min_distance = distance
      min_point = a
    end
  }

  medoids[min_point] = []
}

# Разделить системы по кластерам
list.keys.filter { |a| ! medoids.key?(a) }.each do |a|
  m = medoids.keys.min { |m1,m2| data[[a,m1]] <=> data[[a,m2]] }
  medoids[m].push a
end

# Вычислить стоимость ( data, medoids )
min_dist = cost(list,data,medoids)

(1..100).each { |iteration|
  candidat_medoid = nil
  candidat_point = nil

  # SWAP
  medoids.keys.each do |m|
    list.keys.filter { |a| ! medoids.key?(a) }.each do |a|
      tmp_medoids = medoids.clone
      tmp_medoids.delete m
      tmp_medoids[a] = []
      tmp_cost = cost(list, data, tmp_medoids)
      if tmp_cost < min_dist
        min_dist = tmp_cost
        candidat_medoid = m
        candidat_point = a
      end
    end
  end

  break if candidat_point.nil?

  warn "%.2f SWAP %s => %s " % [ min_dist, candidat_medoid, candidat_point ]
  medoids.delete candidat_medoid
  medoids[candidat_point] = []
}


# Разделить системы по кластерам
medoids.each { |k,_| medoids[k] = [] }
list.keys.filter { |a| ! medoids.key?(a) }.each do |a|
  m = medoids.keys.min { |m1,m2| data[[a,m1]] <=> data[[a,m2]] }
  medoids[m].push a
end

medoids.each do |medoid,points|
  #  puts "[[ %s ]]\n\n" % ( [ medoid,points ].join ", " )
end

idx = 1
medoids.each do |medoid,points|
  puts [medoid,idx].join ';'
  points.each { |p|
    puts [p,idx].join ';'
  }
  idx+=1
end
