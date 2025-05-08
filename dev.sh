#!/usr/bin/env bash
set -e

DEFAULT_SOURCE="main"
DEFAULT_CONFIG="Debug"

function usage() {
  echo "Usage: ./dev.sh [build|run|rebuild|clean|format|tidy|leaks] " \
       "[file (with or without .c)] [--config Debug|Release]"
  echo "Examples:"
  echo "  ./dev.sh run"
  echo "  ./dev.sh run shapes --config Release"
  echo "  ./dev.sh leaks main"
  exit 1
}

function parse_args() {
  FILE="${1:-$DEFAULT_SOURCE}"
  FILE="${FILE%.c}"  # strip trailing .c if present
  CONFIG="$DEFAULT_CONFIG"
  shift || true
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --config)
        CONFIG="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done
  FILE_PATH="examples/$FILE.c"
}

function build() {
  parse_args "$@"
  BUILD_DIR="build-$CONFIG"
  echo "==> Building $FILE_PATH with config=$CONFIG..."
  GENERATOR=""
  if command -v ninja &> /dev/null; then
    GENERATOR="-G Ninja"
    echo "==> Using Ninja generator"
  fi
  cmake -S . -B "$BUILD_DIR" $GENERATOR \
        -DEXEC_SOURCE="$FILE_PATH" \
        -DCMAKE_BUILD_TYPE="$CONFIG"
  cmake --build "$BUILD_DIR" --target "$FILE"
}

function run() {
  parse_args "$@"
  BUILD_DIR="build-$CONFIG"
  EXEC="./$BUILD_DIR/$FILE"

  if [ ! -f "$EXEC" ]; then
    echo "Executable not found. Building first..."
    build "$FILE" --config "$CONFIG"
  fi

  echo "==> Running $EXEC"
  "$EXEC"
}

function run_with_leaks() {
  parse_args "$@"
  BUILD_DIR="build-$CONFIG"
  EXEC="./$BUILD_DIR/$FILE"

  if [ ! -f "$EXEC" ]; then
    echo "Executable not found. Building first..."
    build "$FILE" --config "$CONFIG"
  fi

  echo "==> Running: leaks --atExit -- $EXEC"
  leaks --atExit -- "$EXEC"
}

function clean() {
  echo "==> Cleaning all build directories..."
  rm -rf build-*
}

function rebuild() {
  clean
  build "$@"
}

function format() {
  echo "==> Formatting source files..."
  find examples -name '*.c' -o -name '*.h' -print0 | xargs -0 clang-format -i
}

function tidy() {
  parse_args "$@"
  echo "==> Running clang-tidy on $FILE_PATH..."

  RAYLIB_INCLUDE_DIR=$(brew --prefix raylib)/include
  BUILD_DIR="build-$CONFIG"
  COMPILE_COMMANDS="$BUILD_DIR/compile_commands.json"

  if [ ! -f "$COMPILE_COMMANDS" ]; then
    echo "Compile commands not found. Configuring first..."
    cmake -S . -B "$BUILD_DIR" -DEXEC_SOURCE="$FILE_PATH" -DCMAKE_BUILD_TYPE="$CONFIG"
  fi

  clang-tidy "$FILE_PATH" -p "$BUILD_DIR" -- -I"$RAYLIB_INCLUDE_DIR"
}

function list() {
  echo "==> Available examples:"
  find examples -type f -name '*.c' | sed 's|examples/||; s|\.c$||' | sort
}

case "$1" in
  build) shift; build "$@" ;;
  run) shift; run "$@" ;;
  clean) clean ;;
  rebuild) shift; rebuild "$@" ;;
  format) format ;;
  tidy) shift; tidy "$@" ;;
  leaks) shift; run_with_leaks "$@" ;;
  list) list ;;
  *) usage ;;
esac
