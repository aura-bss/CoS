# coding: utf-8

require 'pp'
require 'time'

def stable_day_cluster( days )
  return 1 if days < 60
  return 2 if days < 600
  return 3 if days < 1600
  return 4
end

# Для законодательства
def stable_day_cluster2( days )
  return 1 if days < 85
  return 2 if days < 350
  return 3 if days < 600
  return 4
end


def frequency_cluster(tasks,days)
  tasks = tasks.to_i
  days = days.to_i
  return 4 if tasks < 300 && days < 280
  return 3 if tasks < 490 && days < 600
  return 2 if tasks < 980 && days < 1800
  return 1
end

# Для законодательства
def frequency_cluster2(tasks,days)
  tasks = tasks.to_i
  days = days.to_i
  return 4 if tasks < 7 && days < 12
  return 3 if tasks < 15 && days < 20
  return 2 if tasks < 40 && days < 40
  return 1
end

stop = ["","Микроядро ДБО","Конструктор документов","Служебные утилиты"]
while ln = gets()
  ( subName, tasks, days, date ) = ln.chomp.split( /;/ ).map { |x| x.delete_prefix('"').delete_suffix('"') }
  next if stop.any?(subName)
  stable_days = ((Time.now() - Time.parse(date)) / 86400).to_i
   puts [subName,frequency_cluster(tasks,days),stable_day_cluster(stable_days),tasks,days,stable_days].join ';'
  # puts [subName,frequency_cluster(tasks,days),stable_day_cluster(stable_days)].join ';'
end