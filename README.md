# NAME

Octets::To::Unicode - модуль утилит для распознавания кодировки текста (в том числе в файлах) и его декодирования

# VERSION

0.01

# ARTICLE

Статья на Хабре: https://habr.com/ru/post/664308/.

# SYNOPSIS

        use Octets::To::Unicode;
        
        my $unicode = decode "Стар Трек";
        my ($unicode, $encoding) = decode "Стар Трек";
        my $unicode = decode $octets_in_cp1251_or_maybe_in_utf8, [qw/cp1251 utf-8/];
        
        my $encoding = detect $octets;
        my $encoding = detect $octets, [qw/cp1251 utf-8/];
        
        my ($file_text_in_unicode, $encoding) = file_decode "path/to/file", ["cp1251", "koi8-r"];
        file_encode "path/to/file2", "koi8-r", $file_text_in_unicode;

Использование утилит:

        # Отформатировать указанные файлы perltidy:
        $ ru-perltidy file1 file2

        # Указать кодировку:
        $ ru-perltidy file1 file2 -e utf-8,cp1251

        # Форматирует только изменённые файлы в репозитории git:
        $ ru-perltidy

        # Форматирует изменённые файлы в ветке (на случай, если забыл отформатировать перед комитом):
        $ ru-perltidy --in-branch

        # Указать расширения файлов:
        $ ru-perltidy --ext 'pl,pm,'

        # Перевести файлы во временные в кодировке utf-8 (в /tmp) и после выполнения команды и их изменения переписать обратно в определён
        ной кодировке:
        # (тут $1 - первый файл, $2 - второй и т.д., $* - все файлы через пробел. Так же работают подстановки ${1} и т.д.)
        $ ru-utf8 file1 file2 -c 'perltidy $1 -st > $2'

# DESCRIPTION

Пакет включает в себя утилиты:

- **ru-perltidy** — форматирует файлы через perltidy c определением их кодировки;
- **ru-utf8** — переводит файлы во временные (в кодировке utf-8), выполняет указанную команду и переписывает обратно в определённой кодировке;

и модуль perl:

- **Octets::To::Unicode** — модуль c функциями определения кодировки текста и его конвертирования между кодировками.

**Octets::To::Unicode** предоставляет необходимое множество утилит для определения кодировки текста и его декодирования, а так же — работы с файлами.

В 2000-х определилась тенденция переводить проекты в национальных кодировках в utf-8. Однако не везде их перевели одним махом, а решили рубить собаке хвост постепенно. В результате во многих проектах часть файлов c кодом в utf-8, а часть — в национальной кодировке (cp1251, например).

Ещё одной проблемой могут служить урлы с эскейп-последоваительностями. Например, https://ru.wikipedia.org/wiki/Молчание#Золото преобразуется в мессенджере, куда эту ссылку можно скопировать, в https://ru.wikipedia.org/wiki/%D0%9C%D0%BE%D0%BB%D1%87%D0%B0%D0%BD%D0%B8%D0%B5#%D0%97%D0%BE%D0%BB%D0%BE%D1%82%D0%BE. Причём один мессенджер переведёт русские символы в utf-8, другой — в cp1251, третий — в koi8-r.

Чтобы решить эти две проблемы в приложениях и был написан этот модуль.

# SUBROUTINES/METHODS

## bohemy

    $num = bohemy $unicode;

Возвращает числовую характеристику похожести текста на русский. 

Алгоритм основан на наблюдении, что в русском языке слово начинается на прописную или строчную букву, а затем состоит из строчных букв.

Таким образом, числовая характеристика, это сумма длин русско-похожих слов с разницей суммы длин русско-непохожих.

Принимает параметр:

- **$unicode**

    Текст в юникоде (с взведённым флажком utf8).

## decode

    $unicode = decode $octets, $encodings;
    ($unicode, $encoding) = decode $octets, $encodings;

Возвращает декодированный текст в скалярном контексте, а в списочном, ещё и определённую кодировку. 

Если ни одна из кодировок не подошла, то вместо юникода в первом параметре возвращаются октеты, а вместо кодировки - `undef`:

        ($octets, $encoding_is_undef) = decode $octets, [];

Принимает параметры:

- **$unicode**

    Текст в юникоде (с взведённым флажком utf8).

