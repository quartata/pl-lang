#!/usr/bin/perl
# pl

use List::Util qw(first max min reduce sum);
use List::MoreUtils qw(any all);
use Scalar::Util qw(dualvar looks_like_number);
use Text::Soundex;
use feature qw(say switch);

%variables = ();
%commands = (
  7=>(sub { return shift(@_)*shift(@_); }), # multiplication
  15=>(sub { return 2*pop; }),             # double
  19=>(sub { return factorial(pop); }),    # factorial
  29=>(sub { return dualvar(shift(@_),shift(@_)); }), # dualvar
  30=>(sub { $variables{$lastusedvar} = \(deref($variables{$lastusedvar})+1); return; }), # increment last var
  31=>(sub { $variables{$lastusedvar} = \(deref($variables{$lastusedvar})-1); return; }), # decrement last var
  61=>(sub {                               # assignment
     $pointer++;
     $variables{$tokens[$pointer]} = \pop;
     return;
  }),
  127=>(sub {}), # no-op
  135=>(sub { $n = shift(@_); $k = shift(@_); return (factorial($n)/(factorial($k)*factorial($n-$k))); }), # combinations
  137=>(sub { return pop%2; }), # parity
  149=>(sub { return ord(pop); }), # ord
  157=>(sub { $pointer++; skip(); return; }), # else
  158=>(sub { $pointer = -1; return; }), # recurse
  162=>(sub { return chr(pop); }), # chr
  164=>(sub { return "\n"; }), # newline
  165=>(sub { return product(@_); }), # product
  166=>(sub { $x = shift(@_); $y = shift(@_); $array = 1; return \($y =~ /$x/); }), # match
  167=>(sub { $x = shift(@_); $y = shift(@_); $z = shift(@_); $variables{"_"} = \scalar($z =~ s/$x/$y/g); return $z; }), # substitute
  168=>(sub { if(!pop) { skip(); } return; }), # if
  171=>(sub { return 0.5*pop; }), # half
  176=>(sub { $array = 1; return \unpack(shift(@_), shift(@_)); }), # unpack
  177=>(sub { return pack(shift(@_), shift(@_)); }), # pack
  196=>(sub { return shift(@_)-shift(@_); }), # subtraction
  197=>(sub { return shift(@_)+shift(@_); }), # addition
  208=>(sub { foreach(@_) { push(@arguments,$_);  } return; }), # flatten
  228=>(sub { return sum(@_); }), # sum
  238=>(sub { return looks_like_number(pop); }), # quack
  240=>(sub { return isPrime(pop); }),        # primality
  244=>(sub { $x = pop(@arguments); $y = pop(@arguments); push(@arguments,$x); push(@arguments,$y); return; }), # swap
  245=>(sub { @arguments = reverse(@arguments); }), # reverse
  246=>(sub { return shift(@_)/shift(@_); }), # division
  252=>(sub { return shift(@_)**shift(@_); }), # exponent
  254=>(sub { $array = 1; return [0,0]; }) # test
);
%arities = (
  7=>2,
  15=>1,
  19=>1,
  29=>2,
  30=>0,
  31=>0,
  61=>1,
  127=>0,
  135=>2,
  137=>1,
  149=>1,
  157=>0,
  158=>0,
  162=>1,
  164=>0,
  165=>1,
  166=>2,
  167=>3,
  168=>1,
  171=>1,
  176=>2,
  177=>2,
  196=>2,
  197=>2,
  208=>1,
  223=>0,
  228=>1,
  238=>1,
  240=>1,
  244=>0,
  245=>0,
  246=>2,
  252=>2
);

@tokens = ();
@arguments = ();
$pointer = 0;
$lastusedvar = "_";
$array = 0;

