#!/usr/bin/env bash
set -e

DEFAULT_SOURCE="main"
DEFAULT_CONFIG="Debug"

function usage() {
  echo "Usage: ./dev.sh [build|run|rebuild|clean|format|tidy|leaks|list] " \
       "[file (with or without .c/.cpp)] [--config Debug|Release]"
  echo "Examples:"
  echo "  ./dev.sh run"
  echo "  ./dev.sh run shapes --config Release"
  echo "  ./dev.sh leaks main"
  exit 1
}

function parse_args() {
  FILE="${1:-$DEFAULT_SOURCE}"
  FILE="${FILE%.c}"
  FILE="${FILE%.cpp}"
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

  # Check whether .cpp or .c exists (prefer .cpp)
  if [[ -f "examples/$FILE.cpp" ]]; then
    EXT="cpp"
  else
    EXT="c"
  fi

  FILE_PATH="examples/$FILE.$EXT"
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

  export CC="/opt/homebrew/opt/llvm/bin/clang"
  export CXX="/opt/homebrew/opt/llvm/bin/clang++"

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
  find examples -type f \( -name '*.c' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \) -print0 | xargs -0 clang-format -i
}

function tidy() {
  CONFIG="$DEFAULT_CONFIG"

  # Check for config flag
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

  echo "==> Running clang-tidy on all examples/*.c and *.cpp files..."

  RAYLIB_INCLUDE_DIR=$(brew --prefix raylib)/include
  BUILD_DIR="build-$CONFIG"
  COMPILE_COMMANDS="$BUILD_DIR/compile_commands.json"

  if [ ! -f "$COMPILE_COMMANDS" ]; then
    echo "Compile commands not found. Configuring first..."
    cmake -S . -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$CONFIG"
  fi

  # Run clang-tidy on all .c/.cpp files in examples/
  find examples -type f \( -name '*.c' -o -name '*.cpp' \) | while read -r FILE; do
    echo "==> Linting $FILE"
    clang-tidy "$FILE" -p "$BUILD_DIR" -- -I"$RAYLIB_INCLUDE_DIR"
  done
}

function list() {
  echo "==> Available examples:"
  find examples -type f \( -name '*.c' -o -name '*.cpp' \) | sed 's|examples/||; s|\.[^.]*$||' | sort
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
