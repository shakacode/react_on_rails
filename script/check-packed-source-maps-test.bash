#!/usr/bin/env bash
# Test harness for script/check-packed-source-maps.mjs. Self-contained:
# requires bash, tar, and node. Run with
# `bash script/check-packed-source-maps-test.bash`.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKER="$SCRIPT_DIR/check-packed-source-maps.mjs"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

TESTS_FAILED=0

# make_tarball NAME FILE=CONTENT... builds $WORK_DIR/NAME.tgz with a package/ root.
make_tarball() {
  local name="$1"
  shift
  local root="$WORK_DIR/$name/package"
  mkdir -p "$root"
  local spec
  for spec in "$@"; do
    mkdir -p "$(dirname "$root/${spec%%=*}")"
    printf '%b' "${spec#*=}" > "$root/${spec%%=*}"
  done
  tar -czf "$WORK_DIR/$name.tgz" -C "$WORK_DIR/$name" package
}

# expect NAME EXPECTED_EXIT EXPECTED_OUTPUT_SUBSTRING
expect() {
  local name="$1" expected_exit="$2" needle="$3" output status
  output="$(node "$CHECKER" "$WORK_DIR/$name.tgz" 2>&1)"
  status=$?
  if [[ "$status" -ne "$expected_exit" || "$output" != *"$needle"* ]]; then
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL $name: expected exit $expected_exit with '$needle', got exit $status: $output" >&2
  else
    echo "ok $name"
  fi
}

make_tarball clean 'lib/index.js=export {};\n' 'lib/index.d.ts=export {};\n'
expect clean 0 'no dangling sourceMappingURL pointers'

make_tarball dangling-js 'lib/index.js=export {};\n//# sourceMappingURL=index.js.map\n'
expect dangling-js 1 'lib/index.js -> index.js.map'

make_tarball dangling-dts 'lib/sub/a.d.ts=export {};\n//# sourceMappingURL=a.d.ts.map\n'
expect dangling-dts 1 'lib/sub/a.d.ts -> a.d.ts.map'

make_tarball shipped-map 'lib/index.js=export {};\n//# sourceMappingURL=index.js.map\n' 'lib/index.js.map={}\n'
expect shipped-map 0 'no dangling sourceMappingURL pointers'

make_tarball inline-map 'lib/index.js=export {};\n//# sourceMappingURL=data:application/json;base64,e30=\n'
expect inline-map 0 'no dangling sourceMappingURL pointers'

# Code that merely mentions the comment syntax is not a pointer.
make_tarball mention 'lib/index.js=const re = /\\/\\/# sourceMappingURL=(\\S+)/;\n'
expect mention 0 'no dangling sourceMappingURL pointers'

if [[ "$TESTS_FAILED" -ne 0 ]]; then
  echo "$TESTS_FAILED test(s) failed" >&2
  exit 1
fi
echo "All check-packed-source-maps tests passed"
