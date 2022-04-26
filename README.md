# NAME

perl-octets-to-unicode — утилиты для конвертирования файлов и строк в utf8.

# SYNOPSIS

```sh
# Отформатировать указанные файлы perltidy:
$ ru-perltidy file1 file2

# Указать кодировку:
$ ru-perltidy file1 file2 -c utf-8,cp1251

# Форматирует только изменённые файлы в репозитории git:
$ ru-perltidy --git

# Форматирует изменённые файлы в последнем комите (на случай, если забыл отформатировать перед комитом):
$ ru-perltidy --git-head

# Создать временные файлы в кодировке utf-8 в /tmp и после изменения переписать обратно в определённой кодировке:
$ ru-conv file1 file2 by perltidy {} 

```

```perl
# В пёрле:
use Octets::To::Unicode qw/detect decode/;

# Определить кодировку из указанной последовательности:
my $codepage = detect($octets, [qw/utf-8 cp1251 koi8-r/]);

use Encode;

my $unicode = Encode::decode($codepage, $octets);

# Определить кодировку и декодировать:
my $utf8 = decode($octets, [qw/utf-8 cp1251 koi8-r/]);

die "Что-то пошло не так!" if $utf8 ne $unicode;
```

# DESCRIPTION

Octets::To::Unicode — модуль для конвертирования 

# AUTHOR

Yaroslav O. Kosmina <darviarush@mail.ru>

# LICENSE

⚖ **GPLv3**