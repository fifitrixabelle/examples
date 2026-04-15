# Python Project

## Description
This project demonstrates the use of `pydantic` models, asynchronous functions, and testing in Python.

## Setup
1. **Install dependencies:**
   ```bash
   uv sync
   # or
   just install
   ```

2. **Run tests:**
   ```bash
   just test
   # or
   uv run pytest
   ```

3. **Run the application:**
   ```bash
   just run
   # or
   uv run python main.py
   ```

## Development Commands (using Just)

This project uses [Just](https://github.com/casey/just) as a command runner. Run `just` or `just --list` to see available commands:

- `just test` - Run tests with pytest
- `just test-verbose` - Run tests with verbose output
- `just lint` - Check code with ruff
- `just format` - Format code with ruff
- `just check` - Run both linting and tests
- `just run` - Run the main application
- `just clean` - Clean up cache files
- `just update` - Update dependencies
- `just all` - Install, check, and format everything

## Usage
The application generates random `Person` objects using `faker`, assigns them a unique ID, and prints their details.

## Dependencies
- duckdb
- faker
- pendulum
- playwright
- pydantic
- uuid7
- ruff
- streamlit
- uplot
- watchdog

## License
This project is licensed under the MIT License.
