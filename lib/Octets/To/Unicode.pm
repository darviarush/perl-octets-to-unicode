package Octets::To::Unicode;
use 5.008001;
use utf8;
use strict;
use warnings FATAL => 'all';

our $VERSION = "0.01";

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = grep { *{$Octets::To::Unicode::{$_}}{CODE} } keys %Octets::To::Unicode::;

use Encode qw//;

#@category Кодировка

# Определяет кодировку. В koi8-r и в cp1251 большие и малые буквы как бы поменялись местами, поэтому у правильной кодировки вес будет больше
sub _bohemy {
	my ($s) = @_;
	my $c = 0;
	while($s =~ /[а-яё]+/gi) {
		my $x = $&;
		if($x =~ /^[А-ЯЁа-яё][а-яё]*$/) { $c++ } else { $c-- }
	}
	$c
}

# Определить кодировку и декодировать
sub decode(@) {
	my ($octets, $encodings) = @_;
	
	return if !length $octets;
	
	utf8::encode($octets) if utf8::is_utf8($octets);
	
	$encodings //= [qw/utf-8 cp1251 koi8-r/];
	
	my @x = grep length $_->[0], map { eval { [ Encode::decode( $_, $octets, Encode::FB_CROAK ), $_ ] } } @$encodings;
	
	my ($unicode, $mem_encoding);
	($unicode, $mem_encoding) = @{$x[0]} if @x == 1;
	
	if(@x > 1) {
		my @r = map _bohemy($_->[0]), @x;
		
		($unicode, $mem_encoding) = @{(sort { _bohemy($b->[0]) <=> _bohemy($a->[0]) } @x)[0]};
		
		print STDERR "??? ", join(", ", @r), "->", join(", ", sort {$b <=> $a} @r), " -> $unicode, $mem_encoding\n";
	}
	
	print "m=$mem_encoding\n";
	
	wantarray? ($unicode, $mem_encoding): $unicode;
}

# Определить кодировку
sub detect(@) {
	(decode @_)[1];
}

#@category Вспомогательные функции

# Ищет файлы в директориях рекурсивно
sub file_find($);
sub file_find($) {
	my ($file) = @_;
	if(-d $file) {
		$file =~ s!/$!!;
		map file_find($_), <$file/*>;
	} else {
		$file
	}
}

# Чтение бинарного файла
sub file_read($) {
	my ($file) = @_;
	open my $f, "<", $file or die "При открытии для чтения $file произошла ошибка: $!.";
	read $f, my $buf, -s $f;
	close $f;
	$buf
}

# Запись в бинарный файл
sub file_write(@) {
	my ($file, $unicode) = @_;
	
	utf8::encode($unicode) if utf8::is_utf8($unicode);
	
	open my $f, ">", $file or die "При открытии для записи $file произошла ошибка: $!.";
	print $f $unicode;
	close $f;
}

# Определить кодировку и декодировать файл
sub file_decode(@) {
	my ($file, $encodings) = @_;
	decode file_read $file, $encodings;
}

# Кодировать в указанной кодировке и записать в файл
sub file_encode(@) {
	my ($file, $encoding, $code) = @_;
	
	$code = Encode::encode( $encoding, $code ) if defined $encoding;
	
	file_write $file, $code;
}

1;
__END__

=encoding utf-8

=head1 NAME

Octets::To::Unicode - модуль утилит

=head1 SYNOPSIS

    use Octets::To::Unicode;

=head1 DESCRIPTION

Ru::Perl::Tidy is ...

=head1 AUTHOR

Yaroslav O. Kosmina E<lt>darviarush@mail.ruE<gt>

=head1 LICENSE

GPLv3

=cut

