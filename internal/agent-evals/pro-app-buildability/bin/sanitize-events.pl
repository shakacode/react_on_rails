#!/usr/bin/env perl
use strict;
use warnings;

while (<>) {
  s{/Users/[^\s"']+}{<LOCAL_PATH>}g;
  s{/tmp/[^\s"']+}{<LOCAL_PATH>}g;
  s/(authorization["'=: ]+)[^ ,"']+/$1\[REDACTED\]/ig;
  s/(cookie["'=: ]+)[^ ,"']+/$1\[REDACTED\]/ig;
  s/(password["'=: ]+)[^ ,"']+/$1\[REDACTED\]/ig;
  s/((?:api[_-]?key|token|secret|license[_-]?key)["'=: ]+)[^ ,"']+/$1\[REDACTED\]/ig;
  s/(-----BEGIN [A-Z ]*PRIVATE KEY-----).*?(-----END [A-Z ]*PRIVATE KEY-----)/$1\[REDACTED\]$2/g;
  print;
}
