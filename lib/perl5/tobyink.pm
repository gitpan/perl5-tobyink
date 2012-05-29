package perl5::tobyink;

use 5.010;
use strict 1;
no warnings 1;

use constant {
	true   => !!1,
	false  => !1,
};

use constant {
	read_only  => 'ro',
	read_write => 'rw',
};

use IO::Handle 0;
use Encode 0;

# perl5-hack
sub imports { +__PACKAGE__ }

BEGIN
{
	$perl5::tobyink::AUTHORITY = 'cpan:TOBYINK';
	$perl5::tobyink::VERSION   = '0.001';
}

{
	our $norm = 1;
	our $ltrim = 1;
	our $rtrim = 1;
	
	sub normalize
	{
		if (not defined wantarray)
		{
			for (@_)
			{
				$_ =~ s{^\s+}{}g if $ltrim;
				$_ =~ s{\s+$}{}g if $rtrim;
				$_ =~ s{\s+}{ }g if $norm;
			}
			return;
		}
		
		my @strings = @_;
		for (@strings)
		{
			$_ =~ s{^\s+}{}g if $ltrim;
			$_ =~ s{\s+$}{}g if $rtrim;
			$_ =~ s{\s+}{ }g if $norm;
		}
		
		if (@strings==1 and not wantarray)
		{
			return $strings[0];
		}
		
		return @strings;
	}
	
	sub trim
	{
		local $norm = 0;
		if (defined wantarray)
		{
			return normalize(@_);
		}
		normalize(@_);
		1;
	}

	sub ltrim
	{
		local $norm  = 0;
		local $rtrim = 0;
		if (defined wantarray)
		{
			return normalize(@_);
		}
		normalize(@_);
		1;
	}
	
	sub rtrim
	{
		local $norm  = 0;
		local $ltrim = 0;
		if (defined wantarray)
		{
			return normalize(@_);
		}
		normalize(@_);
		1;
	}
}

sub IMPORT
{
	strict->unimport;
	warnings->unimport;
	
	# stolen from common::sense...
	warnings->import(qw(FATAL closed threads internal debugging pack
	                 portable prototype inplace io pipe unpack malloc
	                 deprecated glob digit printf layer
	                 reserved taint closure semicolon));
	strict->import(qw(subs vars));

	# use feature ':5.10';
	$^H{feature_switch} =
	$^H{feature_say}    =
	$^H{feature_state}  = 1;
	
	my $caller = caller;
	foreach my $e (qw(trim ltrim rtrim normalize true false))
	{
		no strict 'refs';
		*{"$caller\::$e"} = \&{$e};
	}

	if (grep(/^-(class|antlers)$/, @_))
	{
		foreach my $e (qw(read_only read_write))
		{
			no strict 'refs';
			*{"$caller\::$e"} = \&{$e};
		}
	}
	
	if (grep(/^-class$/, @_))
	{
		require perl5::tobyink::OO;
		@_ = $caller;
		goto \&perl5::tobyink::OO::import;
	}
}

use Object::Tap 0 -package => 'UNIVERSAL';

###
### Inject these "use" lines into our caller.
###
use Syntax::Collector 0.003 -collect => q/
use Carp 0 qw(carp croak confess);
use Devel::Assert 0 qw(0);
use List::Util 0 qw(first max min reduce shuffle);
use List::MoreUtils 0 qw(uniq);
use Method::Signatures::Simple 1.00 method_keyword => 'method', function_keyword => 'function';
use Path::Class 0 qw(file dir);
use POSIX 0 qw(floor ceil);
use Scalar::Util 0 qw(blessed isweak looks_like_number refaddr reftype weaken);
use Syntax::Feature::Maybe 0;
use Syntax::Feature::Perform 0;
use Syntax::Feature::Ql 0;
use Syntax::Feature::Qwa 0;
use Try::Tiny 0;
use autodie 0;
no indirect 0 ':fatal';
use mro 0 'c3';
use namespace::sweep 0;
use true 0.14;
use utf8::all 0;
/;

{
	package
	Class::Path::Dir; use overload '@{}', 'children';
}

__FILE__
__END__

=head1 NAME

perl5::tobyink - a lightweight collection of syntax extensions

=head1 SYNOPSIS

 use perl5::tobyink;

=head1 DESCRIPTION

C<< use perl5::tobyink >> is roughly equivalent to:

 use 5.010;
 use autodie;
 use common::sense;
 use constant { false => !1, true => !!1 };
 use mro qw(c3);
 use namespace::sweep;
 use syntax qw(maybe perform ql qwa);
 use true;
 use utf8::all;
 
 no indirect qw(:fatal);
 
 require Encode;
 require IO::Handle;
 
 use Carp qw(carp croak confess);
 use Devel::Assert qw(0);
 use List::Util qw(first max min reduce shuffle);
 use List::MoreUtils qw(uniq);
 use Method::Signatures::Simple 1.00 method_keyword => 'method', function_keyword => 'function';
 use Object::Tap -package => 'UNIVERSAL';
 use Path::Class qw(file dir);
 use POSIX qw(floor ceil);
 use Scalar::Util qw(blessed isweak looks_like_number refaddr reftype weaken);
 use Try::Tiny 0;
 
 *trim      = \&perl5::tobyink::trim;
 *ltrim     = \&perl5::tobyink::ltrim;
 *rtrim     = \&perl5::tobyink::rtrim;
 *normalize = \&perl5::tobyink::normalize;

=head2 Object Oriented Programming

Calling with the parameter "-class", will also act as C<< use Any::Mo >>,
and thus will set up a C<new> method for your package, provide C<has>,
C<extends> and other antlery sugar. 

 {
     package Person;
     use perl5::tobyink -class;
     has name => (is => read_only, isa => 'Str');
     has age  => (is => read_only, isa => 'Num');
 }

With the "-class" parameter, additional constants read_only and read_write
are exported too.

If you'd rather use Moose or Mouse or whatever, then don't pass "-class" and
use Moose/Mouse/whatever manually. The read_only/read_write constants can
be exported using the "-antlers" parameter.

 {
     package Person;
     use perl5::tobyink -antlers;
     use Any::Moose;
     has name => (is => read_only, isa => 'Str');
     has age  => (is => read_only, isa => 'Num');
 } 

=head2 Assertions

You can include assertions in your code a la:

 method set_name ($new)
 {
     assert(length $new > 0);
     $self->{name} = $new;
 }

By default assertions are not checked at all; they are short-circuited
entirely. To have them checked, you need to C<< use Devel::Assert -all >>.
One easy way is to run your script like this:

 perl -MDevel::Assert=-all yourscript.pl

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=perl5-tobyink>.

=head1 SEE ALSO

L<Any::Mo>,
L<autodie>,
L<Carp>,
L<common::sense>,
L<Encode>,
L<Devel::Assert>,
L<indirect>,
L<IO::Handle>,
L<List::Util>,
L<List::MoreUtils>,
L<Method::Signatures::Simple>,
L<mro>,
L<namespace::sweep>,
L<Object::Tap>,
L<Path::Class>,
L<POSIX>,
L<Scalar::Util>,
L<Syntax::Feature::Maybe>,
L<Syntax::Feature::Perform>,
L<Syntax::Feature::Ql>,
L<Syntax::Feature::Qwa>,
L<true>
L<Try::Tiny>,
L<utf8::all>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=begin private

=item C<IMPORT>

=end private
