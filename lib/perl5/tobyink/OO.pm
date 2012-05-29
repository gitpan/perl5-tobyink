package perl5::tobyink::OO;

use 5.006;
use strict qw/vars subs/;
no warnings;

our $Mo        = __PACKAGE__.'::Mo';
our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';
our $PREFERRED = undef;

use Scalar::Util;
use Carp;

sub import {
	my $prefer = (shift)->decide;
	
	if ($prefer eq 'Mo') {
		*{(caller(0))[0].'::blessed'} = \&Scalar::Util::blessed;
		*{(caller(0))[0].'::confess'} = \&Carp::confess;
	}
	
	@_ = ($prefer eq $Mo)
		? ($Mo, qw/build builder default is isa required/)
		: ($prefer);
	
	my $import = $prefer->can('import');
	goto $import;
}

sub decide {
	return $PREFERRED if $PREFERRED;
	my ($self) = @_;
	
	$PREFERRED ||= $Any::Moose::PREFERRED
		if $INC{'Any/Moose.pm'} && Any::Moose->any_moose;
	
	$PREFERRED ||= do {
		local $_ = $ENV{PERL_ANY_MO};
		if (/^MOOSE$/i)    { $self->make_moose_available; 'Moose' }
		elsif (/^MOUSE$/i) { $self->make_mouse_available; 'Mouse' }
		elsif (/^MO$/i)    { $self->make_mo_available;    $Mo }
		elsif (/^${Mo}$/i) { $self->make_mo_available;    $Mo }
		elsif (/./)        { warn "PERL_ANY_MO should be Moose/Mouse/Mo!"; undef }
	};
	
	$PREFERRED ||= 'Moose' if $self->moose_is_available;
	$PREFERRED ||= 'Mouse' if $self->mouse_is_available;
	$self->make_mo_available and $PREFERRED ||= $Mo;
	return $PREFERRED;
}

# Moose
sub moose_is_available {
	defined $INC{'Moose.pm'}
		and UNIVERSAL::can('Moose', 'can')
		and Moose->can('import');
}
sub make_moose_available {
	return if (shift)->moose_is_available;
	require Moose; 1
}

# Mouse
sub mouse_is_available {
	defined $INC{'Mouse.pm'}
		and UNIVERSAL::can('Mouse', 'can')
		and Mouse->can('import');
}
sub make_mouse_available {
	return if (shift)->mouse_is_available;
	require Mouse; 1
}

# Mo
my $AMM_available;
sub mo_is_available {
	return 1 if $AMM_available;
	return;
}
sub make_mo_available {
	return if (shift)->mo_is_available;
	no strict;
	my $AMM = do { local $/ = <DATA> }
		or die "Could not load AMM from DATA";
	eval $AMM
		or die "Could not evaluate AMM: $@";
	$AMM_available = 1;
}

