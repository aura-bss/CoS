## Запуск на операционных системах семейства Linux (Debian, Ubuntu)

Открываем консоль (терминал)

Установливаем Ruby и пакеты:

    sudo apt update && sudo apt install ruby -y
    sudo gem install sqlite3-ruby ruby-json

Создаём директории repos и data:

    mkdir data repos

Переходим в директорию repos: `cd repos`

Скачиваем необходимые репозитории.

Клонируем интересующий нас репозиторий:

    git clone https://github.com/repo1.git

При необходимости повторяем то же действие с другими репозиториями

Вместо `repo1 repo2` указываем имена всех полученных репозиториев через пробел и выполняем команду:

    for CI in repo1 repo2 ; do cd $CI ; git remote update -p ; git pull ; cd .. ; done

Собираем коммиты со всех репозиториев и сохраняем в файл `allCommits.csv`:

    time . ../allCommits.sh > ../data/allCommits.csv

Обрабатываем коммиты:

    time cat ../data/allCommits.csv | perl -ne 'printf "%s\n", join ";", ( split /;/)[0,1]' | sort -u > ../data/repoCommits.csv

В консоли в этой же директории repos выполняем команду: pwd и копируем ответ в буфер обмена

Открываем файл `../files.rb`

На строке 13 в переменную `chdir` вместо значения `FOLDER` вставляем из буфера обмена и сохраняем файл

Открываем файл `../pathes.rb`

На строке 6 в переменную `work_dir` вместо значения `/tmp/` вставляем из буфера обмена и сохраняем файл

Выполняем команду: 

    time ruby ../files.rb ../data/repoCommits.csv ../data/allFiles.csv

Выполняем команду:

    time cat ../data/allFiles.csv | grep -v '=>' > ../data/allFiles2.csv

