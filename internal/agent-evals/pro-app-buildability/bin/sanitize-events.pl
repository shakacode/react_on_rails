#!/usr/bin/env perl
use strict;
use warnings;

local $/;
my $content = <>;

for my $variable (qw(EVAL_PRIVATE_DIR EVAL_WORKSPACE EVAL_OUTPUT)) {
  my $value = $ENV{$variable};
  $content =~ s/\Q$value\E/<LOCAL_PATH>/g if defined $value && length $value;
}
$content =~ s{/Users/[^\s"']+}{<LOCAL_PATH>}g;
$content =~ s{/private/tmp(?:/[^\s"']*)?}{<LOCAL_PATH>}g;
$content =~ s{/tmp/[^\s"']+}{<LOCAL_PATH>}g;
$content =~ s{/var/folders/[^\s"']+}{<LOCAL_PATH>}g;
$content =~ s/(authorization["'=: ]+)[^,"'\n]+/$1\[REDACTED\]/ig;
$content =~ s/(cookie["'=: ]+)[^,"'\n]+/$1\[REDACTED\]/ig;
$content =~ s/(password["'=: ]+)[^,"'\n]+/$1\[REDACTED\]/ig;
$content =~ s/((?:api[_-]?key|token|secret|license[_-]?key)["'=: ]+)[^,"'\n]+/$1\[REDACTED\]/ig;
$content =~ s/(-----BEGIN [A-Z ]*PRIVATE KEY-----).*?(-----END [A-Z ]*PRIVATE KEY-----)/$1\[REDACTED\]$2/igs;
print $content;