__PACKAGE__
__DATA__
package perl5::tobyink::OO::Mo;
$VERSION='0.31';
no warnings;my$M='perl5::tobyink::OO::'.'Mo'.'::';*{$M.Object::new}=sub{bless{@_[1..$#_]},$_[0]};*{$M.import}=sub{my($P,%e,%o)=caller.'::';shift;&{$M.$_.::e}($P,\%e,\%o,\@_)for@_;return if$e{M};%e=(extends,sub{eval"no $_[0]()";@{$P.ISA}=$_[0]},has,sub{my$n=shift;my$m=sub{$#_?$_[0]{$n}=$_[1]:$_[0]{$n}};$m=$o{$_}->($m,$n,@_)for sort keys%o;*{$P.$n}=$m},%e,);*{$P.$_}=$e{$_}for keys%e;@{$P.ISA}=$M.Object};
;package perl5::tobyink::OO::Mo::build;my$M='perl5::tobyink::OO::'."Mo::";
$VERSION=0.31;
*{$M.'build::e'}=sub{my($P,$e)=@_;$e->{new}=sub{$c=shift;my$s=bless{@_},$c;my@B;do{@B=($c.::BUILD,@B)}while($c)=@{$c.::ISA};exists&$_&&&$_($s)for@B;$s}};
;package perl5::tobyink::OO::Mo::builder;my$M='perl5::tobyink::OO::'."Mo::";
$VERSION=0.31;
*{$M.'builder::e'}=sub{my($P,$e,$o)=@_;$o->{builder}=sub{my($m,$n,%a)=@_;my$b=$a{builder}or return$m;sub{$#_?$m->(@_):!exists$_[0]{$n}?$_[0]{$n}=$_[0]->$b:$m->(@_)}}};
;package perl5::tobyink::OO::Mo::default;my$M='perl5::tobyink::OO::'."Mo::";
$VERSION=0.31;
*{$M.'default::e'}=sub{my($P,$e,$o)=@_;$o->{default}=sub{my($m,$n,%a)=@_;$a{default}or return$m;sub{$#_?$m->(@_):!exists$_[0]{$n}?$_[0]{$n}=$a{default}->(@_):$m->(@_)}}};
;package perl5::tobyink::OO::Mo::is;$M='perl5::tobyink::OO::'."Mo::";
$VERSION=0.31;
*{$M.'is::e'}=sub{my($P,$e,$o)=@_;$o->{is}=sub{my($m,$n,%a)=@_;$a{is}or return$m;sub{$#_&&$a{is}eq 'ro'&&caller ne 'Mo::coerce'?die$n.' is ro':$m->(@_)}}};
;package perl5::tobyink::OO::Mo::isa;$M='perl5::tobyink::OO::'."Mo::";
$VERSION=0.31;
$Z=CODE;sub O(_){UNIVERSAL::can(@_,isa)}sub S(&){pop}sub Z{1}sub R(){ref}sub N(){!defined}sub Y(){!N&&!R}our%TC=(Any,\&Z,Item,\&Z,Bool,S{N||0 eq$_||1 eq$_||''eq$_},Undef,\&N,Defined,S{!N},Value,\&Y,Str,\&Y,Num,S{Y&&/^([+-]?\d+|[+-]?(?=\d|\.\d)\d*(\.\d*)?(e([+-]?\d+))?|(Inf(inity)?|NaN))$/i},Int,S{/^\d+$/},Ref,\&R,FileHandle,\&R,Object,S{R&&O},(map{$_.Name,S{Y&&/^\S+$/}}qw/Class Role/),map{my$J=/R/?$_:uc$_;$_.Ref,S{R eq$J}}qw(Scalar Array Hash Code Glob Regexp));sub check{my$v=pop;return eval{$_[0]->($v);1}if ref$_[0]eq$Z;@_=split/\|/,shift;while(@_){(my$t=shift)=~s/^\s+|\s+$//g;if($t=~/^Maybe\[(.+)\]$/){@_=(Undef,$1,@_);next}$t=$1 if$t=~/^(.+)\[/;if(my$k=$TC{$t}){local$_=$v;&$k&&return 1}elsif($t=~/::/){O($v)&&$v->isa($t)&&return 1}else{return 1}}0}sub av{(my$t,$_)=@_;ref($t)eq$Z?$t->($_):${die"not $t\n"if!check@_}}*{$M.isa::e}=S{my($P,$e,$o)=@_;my$C=*{$P.new}{$Z}||*{$M.Object::new}{$Z};*{$P.new}=S{my%a=@_[1..$#_];av(($cx{$P.$_}||next),$a{$_})for keys%a;goto$C};$o->{isa}=S{my($m,$n,%a)=@_;my$V=$cx{$P.$n}=$a{isa}or return$m;S{av$V,$_[1]if$#_;$m->(@_)}}}
;package perl5::tobyink::OO::Mo::required;my$M='perl5::tobyink::OO::'."Mo::";
$VERSION=0.31;
*{$M.'required::e'}=sub{my($P,$e,$o)=@_;$o->{required}=sub{my($m,$n,%a)=@_;if($a{required}){my$C=*{$P."new"}{CODE}||*{$M.Object::new}{CODE};no warnings 'redefine';*{$P."new"}=sub{my$s=$C->(@_);my%a=@_[1..$#_];die$n." required"if!$a{$n};$s}}$m}};
;
