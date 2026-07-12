#!/usr/bin/env perl
use strict;
use warnings;

my $MAX_INPUT_BYTES = 1_048_576;

sub sensitive_name {
  my ($name) = @_;
  return $name =~ /^(?:authorization|cookie)$/i ||
    $name =~ /(?:api[_-]?key|access[_-]?key|secret|token|password|passwd|credential|private[_-]?key|license[_-]?key)/i ||
    $name =~ /(?:^|[_-])key(?:$|[_-])/i;
}

sub credential_value {
  my ($value) = @_;
  $value =~ s/^\s+|\s+$//g;
  return 0 if !length($value) || $value eq '[REDACTED]';
  return $value !~ /^(?:auto|false|file|keyring|none|null|true|unknown)$/i;
}

sub structured_value_end {
  my ($value, $start) = @_;
  my @stack = (substr($value, $start, 1) eq '{' ? '}' : ']');
  my $quote = '';
  my $escaped = 0;
  for (my $index = $start + 1; $index < length($value); $index++) {
    my $character = substr($value, $index, 1);
    if (length($quote)) {
      if ($escaped) {
        $escaped = 0;
      } elsif ($character eq '\\') {
        $escaped = 1;
      } elsif ($character eq $quote) {
        $quote = '';
      }
    } elsif ($character eq '"' || $character eq "'") {
      $quote = $character;
    } elsif ($character eq '{' || $character eq '[') {
      push @stack, $character eq '{' ? '}' : ']';
    } elsif ($character eq '}' || $character eq ']') {
      return length($value) if !@stack || $character ne $stack[-1];
      pop @stack;
      return $index + 1 unless @stack;
    }
  }
  return length($value);
}

sub redact_structured_sensitive_values {
  my ($value) = @_;
  my $output = '';
  my $cursor = 0;
  while ($value =~ /([a-z0-9_-]+)(["']?\s*[:=]\s*)([\[{])/ig) {
    next unless sensitive_name($1);
    my $start = $+[0] - 1;
    my $end = structured_value_end($value, $start);
    $output .= substr($value, $cursor, $start - $cursor) . '[REDACTED]';
    $cursor = $end;
    pos($value) = $end;
  }
  return $output . substr($value, $cursor);
}

@ARGV <= 1 or die "usage: sanitize-events.pl [INPUT]\n";
my $input;
if (@ARGV) {
  open $input, '<', $ARGV[0] or die "cannot open $ARGV[0]: $!\n";
} else {
  $input = *STDIN;
}
binmode $input;

my $content = '';
while (1) {
  my $remaining = $MAX_INPUT_BYTES - length($content);
  my $chunk = '';
  my $read = read $input, $chunk, $remaining < 65_536 ? $remaining + 1 : 65_536;
  defined $read or die "cannot read sanitizer input: $!\n";
  last if $read == 0;
  if ($read > $remaining) {
    print STDERR "sanitizer input exceeds $MAX_INPUT_BYTES-byte limit\n";
    exit 65;
  }
  $content .= $chunk;
}
close $input if @ARGV;

$content = redact_structured_sensitive_values($content);

for my $variable (qw(EVAL_PRIVATE_DIR EVAL_WORKSPACE EVAL_OUTPUT)) {
  my $value = $ENV{$variable};
  $content =~ s/(?<![A-Za-z0-9._-])\Q$value\E(?=$|[\/\s"',;:)\]}])/<LOCAL_PATH>/g
    if defined $value && length $value;
}
$content =~ s{(?<![A-Za-z0-9._-])/(?:Users|home)/[^/\s"']+(?:/[^\s"']*)?}{<LOCAL_PATH>}g;
$content =~ s{(?<![A-Za-z0-9._-])/root(?:/[^\s"']*)?}{<LOCAL_PATH>}g;
$content =~ s{(?<![A-Za-z0-9._-])/private/tmp(?:/[^\s"']*)?}{<LOCAL_PATH>}g;
$content =~ s{(?<![A-Za-z0-9._-])/tmp/[^\s"']+}{<LOCAL_PATH>}g;
$content =~ s{(?<![A-Za-z0-9._-])/var/folders/[^\s"']+}{<LOCAL_PATH>}g;
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
