# Task runner: https://github.com/casey/just
# Requires: `uv` and `just`.

# List all the justfile recipes.
help:
    just --list --list-prefix 'just '

# Install the dependencies.
install:
    uv sync --dev

# Lint the code with Ruff.
lint:
    uv run ruff format --check .
    uv run ruff check .

# Format the code with Ruff.
format:
    uv run ruff check . --fix
    uv run ruff format .

# Compile the translations (the release workflow does it for the published package).
compilemessages:
    cd src/wagtail_notion_form && uv run django-admin compilemessages

# Needs a clean main and the GitHub CLI (`gh auth login`).
# Release to GitHub, which publishes to PyPI: `just release 0.1.0` or `just release patch|minor|major`.
release version:
    #!/usr/bin/env bash
    set -euo pipefail
    test "$(git branch --show-current)" = main || { echo "Release from main." >&2; exit 1; }
    test -z "$(git status --porcelain)" || { echo "Commit your changes first." >&2; exit 1; }
    # A first release may run before main tracks origin/main.
    if git rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then git pull --ff-only; fi
    case "{{ version }}" in
        major|minor|patch) uv version --bump "{{ version }}" ;;
        *) uv version "{{ version }}" ;;
    esac
    version=$(uv version --short)
    notes=$(mktemp)
    uv run python scripts/release_notes.py "$version" > "$notes"
    git commit -am "Release v$version"
    git push --set-upstream origin main
    # Creates the v$version tag on GitHub; publishing the release runs publish.yml.
    gh release create "v$version" --title "v$version" --notes-file "$notes" --target "$(git rev-parse HEAD)"
    git fetch --tags