Устанавливаем DataGrip для работы с запросами к БД:

    Инструкция: [https://www.jetbrains.com/datagrip/download/#section=linux](https://www.jetbrains.com/datagrip/download/#section=linux)

    При первом запуске программы выбираем тип лицензирования.
    Далее настраиваем подключение к БД Oracle

Открываем консоль DataGrip и и выполняем запрос:

    SELECT p.PKEY, p.PNAME, p.PKEY || '-' || i.ISSUENUM task, t.PNAME,
    ROUND( sum( w.TIMEWORKED ) / 3600.0, 2 ) worklog, i.SUMMARY
    FROM
    JIRACLUSTER.PROJECT p
    JOIN JIRACLUSTER.JIRAISSUE i ON ( p.id = i.PROJECT )
    JOIN JIRACLUSTER.WORKLOG w ON ( i.id = w.issueid )
    JOIN JIRACLUSTER.ISSUETYPE t ON ( i.issuetype = t.ID )
    GROUP BY p.PKEY, p.PNAME, p.PKEY || '-' || i.ISSUENUM, t.PNAME,
    i.SUMMARY ;

Сохраняем результат в файл jiraTaskWorklog.tsv:

    В окне DataGrip в блоке Result нажимаем на выпадающее меню "TSV":
    ![В окне DataGrip в блоке Result нажимаем на выпадающее меню TSV](https://github.com/aura-bss/CoS/blob/master/Screenshot1.png "Screenshot1.png")

    Далее нажимаем на пункт меню "Configure CSV Formats...":
    ![Нажимаем на пункт меню Configure CSV Formats](https://github.com/aura-bss/CoS/blob/master/Screenshot1.png "Screenshot2.png")

    Далее выпадающем меню "Value separator" выбираем пункт "Pipe" нажимаем на кнопку ОК:
    ![В выпадающем меню Value separator выбираем пункт Pipe](https://github.com/aura-bss/CoS/blob/master/Screenshot1.png "Screenshot3.png")

    В окне DataGrip в блоке Result нажимаем на кнопку "Export Data". Далее в поле "Output file" в качестве места сохранения выбираем директорию data в репозитории, указываем имя файла jiraTaskWorklog.tsv и нажимаем кнопку "Export to file":
    ![В окне DataGrip в блоке Result нажимаем на кнопку Export Data](https://github.com/aura-bss/CoS/blob/master/Screenshot1.png "Screenshot4.png")

В консоли Linux переходим в директорию с репозиторием и выполняем команду:

    time cat data/jiraTaskWorklog.tsv | perl -pe ' s|"||g ' | perl -pe " s|'||g " | perl -ne ' printf "%s", join( "|", map { s{\|}{ }g; $_ } split( /\|/,$_,6 ) ) ' > data/jiraTaskWorklog2.csv

В приложении DataGrip в консоли выполняем запрос:

    SELECT p.PKEY || '-' || ISSUENUM as key, i.ISSUETYPE, i.SUMMARY,
    p_name.STRINGVALUE pname,
    actionVal.CUSTOMVALUE activity, productVal.CUSTOMVALUE
    productName
    FROM JIRACLUSTER.JIRAISSUE i
    JOIN JIRACLUSTER.PROJECT p ON ( project=p.id )
    JOIN JIRACLUSTER.ISSUETYPE t ON ( i.issuetype = t.ID )
    LEFT JOIN JIRACLUSTER.CUSTOMFIELDVALUE p_name ON ( i.id =
    p_name.ISSUE AND i.PROJECT=p_name.PROJECT and
    p_name.CUSTOMFIELD=25347 )LEFT JOIN JIRACLUSTER.CUSTOMFIELDVALUE action ON ( i.id =
    action.ISSUE AND i.PROJECT = action.PROJECT and
    action.CUSTOMFIELD=18102 )
    LEFT JOIN JIRACLUSTER.CUSTOMFIELDOPTION actionVal ON
    ( actionVal.id = action.STRINGVALUE )
    LEFT JOIN JIRACLUSTER.CUSTOMFIELDVALUE product ON ( i.id =
    product.ISSUE AND i.PROJECT = product.PROJECT and
    product.CUSTOMFIELD=11009 )
    LEFT JOIN JIRACLUSTER.CUSTOMFIELDOPTION productVal ON
    ( productVal.id = product.STRINGVALUE )
    WHERE p.PKEY = 'PRJ' AND ISSUETYPE=12100 ORDER BY ISSUENUM
    DESC ;

Повторяем шаги сохранения в файл TSV из предыдущих пунктов. В качестве имени файла указываем jiraActivity.tsv

В репозитории создаём пустой файл для БД SQLite:

    touch timeFiles.db

Устанавливаем SQLite:

    sudo apt update && sudo apt install sqlite3 -y

Создаём таблицы в БД и импортируем в них данные:

    sqlite3 timeFiles.db -csv -separator ',' 'create table jiraTaskWorkLog ( pkey varchar, pname varchar, key varchar primary key, type varchar, hours float, summary varchar )'
    
    sqlite3 -csv -separator '|' timeFiles.db '.import data/jiraTaskWorklog2.csv jiraTaskWorkLog'

    sqlite3 timeFiles.db -csv -separator ',' 'create table jiraActivity ( key varchar, summary blob, pname varchar primary key, activity varchar, product varchar )'

    sqlite3 -csv -separator '|' timeFiles.db '.import data/jiraActivity.tsv jiraActivity'

В программе DataGrip добавляем новое подключение к БД timeFiles.db и подключемся к консоли

В консоли выполняем по очереди строки запроса:

    ALTER TABLE jiraActivity ADD activityGroup VARCHAR ;
    UPDATE jiraActivity SET activityGroup = 'Развитие';
    UPDATE jiraActivity SET activityGroup = 'Саппорт' WHERE activity in( 'Лицензии.Саппорт', 'Дефеĸты', 'Внедрение' );

В консоли Linux выполняем команду:

    sqlite3 timeFiles.db -csv -separator '|' 'create table rmiSubsKeys ( mask varchar primary key, subName varchar, subId varchar )'

ДЛЯ ЭТОЙ КОМАНДЫ НЕТ ФАЙЛА:

    sqlite3 -csv -separator '|' timeFiles.db '.import rmiSubsKyes.tsv rmiSubsKeys'

ДЛЯ ЭТОЙ КОМАНДЫ НЕТ ФАЙЛА:

    cat ~/Tmp/РучныеКлючиПодсистем.csv | perl -ne ' ($_,$key,$name,$id) = split /;/; printf qq{INSERT OR REPLACE INTO rmiSubsKeys VALUES ("%s","%s","%s");\n}, $key, $name, $id if $key and $name; ' | sqlite3 -csv -separator ';' timeFiles.db

Создаём таблицы в БД и импортируем в них данные:

    sqlite3 timeFiles.db -csv -separator ';' 'create table gitCommits ( repo varchar, chash varchar primary key , date varchar, datetime bigint, key varchar, author varchar, subject blob )'

    sqlite3 -csv -separator ';' timeFiles.db '.import data/allCommits.csv gitCommits'

    sqlite3 timeFiles.db -csv -separator ';' 'create table gitFiles ( repo varchar, chash varchar, date varchar, added bigint, deleted bigint, file varchar )'
    
    sqlite3 -csv -separator ';' timeFiles.db '.import data/allFiles2.csv gitFiles'

Создаём таблицу gitCommitsAM, далее с помощью запроса к таблице gitCommits для сбора коммитов у ĸоторых есть задачи и файлы с суммой добавленых и удаленных строĸ:

    sqlite3 timeFiles.db 'CREATE TABLE gitCommitsAM AS SELECT c.repo,c.chash,c.date,c.key,c.author,SUM(added) added, SUM(deleted) deleted, COUNT(DISTINCT f.repo || f.file ) files FROM gitCommits c JOIN jiraTaskWorkLog j USING ( key ) JOIN gitFiles f USING ( chash ) WHERE j.hours > 0 GROUP BY 1,2,3,4,5;'

Создаём таблицу jiraTaskWorkLogAM, далее с помощью запроса к таблице jiraTaskWorkLog для сбора задач у ĸоторых есть ĸоммиты с файлами, с числом ĸоммитов, файлов, добавленных и удаленных строĸ: 

    sqlite3 timeFiles.db 'CREATE TABLE jiraTaskWorkLogAM AS SELECT j.pname,j.pkey,j.key,j.type,j.hours, COUNT(DISTINCT chash) commits, SUM(f.added) added, SUM(f.deleted) deleted, COUNT( DISTINCT f.repo||f.file) files FROM jiraTaskWorkLog j JOIN gitCommitsAM c USING ( key ) JOIN gitFiles f USING ( chash ) GROUP BY 1,2,3,4;'

Создаём таблицу gitFilesAM через запрос к таблицам rmiSubsKeys, gitFiles:

    sqlite3 timeFiles.db 'CREATE TABLE gitFilesAM AS SELECT f.date, j.pname, j.pkey, j.key, j.type, f.chash, f.repo, f.file, j.hours * ( 2 * f.added + f.deleted ) / ( j.added * 2 + j.deleted ) hours, ( select subName from rmiSubsKeys s where instr(f.file,s.mask) > 0 order by length(s.mask) desc limit 1 ) as subName, ( select s.mask from rmiSubsKeys s where instr(f.file,s.mask) > 0 order by length(s.mask) desc limit 1 ) as subMask, a.activity, a.activityGroup, a.product FROM gitFiles f JOIN gitCommitsAM using ( chash ) JOIN jiraTaskWorkLogAM j using ( key ) LEFT JOIN jiraActivity a USING ( pname );'

Генерируем отчёт:

    ruby pathes.rb | json_pp > treeView.json

Копируем отчёт на веб-сервер:

    scp -P 2277 treeView.json web-server:/var/www/html/treeView.json

Создаём таблицу dateSubsytem, далее с помощью запроса к таблице gitFilesAM для выборки дней ĸогда изменялись подсистемы (для метоĸ связности и частотности):

    sqlite3 timeFiles.db 'CREATE TABLE dateSubsytem AS SELECT date,subName FROM gitFilesAM GROUP BY 2,1;'

Создаём таблицу taskSubsytem, далее с помощью запроса к таблице gitFilesAM для выборки задач в рамĸах ĸоторых менялась подсистема, с ĸалендарными датами:

    sqlite3 timeFiles.db 'CREATE TABLE taskSubsytem AS SELECT key,subName,min(date) f, max(date) t FROM gitFilesAM GROUP BY 1,2 ;'

Создаём таблицу frequencyClusterSubsystem:

    sqlite3 timeFiles.db -csv -separator ',' 'create table frequencyClusterSubsystem ( subName varchar primary key, frequencyCluster integer, stableCluster integer, tasks integer,days integer,stable_days integer )'

ДЛЯ ЭТОЙ КОМАНДЫ НЕТ ФАЙЛА cluster_frequency.rb:

    sqlite3 -csv -separator ';' timeFiles.db "WITH ddd(subName,days,ldate) AS (SELECT subName, count(distinct date), max(date) FROM dateSubsytem GROUP BY 1 ), ttt(subName,tasks,tdate ) AS ( SELECT subName,count(distinct key),max(t) from taskSubsytem group by 1 ) SELECT subName,tasks,days,ldate from ddd join ttt USING ( subName ) order by tasks desc" | ruby cluster_frequency.rb | sqlite3 -csv -separator ';' timeFiles.db ".import '|cat -' frequencyClusterSubsystem"

Создаём таблицу subsystemTimeCouple:

    sqlite3 timeFiles.db -csv -separator ',' 'create table subsystemTimeCouple ( subNameA varchar, subNameB varchar, timeCouple double )'

ДЛЯ ЭТОЙ КОМАНДЫ НЕТ ФАЙЛА subCorrelation2.rb:

    ruby subCorrelation2.rb | sqlite3 -csv -separator ';' timeFiles.db ".import '|cat -' subsystemTimeCouple"

Обновляем данные в таблице subsystemTimeCouple:

    sqlite3 timeFiles.db -csv -separator ',' 'update subsystemTimeCouple set timeCouple = 0 where timeCouple is null ; update subsystemTimeCouple set timeCouple = 0 where timeCouple = "" '

Создаём таблицу subsystemTaskCouple:

    sqlite3 timeFiles.db -csv -separator ',' 'create table subsystemTaskCouple ( subNameA varchar, subNameB varchar, taskCouple double )'

Выполняем SQL-запрос для выборки совместности подсистем по задачам:

    sqlite3 timeFiles.db -csv -separator ';' "WITH cnt(subName,cnt) AS ( SELECT subName,count(distinct key) from taskSubsytem GROUP BY 1) SELECT t1.subName,t2.subName,1.0 * 19892 * count(distinct t2.key) / ( cnt1.cnt * cnt2.cnt ) FROM taskSubsytem t1 JOIN taskSubsytem t2 ON ( t1.key=t2.key and t1.subName != t2.subName ) JOIN cnt cnt1 ON ( t1.subName=cnt1.subName) JOIN cnt cnt2 ON( t2.subName=cnt2.subName ) WHERE cnt1.cnt >= 100 and cnt2.cnt >= 100 GROUP BY 1,2" | sqlite3 -csv -separator ';' timeFiles.db ".import '|cat -' subsystemTaskCouple"

Создаём таблицу systemFullCouple, далее с помощью запроса к таблице subsystemTimeCouple для выборки совместности подсистем по времени и задачам, с нормированием и среднеĸвадратичесĸой дистанцией:

    sqlite3 timeFiles.db -csv -separator ',' 'CREATE TABLE systemFullCouple AS SELECT subNameA, subNameB, SQRT( 1.0 * ( coalesce(timeCouple,0) * coalesce(timeCouple,0) + coalesce(taskCouple,0) / 70 * coalesce(taskCouple,0) / 70 ) / 2 ) FROM subsystemTimeCouple LEFT JOIN subsystemTaskCouple USING ( subNameA, subNameB ) ORDER BY 3 DESC'

Создаём таблицу fullClusterSubsystem:

    sqlite3 timeFiles.db -csv -separator ',' 'create table fullClusterSubsystem ( subName varchar primary key, joinCluster integer )'

ДЛЯ ЭТОЙ КОМАНДЫ НЕТ ФАЙЛА kmedoidsFull.rb:

    ruby kmedoidsFull.rb | sqlite3 -csv -separator ';' timeFiles.db ".import '|cat -' fullClusterSubsystem"

ДЛЯ ЭТОЙ КОМАНДЫ НЕТ ФАЙЛА kmedoidsLast.rb:

    sqlite3 timeFiles.db -csv -separator ';' "SELECT subName, frequencyCluster, stableCluster, COALESCE(joinCluster,13), COALESCE(usageCluster,7) FROM frequencyClusterSubsystem LEFT JOIN fullClusterSubsystem USING ( subName ) LEFT JOIN usageClusterSubsystem using ( subName ) ORDER BY frequencyCluster + stableCluster + COALESCE(joinCluster,13), COALESCE(usageCluster,7)" | ruby kmedoidsLast.rb

Создаём таблицу lastDevSupportClusterSubsystem:

    sqlite3 timeFiles.db -csv -separator ',' 'create table lastDevSupportClusterSubsystem ( subName varchar primary key, cluster integer )'

Кластеризация развитие и сопровождение
ДЛЯ ЭТОЙ КОМАНДЫ НЕТ ФАЙЛА kmedoidsLast.rb:

    /usr/local/opt/sqlite/bin/sqlite3 timeFiles.db -csv -separator ';' "SELECT subName, frequencyCluster, stableCluster, COALESCE(joinCluster,13), COALESCE(usageCluster,7) FROM frequencyClusterSubsystem LEFT JOIN fullClusterSubsystem USING ( subName ) LEFT JOIN usageClusterSubsystem using ( subName ) ORDER BY frequencyCluster + stableCluster + COALESCE(joinCluster,13), COALESCE(usageCluster,7)" | ruby kmedoidsLast.rb | /usr/local/opt/sqlite/bin/sqlite3 -csv -separator ';' timeFiles.db ".import '|cat -' lastDevSupportClusterSubsystem"

Создаём таблицу lastClusterSubsystem:

    sqlite3 timeFiles.db -csv -separator ',' 'create table lastClusterSubsystem ( subName varchar primary key, cluster integer )'

ДЛЯ ЭТОЙ КОМАНДЫ НЕТ ФАЙЛА kmedoidsLast.rb:

    sqlite3 timeFiles.db -csv -separator ';' "SELECT subName, frequencyCluster, stableCluster, COALESCE(joinCluster,13), COALESCE(usageCluster,7) FROM frequencyClusterSubsystem LEFT JOIN fullClusterSubsystem USING ( subName ) LEFT JOIN usageClusterSubsystem using ( subName ) ORDER BY frequencyCluster + stableCluster + COALESCE(joinCluster,13), COALESCE(usageCluster,7)" | ruby kmedoidsLast.rb | /usr/local/opt/sqlite/bin/sqlite3 -csv -separator ';' timeFiles.db ".import '|cat -' lastClusterSubsystem"

Создаём таблицу lastLegislationClusterSubsystem:

    sqlite3 timeFiles.db -csv -separator ',' 'create table lastLegislationClusterSubsystem ( subName varchar primary key, cluster integer )'

ДЛЯ ЭТОЙ КОМАНДЫ НЕТ ФАЙЛА kmedoidsLast.rb:

    sqlite3 timeFiles.db -csv -separator ';' "SELECT subName, frequencyCluster, stableCluster, COALESCE(joinCluster,13), COALESCE(usageCluster,7) FROM frequencyClusterSubsystem LEFT JOIN fullClusterSubsystem USING ( subName ) LEFT JOIN usageClusterSubsystem using ( subName ) ORDER BY frequencyCluster + stableCluster + COALESCE(joinCluster,13), COALESCE(usageCluster,7)" | ruby kmedoidsLast.rb | sqlite3 -csv -separator ';' timeFiles.db ".import '|cat -' lastLegislationClusterSubsystem"
