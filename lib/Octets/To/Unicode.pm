package Octets::To::Unicode;
use 5.008001;
use utf8;
use strict;
use warnings FATAL => 'all';

our $VERSION = "0.01";

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  grep { *{ $Octets::To::Unicode::{$_} }{CODE} } keys %Octets::To::Unicode::;

use Encode qw//;

#@category Кодировка

# Определяет кодировку. 
# В koi8-r и в cp1251 большие и малые буквы как бы поменялись местами, поэтому у правильной кодировки вес будет больше
sub bohemy($) {
    my ($s) = @_;
    my $c = 0;
    while ( $s =~ /[а-яё]+/gi ) {
        my $x = $&;
        if   ( $x =~ /^[А-ЯЁа-яё][а-яё]*$/ ) { $c += length $x }
        else                                 { $c -= length $x }
    }
    $c;
}

# Определить кодировку и декодировать
sub decode(@) {
    my ( $octets, $encodings ) = @_;

    return if !length $octets;

    utf8::encode($octets) if utf8::is_utf8($octets);

    $encodings //= [qw/utf-8 cp1251 koi8-r/];

    my @x = grep length $_->[0], map {

# В случае ошибки Encode::decode помещает пустую строку в свой второй аргумент. Какой-то баг.
        my $save = $octets;
        eval { [ Encode::decode( $_, $save, Encode::FB_CROAK ), $_ ] };
    } @$encodings;

    my ( $unicode, $mem_encoding );
    ( $unicode, $mem_encoding ) = @{ $x[0] } if @x == 1;

    if ( @x > 1 ) {
        ( $unicode, $mem_encoding ) =
          @{ ( sort { bohemy( $b->[0] ) <=> bohemy( $a->[0] ) } @x )[0] };
    }

    wantarray ? ( $unicode, $mem_encoding ) : $unicode;
}

# Определить кодировку
sub detect(@) {
    ( decode @_ )[1];
}

#@category Вспомогательные функции

# Ищет файлы в директориях рекурсивно
sub file_find($);

