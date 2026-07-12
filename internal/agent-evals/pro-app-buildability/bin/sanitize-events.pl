#!/usr/bin/env perl
use strict;
use warnings;

sub sensitive_name {
  my ($name) = @_;
  return $name =~ /^(?:authorization|cookie)$/i ||
    $name =~ /(?:api[_-]?key|access[_-]?key|secret|token|password|passwd|credential|private[_-]?key|license[_-]?key)/i;
}

sub credential_value {
  my ($value) = @_;
  $value =~ s/^\s+|\s+$//g;
  return 0 if !length($value) || $value eq '[REDACTED]' || $value =~ /^[\[{]/;
  return $value !~ /^(?:auto|false|file|keyring|none|null|true|unknown)$/i;
}

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
$content =~ s{([a-z0-9_-]+)(["']?\s*[:=]\s*)(["'])((?:\\.|(?!\3)[^\n])*)\3}{
  my ($name, $separator, $quote, $value) = ($1, $2, $3, $4);
  sensitive_name($name) && credential_value($value)
    ? "$name$separator$quote\[REDACTED\]$quote"
    : $&;
}ige;
$content =~ s{([a-z0-9_-]+)(["']?\s*[:=]\s*)(["'])((?:\\.|(?!\3)[^\n])*)$}{
  my ($name, $separator, $quote, $value) = ($1, $2, $3, $4);
  sensitive_name($name) && credential_value($value)
    ? "$name$separator$quote\[REDACTED\]"
    : $&;
}igem;
$content =~ s{([a-z0-9_-]+)(["']?\s*[:=]\s*)([^"'\s\n][^\n]*)}{
  my ($name, $separator, $value) = ($1, $2, $3);
  sensitive_name($name) && credential_value($value)
    ? "$name$separator\[REDACTED\]"
    : $&;
}ige;
$content =~ s/(-----BEGIN [A-Z ]*PRIVATE KEY-----).*?(-----END [A-Z ]*PRIVATE KEY-----)/\[REDACTED\]/igs;
$content =~ s/-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*/\[REDACTED\]/ig;
$content =~ s/bearer\s+[a-z0-9._~+\/=\-]{12,}/Bearer \[REDACTED\]/ig;
print $content;
