#!/usr/bin/env perl
use strict;
use warnings;
use B qw(SVf_POK svref_2object);
use JSON::PP ();

my $MAX_INPUT_BYTES = 1_048_576;
my $MAX_EVENTS = 5_000;

sub sensitive_name {
  my ($name) = @_;
  return $name =~ /^(?:authorization|cookie)$/i ||
    $name =~ /(?:api[_-]?key|access[_-]?key|secret|token|password|passwd|credential|private[_-]?key|license[_-]?key)/i ||
    $name =~ /(?:^|[_-])key(?:$|[_-])/i;
}

sub credential_value {
  my ($value) = @_;
  return 0 if $value eq '<GENERATED_AT_RUNTIME>';
  $value =~ s/^\s+|\s+$//g;
  return 0 if !length($value) || $value eq '[REDACTED]';
  return $value !~ /^(?:auto|false|file|keyring|none|null|true|unknown)$/i;
}

sub canonicalize_runtime_generated_secret {
  my ($value) = @_;
  $value =~ s{(^|[ \t])SECRET_KEY_BASE="<GENERATED_AT_RUNTIME>"(?=[ \t]|$)}{
    "$1" . 'SECRET_KEY_BASE="[REDACTED]"'
  }gme;
  $value =~ s{(^|[ \t`])SECRET_KEY_BASE=\$\(bin/rails secret\)(?=[ \t]|$)}{
    "$1" . 'SECRET_KEY_BASE="<GENERATED_AT_RUNTIME>"'
  }gme;
  return $value;
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

sub quoted_value_end {
  my ($value, $start, $quote) = @_;
  my $escaped = 0;
  for (my $index = $start; $index < length($value); $index++) {
    my $character = substr($value, $index, 1);
    return $index if !$escaped && $character eq $quote;
    return $index if $character eq "\n";
    $escaped = !$escaped && $character eq '\\';
  }
  return length($value);
}

sub redact_quoted_sensitive_values {
  my ($value) = @_;
  my $output = '';
  my $cursor = 0;
  while ($value =~ /([a-z0-9_-]+)(["']?\s*[:=]\s*)(["'])/ig) {
    my ($name, $separator, $quote) = ($1, $2, $3);
    my $value_start = $+[0];
    my $value_end = quoted_value_end($value, $value_start, $quote);
    my $closed = $value_end < length($value) && substr($value, $value_end, 1) eq $quote;
    my $quoted_value = substr($value, $value_start, $value_end - $value_start);
    if (sensitive_name($name) && credential_value($quoted_value)) {
      $output .= substr($value, $cursor, $value_start - $cursor) . '[REDACTED]';
      $output .= $quote if $closed;
      $cursor = $value_end + ($closed ? 1 : 0);
    }
    pos($value) = $value_end + ($closed ? 1 : 0);
  }
  return $output . substr($value, $cursor);
}

sub sanitize_text {
  my ($content) = @_;
  $content = canonicalize_runtime_generated_secret($content);
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
  $content = redact_quoted_sensitive_values($content);
  $content =~ s{([a-z0-9_-]+)(["']?\s*[:=]\s*)([^"'\s\n][^\n]*)}{
    my ($name, $separator, $value) = ($1, $2, $3);
    sensitive_name($name) && credential_value($value)
      ? "$name$separator\[REDACTED\]"
      : $&;
  }ige;
  $content =~ s/(-----BEGIN [A-Z ]*PRIVATE KEY-----).*?(-----END [A-Z ]*PRIVATE KEY-----)/\[REDACTED\]/igs;
  $content =~ s/-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*/\[REDACTED\]/ig;
  $content =~ s/bearer\s+[a-z0-9._~+\/=\-]{12,}/Bearer \[REDACTED\]/ig;
  return $content;
}

sub scalar_is_string {
  my ($value) = @_;
  return defined($value) && !ref($value) && (svref_2object(\$value)->FLAGS & SVf_POK);
}

sub mark_exact_workspace_path {
  my ($value) = @_;
  my @parts = split /(https?:\/\/[^\s"']+)/i, $value;
  for my $part (@parts) {
    next if $part =~ /^https?:\/\//i;
    # A model-authored placeholder is not runner identity evidence. Demote it
    # before minting the marker that only the exact runner workspace can receive.
    $part =~ s/<EVAL_WORKSPACE>/<LOCAL_PATH>/g;
    my $workspace = $ENV{EVAL_WORKSPACE};
    if (defined $workspace && length($workspace)) {
      $part =~ s/\Q$workspace\E(?=$|[\/\s"',;:)\]}])/<EVAL_WORKSPACE>/g;
    }
  }
  return join '', @parts;
}

sub sanitize_json_value {
  my ($value, $sensitive, $command_value) = @_;
  my $type = ref($value);
  if ($type eq 'HASH') {
    return '[REDACTED]' if $sensitive;
    my %safe;
    for my $key (keys %$value) {
      my $child_sensitive = sensitive_name($key);
      my $child_command_value = $command_value || $key eq 'command';
      $safe{$key} = sanitize_json_value($value->{$key}, $child_sensitive, $child_command_value);
    }
    return \%safe;
  }
  if ($type eq 'ARRAY') {
    return '[REDACTED]' if $sensitive;
    return [map { sanitize_json_value($_, 0, $command_value) } @$value];
  }
  return $value if $type eq 'JSON::PP::Boolean' || !defined($value);
  die "unexpected JSON value type\n" if length($type);

  my $is_string = scalar_is_string($value);
  return '[REDACTED]' if $sensitive && credential_value($value);
  return $is_string ? sanitize_text($command_value ? mark_exact_workspace_path($value) : $value) : $value;
}

sub sanitize_jsonl {
  my ($content) = @_;
  return '' unless length($content);
  my @lines = split /\n/, $content, -1;
  pop @lines if @lines && $lines[-1] eq '';
  if (@lines > $MAX_EVENTS) {
    print STDERR "JSONL input exceeds $MAX_EVENTS-event limit\n";
    exit 65;
  }

  my $json = JSON::PP->new->utf8(1)->canonical(1);
  my @safe_lines;
  for my $index (0 .. $#lines) {
    my $event;
    my $decoded = eval {
      $event = $json->decode($lines[$index]);
      1;
    };
    unless ($decoded) {
      print STDERR 'malformed JSONL event at line ' . ($index + 1) . "\n";
      exit 65;
    }
    unless (ref($event) eq 'HASH') {
      print STDERR 'JSONL event at line ' . ($index + 1) . " is not an object\n";
      exit 65;
    }
    push @safe_lines, $json->encode(sanitize_json_value($event, 0, 0));
  }
  return join('', map { "$_\n" } @safe_lines);
}

my $jsonl_mode = @ARGV && $ARGV[0] eq '--jsonl';
shift @ARGV if $jsonl_mode;
@ARGV <= 1 or die "usage: sanitize-events.pl [--jsonl] [INPUT]\n";
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

print $jsonl_mode ? sanitize_jsonl($content) : sanitize_text($content);
