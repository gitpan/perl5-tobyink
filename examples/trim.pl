use perl5-tobyink;

normalize(my @strings = split /\n/, <<STRINGS);
  Hello world
Hello world   
   Hello world   
 Hello    world 
STRINGS

say "[$_]" for @strings;
