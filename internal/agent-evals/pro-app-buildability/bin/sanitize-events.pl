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
$content =~ s{([a-z0-9_-]+)(["']?\s*[:=]\s*["']?)([^,"'\n]+)}{
  my ($name, $separator, $value) = ($1, $2, $3);
  my $sensitive = $name =~ /^(?:authorization|cookie)$/i ||
    $name =~ /(?:api[_-]?key|access[_-]?key|secret|token|password|passwd|credential|private[_-]?key|license[_-]?key)/i;
  $sensitive ? "$name$separator\[REDACTED\]" : "$name$separator$value";
}ige;
$content =~ s/(-----BEGIN [A-Z ]*PRIVATE KEY-----).*?(-----END [A-Z ]*PRIVATE KEY-----)/$1\[REDACTED\]$2/igs;
print $content;
