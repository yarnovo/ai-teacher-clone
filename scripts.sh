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
  dev)
    uv run uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
    ;;
  start)
    uv run uvicorn src.main:app --host 0.0.0.0 --port 8000
    ;;
  *)
    echo "Usage: $0 {lint|format|test|typecheck|all|dev|start}"
    exit 1
    ;;
esac