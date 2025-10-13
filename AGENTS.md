# HexHub Agent Guidelines

## Commands
- `mix setup` - Install deps and build assets
- `mix phx.server` - Start dev server
- `mix test` - Run all tests (94 tests)
- `mix test test/path/to/file_test.exs` - Run single test file
- `mix test test/path/to/file_test.exs:123` - Run specific test line
- `mix format` - Format code
- `mix assets.build` - Build frontend assets
- `mix assets.deploy` - Build production assets

## Code Style
- Use `@moduledoc` for module documentation
- Define `@type` specs for public functions
- Alias modules at top of file
- Use pattern matching in function heads
- Return `{:ok, result}` or `{:error, reason}` tuples
- Use `@table_name` module attributes for Mnesia tables
- Write descriptive test names with `test "description do"`
- Use `setup` blocks for test isolation
- Follow Phoenix conventions for controllers and components