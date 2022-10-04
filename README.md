## Запуск на операционных системах семейства Linux (Debian, Ubuntu)

Открываем консоль (терминал)

Установливаем пакет Ruby

    sudo apt update && sudo apt install ruby -y

Создаём директории repos и data

Переходим в директорию repos: `cd repos`

Скачать необходимые репозитории

Клонируем интересующий нас репозиторий:

    git clone https://github.com/repo1.git

При необходимости повторяем то же действие с другими репозиториями

Вместо `repo1 repo2` указываем имена всех полученных репозиториев через пробел и выполняем команду:

    for CI in repo1 repo2 ; do cd $CI ; git remote update -p ; git pull ; cd .. ; done

Собираем коммиты со всех репозиториев и сохраняем в файл `allCommits.csv`:

    time . ../allCommits.sh > ../data/allCommits.csv

Оборабатываем коммиты:

    cat ../data/allCommits.csv | perl -ne 'printf "%s\n", join ";", ( split /;/)[0,1]' | sort -u > ../data/repoCommits.csv

В консоли в этой же директории repos выполняем команду: pwd и копируем ответ в буфер обмена

Открываем в текстовом редакторе файл `../files.rb`

На строке 13 в переменную `chdir` вместо значения `FOLDER` вставляем из буфера обмена и сохраняем файл

Выполняем команду: 

    ruby ../files.rb ../data/repoCommits.csv ../data/allFiles.csv

Выполняем команду:

    cat ../data/allFiles.csv | grep -v '=>' > ../data/allFiles2.csv
