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

sub decode_url_name {
  my ($value) = @_;
  $value =~ tr/+/ /;
  $value =~ s/%([0-9a-f]{2})/chr(hex($1))/ige;
  return $value;
}

sub redact_url_parameters {
  my ($value) = @_;
  my @parameters = split /&/, $value, -1;
  for my $parameter (@parameters) {
    my $equals = index($parameter, '=');
    next if $equals < 0;
    my $name = decode_url_name(substr($parameter, 0, $equals));
    $parameter = substr($parameter, 0, $equals + 1) . '[REDACTED]' if sensitive_name($name);
  }
  return join '&', @parameters;
}

sub redact_url_credentials {
  my ($url) = @_;
  my $scheme_end = index($url, '://') + 3;
  my $remainder = substr($url, $scheme_end);
  my $authority_length = $remainder =~ m{[/?#]} ? $-[0] : length($remainder);
  my $authority_end = $scheme_end + $authority_length;
  my $authority = substr($url, $scheme_end, $authority_length);
  my $at = rindex($authority, '@');
  if ($at >= 0) {
    my $colon = index($authority, ':');
    if ($colon >= 0 && $colon < $at) {
      substr($authority, $colon + 1, $at - $colon - 1, '[REDACTED]');
      $url = substr($url, 0, $scheme_end) . $authority . substr($url, $authority_end);
    }
  }
  $remainder = substr($url, $scheme_end);
  $authority_length = $remainder =~ m{[/?#]} ? $-[0] : length($remainder);
  $authority_end = $scheme_end + $authority_length;
  my $query = index($url, '?', $authority_end);
  my $fragment = index($url, '#', $authority_end);
  if ($query >= 0) {
    my $query_end = $fragment >= 0 ? $fragment : length($url);
    my $parameters = redact_url_parameters(substr($url, $query + 1, $query_end - $query - 1));
    $url = substr($url, 0, $query + 1) . $parameters . substr($url, $query_end);
  }
  $fragment = index($url, '#', $authority_end);
  if ($fragment >= 0) {
    $url = substr($url, 0, $fragment + 1) . redact_url_parameters(substr($url, $fragment + 1));
  }
  return $url;
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
$content =~ s{https?://[^\s"']+}{redact_url_credentials($&)}ige;

my @path_parts = split /(https?:\/\/[^\s"']+)/i, $content;
for my $part (@path_parts) {
  next if $part =~ /^https?:\/\//i;
  for my $variable (qw(EVAL_PRIVATE_DIR EVAL_WORKSPACE EVAL_OUTPUT)) {
    my $value = $ENV{$variable};
    $part =~ s/\Q$value\E(?=$|[\/\s"',;:)\]}])/<LOCAL_PATH>/g if defined $value && length $value;
  }
  $part =~ s{/(?:Users|home)/[^/\s"']+(?:/[^\s"']*)?}{<LOCAL_PATH>}g;
  $part =~ s{/root(?:/[^\s"']*)?}{<LOCAL_PATH>}g;
  $part =~ s{/private/tmp(?:/[^\s"']*)?}{<LOCAL_PATH>}g;
  $part =~ s{/tmp/[^\s"']+}{<LOCAL_PATH>}g;
  $part =~ s{/var/folders/[^\s"']+}{<LOCAL_PATH>}g;
}
$content = join '', @path_parts;
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