given(<>) {
  @tokens = split("",$_);
  $variables{"_"} = \<STDIN>; # i can't believe this works
  for(;$pointer < scalar(@tokens);$pointer++) {
    $token = $tokens[$pointer];
    $code = ord($token);
    if($code >= 48 and $code <= 57) { # beginning of a numeral
      push(@arguments,stringParse(3));
    } elsif($code >= 33 and $code <= 126 and $code != 61 and $code != 34 and $code != 39) {
      $ref = $variables{$token};
      if(exists($variables{$token})) {
        push(@arguments,deref($ref)); # push variable
        $lastusedvar = $token;
      } else {
        push(@arguments,stringParse(1)); # implict string
      }
    } else {
      if(exists($commands{$code})) { # command
        $arity = $arities{$code};
        @needed = ();
        for($counter = $arity;$counter > 0 and scalar(@arguments) > 0;$counter--) {
          push(@needed,pop(@arguments)); # pop the arguments we need
        }
        @needed = reverse(@needed);
        if(scalar(@needed) + 1 == $arity) {
          push(@needed,deref($variables{"_"})); # add default var if we're off by one
        } elsif(scalar(@needed) < $arity) {
          continue; # give up if we don't have enough
        }
        $result = &{$commands{$code}}(@needed);
        if(defined($result)) {
          if($array) {
            $array = 0;
            push(@arguments, @$result); # place result on stack
          } else {
            push(@arguments, $result);
          }
        }
      } else {
        if($code == 34) { # regular string
          $pointer++;
          push(@arguments,stringParse(0));
        } elsif($code == 39) { # one char string
          $pointer++;
          push(@arguments,stringParse(2));
        }
      }
    }
  }
  if(scalar(@arguments) == 0) { 
    print deref($variables{"_"}); # print default var if the stack is empty
  } else {
    print join("",@arguments); # print stack otherwise
  }
}


# mode 0 is regular strings
# mode 1 is implict strings
# mode 2 is one-char strings
# mode 3 is numerals
sub stringParse {
  my @string = ();
  my $mode = pop;
  if($mode == 1) {
    while(ord($tokens[$pointer]) >= 32 and ord($tokens[$pointer]) <= 126 and $tokens[$pointer] ne '"' and !exists($variables{$tokens[$pointer]}) and $pointer < scalar(@tokens)) {
      push(@string, $tokens[$pointer]);
      $pointer++;
    }
    if($tokens[$pointer] ne '"') { $pointer--; }
  } elsif($mode == 0) {
    while($tokens[$pointer] ne '"' and $pointer < scalar(@tokens)) {
      push(@string, $tokens[$pointer]);
      $pointer++; 
    }
  } elsif($mode == 2) {
    push(@string, $tokens[$pointer]);
  } elsif($mode == 3) {
    while(ord($tokens[$pointer]) >= 48 and ord($tokens[$pointer]) <= 57) {
      push(@string, $tokens[$pointer]);
      $pointer++;
    }
    $pointer--;
  }
  return join("",@string);
}


# handy function for dereferencing
# we use this quite a bit since we need to use references to store non-scalars
# in a hash
sub deref {
  my $ref = pop;
  my $type = ref $ref;
  if($type eq "ARRAY") {
    return @{$ref};
  } elsif($type eq "HASH") {
    return %{$ref};
  } else {
    return ${$ref};
  }
}

sub factorial {
  if($_[0] == 0) { return 1; }
  return reduce(sub {$a * $b}, 1..pop);
}

# lazy trial division up to sqrt(n)
# replace with something that doesn't suck later
sub isPrime {
  my $num = shift(@_);
  my $s = int(sqrt($num));
  if($num <= 2) { return ($num == 2 ? 1 : 0); } 
  for(my $c = 2; $c <= $s; $c++) {
    if(($num % $c) == 0) { return 0; }
  }
  return 1;
}

sub skip {
  while(ord($tokens[$pointer]) != 157 and ord($tokens[$pointer]) != 127 and $pointer < scalar(@tokens)) {
    $pointer++;
  }
}

sub product {
  return reduce(sub { $a * $b }, @_);
}
