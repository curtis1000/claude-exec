# Contributing

## Development Setup

### Prerequisites

- Python 3.x
- [pre-commit](https://pre-commit.com/)
- [shellcheck](https://www.shellcheck.net/)
- [hadolint](https://github.com/hadolint/hadolint)

### Install pre-commit hooks

```bash
pip install pre-commit
pre-commit install
```

Once installed, hooks run automatically on `git commit`.

## Linting

This project uses [pre-commit](https://pre-commit.com/) to run linters on staged files.

### Run all linters manually

```bash
pre-commit run --all-files
```

### Linters configured

| Linter | Files | Config |
|--------|-------|--------|
| [shellcheck](https://www.shellcheck.net/) | `*.sh` | CLI args |
| [hadolint](https://github.com/hadolint/hadolint) | `Containerfile`, `Dockerfile` | `.hadolint.yaml` |
| [markdownlint](https://github.com/DavidAnson/markdownlint) | `*.md` | `.markdownlint.yaml` |

### Additional checks

- Trailing whitespace removal
- End-of-file newline enforcement
- YAML validation
- Large file detection
- Merge conflict markers
- Private key detection
- Shebang validation