- **$encodings**

    Cписок кодировок, которыми предлагается попробовать декодировать текст.

    Необязательный. Значение по умолчанию: `[qw/utf-8 cp1251 koi8-r/]`.

## detect

    $encoding = detect $octets, $encodings;

Возвращает определённую кодировку или `undef`.

Параметры такие же как у ["decode"](#decode).

## file\_find

        @files = file_find $path_to_directory;

Ищет файлы в директориях рекурсивно и возвращает список путей к ним.

Принимает параметр:

- **$path\_to\_directory**

    Путь к файлу или директории. Если путь не ведёт к директории, то он просто возвращается в списке.

## file\_read

        $octets = file_read $path;

Считывает файл.

Возвращает текст в октетах.

Выбрасывает исключение, если открыть файл не удалось.

Принимает параметр:

- **$path**

    Путь к файлу.

## file\_write

        file_write $path, $octets_or_unicode;

Перезаписывает файл строкой.

Ничего не возвращает.

Выбрасывает исключение, если открыть файл не удалось.

Принимает параметры:

- **$path**

    Путь к файлу.

- **$octets\_or\_unicode**

    Новое тело файла в октетах или юникоде.

## file\_decode

    $unicode = file_decode $path, $encodings;
    ($unicode, $encoding) = file_decode $path, $encodings;

Возвращает декодированный текст из файла в скалярном контексте, а в списочном, ещё и определённую кодировку. 

Если ни одна из кодировок не подошла, то вместо юникода в первом параметре возвращаются октеты, а вместо кодировки - `undef`:

        ($octets, $encoding_is_undef) = file_decode $path, [];

Принимает параметры:

- **$path**

    Путь к файлу.

- **$encodings**

    Cписок кодировок, которыми предлагается попробовать декодировать текст.

    Необязательный. Значение по умолчанию: `[qw/utf-8 cp1251 koi8-r/]`.

## file\_encode

    file_encode $path, $encoding, $unicode;

Переписывает текст в файле в указанной кодировке.

Принимает параметры:

- **$path**

    Путь к файлу.

- **$encoding**

    Кодировка в которую следует перевести параметр `unicode` перед записью в файл.

- **$unicode**

    Новый текст файла в юникоде (с установленным флажком utf8).

# INSTALL

Установить можно любым менеджером `perl` со **CPAN**, например:

        $ cpm install -g Octets::To::Unicode

# DEPENDENCIES

Зависит от модулей:

- Getopt::Long
- Encode
- List::Util
- Pod::Usage
- Term::ANSIColor

и от **perltidy** опционально:

- Perl::Tidy

# RELEASE

Релиз на **CPAN** осуществляется так:

- Обновить исходники:

            $ git pull
            

- Отредактировать файл \_\_Changes\_\_.

    В файле \_\_Changes\_\_ нужно написать список изменений, которые вошли в этот релиз.

    Изменения записываются в виде списка, одно изменение — один элемент списка. Элементы списка обозначаются символами тире \`-\`.

    Список с изменениями нужно разместить между строкой \`{{$NEXT}}\` и строкой с предыдущим релизом.

    Допустим, предыдущий релиз был 1.71. Тогда описание изменений нового релиза будет выглядеть так:

            {{$NEXT}}
             
                    - RU-5 Какой-то тикет, который вошел в релиз.
                    - RU-6 Ещё один тикет, вошедший в релиз.
             
            1.71 2021-05-07T08:52:18Z
             
                    - RU-4 Какой-то предыдущий тикет.

            Обратите внимание — у нового релиза пока нет версии. Версия будет вычислена Миниллой при выполнении релиза и автоматически вписана в файл CHANGES вместо метки C<{{$NEXT}}>.

- Активировать локальную библиотеку:

            $ cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

            Это нужно, чтобы не выполнять релиз под рутом.

- Выполнить релиз:

            $ minil release
            

    В процессе Минилла задаст несколько вопросов, в частности предложит выбрать номер новой версии.

    Обычно на все вопросы нужно отвечать кнопкой "enter". Иначе лучше прервать процесс и внести изменения в конфигурационные файлы.

# AUTHOR

Yaroslav O. Kosmina <darviarush@mail.ru>

# LICENSE

⚖ **GPLv3**
