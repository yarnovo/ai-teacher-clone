.PHONY: lint format test typecheck all

lint:
	uv run ruff check .

format:
	uv run ruff format .

test:
	uv run pytest

typecheck:
	uv run pyright

all: lint typecheck test