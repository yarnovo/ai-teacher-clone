#!/bin/bash

case "$1" in
  lint)
    uv run ruff check .
    ;;
  format)
    uv run ruff format .
    ;;
  test)
    uv run pytest
    ;;
  typecheck)
    uv run pyright
    ;;
  all)
    uv run ruff check . && uv run pyright && uv run pytest
    ;;
  *)
    echo "Usage: $0 {lint|format|test|typecheck|all}"
    exit 1
    ;;
esac