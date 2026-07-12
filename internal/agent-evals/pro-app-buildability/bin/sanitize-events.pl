#!/usr/bin/env perl
use strict;
use warnings;

while (<>) {
  for my $variable (qw(EVAL_PRIVATE_DIR EVAL_WORKSPACE EVAL_OUTPUT)) {
    my $value = $ENV{$variable};
    s/\Q$value\E/<LOCAL_PATH>/g if defined $value && length $value;
  }
  s{/Users/[^\s"']+}{<LOCAL_PATH>}g;
  s{/private/tmp(?:/[^\s"']*)?}{<LOCAL_PATH>}g;
  s{/tmp/[^\s"']+}{<LOCAL_PATH>}g;
  s{/var/folders/[^\s"']+}{<LOCAL_PATH>}g;
  s/(authorization["'=: ]+)[^ ,"']+/$1\[REDACTED\]/ig;
  s/(cookie["'=: ]+)[^ ,"']+/$1\[REDACTED\]/ig;
  s/(password["'=: ]+)[^ ,"']+/$1\[REDACTED\]/ig;
  s/((?:api[_-]?key|token|secret|license[_-]?key)["'=: ]+)[^ ,"']+/$1\[REDACTED\]/ig;
  s/(-----BEGIN [A-Z ]*PRIVATE KEY-----).*?(-----END [A-Z ]*PRIVATE KEY-----)/$1\[REDACTED\]$2/g;
  print;
}