sub file_find($) {
    my ($file) = @_;
    if ( -d $file ) {
        $file =~ s!/$!!;
        map file_find($_), <$file/*>;
    }
    else {
        $file;
    }
}

# Чтение бинарного файла
sub file_read($) {
    my ($file) = @_;
    open my $f, "<", $file
      or die "При открытии для чтения $file произошла ошибка: $!.";
    read $f, my $buf, -s $f;
    close $f;
    $buf;
}

# Запись в бинарный файл
sub file_write(@) {
    my ( $file, $unicode ) = @_;

    utf8::encode($unicode) if utf8::is_utf8($unicode);

    open my $f, ">", $file
      or die "При открытии для записи $file произошла ошибка: $!.";
    print $f $unicode;
    close $f;
	return;
}

# Определить кодировку и декодировать файл
sub file_decode(@) {
    my ( $file, $encodings ) = @_;
    decode file_read $file, $encodings;
}

# Кодировать в указанной кодировке и записать в файл
sub file_encode(@) {
    my ( $file, $encoding, $code ) = @_;

    $code = Encode::encode( $encoding, $code ) if defined $encoding;

    file_write $file, $code;
}

1;
__END__

=encoding utf-8

=head1 NAME

Octets::To::Unicode - модуль утилит для распознавания кодировки текста (в том числе в файлах) и его декодирования

=head1 SYNOPSIS

    use Octets::To::Unicode;
	
	my $unicode = decode "Стар Трек";
	my ($unicode, $encoding) = decode "Стар Трек";
	my $unicode = decode $octets_in_cp1251_or_maybe_in_utf8, [qw/cp1251 utf-8/];
	
	my $encoding = detect $octets;
	my $encoding = detect $octets, [qw/cp1251 utf-8/];
	
	my ($file_text_in_unicode, $encoding) = file_decode "path/to/file", ["cp1251", "koi8-r"];
	file_encode "path/to/file2", "koi8-r", $file_text_in_unicode;

=head1 DESCRIPTION

Octets::To::Unicode предоставляет необходимое множество утилит для определения кодировки текста и его декодирования, а так же — работы с файлами.

В 2000-х определилась тенденция переводить проекты в национальных кодировках в utf-8. Однако не везде их перевели одним махом, а решили рубить собаке хвост постепенно. В результате во многих проектах часть файлов c кодом в utf-8, а часть — в национальной кодировке (cp1251, например).

Ещё одной проблемой могут служить урлы с эскейп-последоваительностями. Например, https://ru.wikipedia.org/wiki/Молчание#Золото преобразуется в мессенджере, куда эту ссылку можно скопировать, в https://ru.wikipedia.org/wiki/%D0%9C%D0%BE%D0%BB%D1%87%D0%B0%D0%BD%D0%B8%D0%B5#%D0%97%D0%BE%D0%BB%D0%BE%D1%82%D0%BE. Причём один мессенджер переведёт русские символы в utf-8, другой — в cp1251, третий — в koi8-r.

Чтобы решить эти две проблемы в приложениях и был написан этот модуль.

=head1 SUBROUTINES/METHODS

=head2 bohemy

    $num = bohemy $unicode;

Возвращает числовую характеристику похожести текста на русский. 

Алгоритм основан на наблюдении, что в русском языке слово начинается на прописную или строчную букву, а затем состоит из строчных букв.

Таким образом, числовая характеристика, это сумма длин русско-похожих слов с разницей суммы длин русско-непохожих.

Принимает параметр:

=over 4

=item B<$unicode>

Текст в юникоде (с взведённым флажком utf8).

=back

=head2 decode

    $unicode = decode $octets, $encodings;
    ($unicode, $encoding) = decode $octets, $encodings;

Возвращает декодированный текст в скалярном контексте, а в списочном, ещё и определённую кодировку. 

Если ни одна из кодировок не подошла, то вместо юникода в первом параметре возвращаются октеты, а вместо кодировки - C<undef>:

	($octets, $encoding_is_undef) = decode $octets, [];

Принимает параметры:

=over 4

=item B<$unicode>

Текст в юникоде (с взведённым флажком utf8).

=item B<$encodings>

Cписок кодировок, которыми предлагается попробовать декодировать текст.

Необязательный. Значение по умолчанию: C<[qw/utf-8 cp1251 koi8-r/]>.

=back

=head2 detect

    $encoding = decode $octets, $encodings;

Возвращает определённую кодировку или C<undef>.

Параметры такие же как у L</"decode">.

=head2 file_find

	@files = file_find $path_to_directory;

Ищет файлы в директориях рекурсивно и возвращает список путей к ним.

Принимает параметр:

=item B<$path_to_directory>

Путь к файлу или директории. Если путь не ведёт к директории, то он просто возвращается в списке.

=back

=head2 file_read

	$octets = file_read $path;

Считывает файл.

Возвращает текст в октетах.

Выбрасывает исключение, если открыть файл не удалось.

Принимает параметр:

=item B<$path>

Путь к файлу.

=back

=head2 file_write

	file_write $path, $octets_or_unicode;

Перезаписывает файл строкой.

Ничего не возвращает.

Выбрасывает исключение, если открыть файл не удалось.

Принимает параметры:

=item B<$path>

Путь к файлу.

=item B<$octets_or_unicode>

Новое тело файла в октетах или юникоде.

=back

=head2 file_decode

    $unicode = file_decode $path, $encodings;
    ($unicode, $encoding) = file_decode $path, $encodings;

Возвращает декодированный текст из файла в скалярном контексте, а в списочном, ещё и определённую кодировку. 

Если ни одна из кодировок не подошла, то вместо юникода в первом параметре возвращаются октеты, а вместо кодировки - C<undef>:

	($octets, $encoding_is_undef) = file_decode $path, [];

Принимает параметры:

=over 4

=item B<$path>

Путь к файлу.

=item B<$encodings>

Cписок кодировок, которыми предлагается попробовать декодировать текст.

Необязательный. Значение по умолчанию: C<[qw/utf-8 cp1251 koi8-r/]>.

=back

=head2 file_encode

    file_encode $path, $encoding, $unicode;

Переписывает текст в файле в указанной кодировке.

Принимает параметры:

=over 4

=item B<$path>

Путь к файлу.

=item B<$encoding>

Кодировка в которую следует перевести параметр C<unicode> перед записью в файл.

=item B<$unicode>

Новый текст файла в юникоде (с установленным флажком utf8).


=back

=head1 AUTHOR

Yaroslav O. Kosmina E<lt>darviarush@mail.ruE<gt>

=head1 LICENSE

GPLv3

=cut

