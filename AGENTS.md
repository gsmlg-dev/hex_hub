# HexHub Agent Guidelines

## Commands
- `mix setup` - Install deps and build assets
- `mix phx.server` - Start dev server
- `mix test` - Run all tests
- `mix test test/path/to/file_test.exs` - Run single test file
- `mix test test/path/to/file_test.exs:123` - Run specific test line
- `mix format` - Format code (uses .formatter.exs config)
- `mix assets.build` - Build frontend assets (tailwind + bun for both apps)
- `mix assets.deploy` - Build production assets with minification

## Code Style
- Use `@moduledoc` for module documentation
- Define `@type` specs for public functions with proper types
- Alias modules at top of file after `require` statements
- Use pattern matching in function heads
- Return `{:ok, result}` or `{:error, reason}` tuples consistently
- Use `@table_name` module attributes for Mnesia tables
- Write descriptive test names with `test "description do"`
- Use `setup` blocks for test isolation
- Follow Phoenix conventions for controllers and components
- Import Phoenix deps in formatter, handle HEEX templates

## Active Technologies
- Elixir 1.15+ / OTP 26+ + Phoenix 1.8+, Mnesia (built-in), DaisyUI/Tailwind CSS (006-anonymous-publish-config)
- Mnesia (`:system_settings` or `:publish_configs` table for setting, existing `:users` table for anonymous user) (006-anonymous-publish-config)

## Recent Changes
- 006-anonymous-publish-config: Added Elixir 1.15+ / OTP 26+ + Phoenix 1.8+, Mnesia (built-in), DaisyUI/Tailwind CSS
