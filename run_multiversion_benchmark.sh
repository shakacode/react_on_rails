#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARK_SCRIPT="$SCRIPT_DIR/benchmark_multiversion.rb"

# Ruby versions to test (official Docker images)
RUBY_VERSIONS=("3.0" "3.1" "3.2" "3.3")

echo "========================================"
echo "Multi-Version Ruby JSON Benchmark"
echo "========================================"
echo

for version in "${RUBY_VERSIONS[@]}"; do
    echo "========================================"
    echo "Testing Ruby $version"
    echo "========================================"

    docker run --rm -v "$BENCHMARK_SCRIPT:/benchmark.rb:ro" \
        "ruby:$version" \
        ruby /benchmark.rb 2>&1

    echo
    echo
done

echo "========================================"
echo "All versions tested!"
echo "========================================"
