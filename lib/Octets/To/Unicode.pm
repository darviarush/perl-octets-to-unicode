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

# Определить кодировку и декодировать
sub decode(@) {
	my ($octets, $encodings) = @_;
	
	utf8::encode($octets) if utf8::is_utf8($octets);
	
	$encodings //= [qw/utf-8 cp1251 koi8-r/];
	
	my $mem_encoding;
	
	for my $encoding ( @$encodings ) {
		eval {
			$octets = Encode::decode( $encoding, $octets, Encode::FB_CROAK );
			$mem_encoding = $encoding;
		};
		last if !$@;
	}
	
	wantarray? ($octets, $mem_encoding): $octets;
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
		my @file;
		my @dir = <$file/*>;
		shift @dir;
		return @file, map file_find($_), @dir;
	} else {
		print "file=$file\n";
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

