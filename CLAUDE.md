# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HexHub is a private hex package manager and hexdocs server built with Phoenix 1.8.0-rc.4 and Elixir 1.15+. It provides a complete implementation of the Hex API specification for managing Elixir packages, users, repositories, and documentation.

## Key Architecture

- **Phoenix Framework**: Web layer with LiveView for real-time features
- **Tailwind CSS**: Styling with DaisyUI components
- **Bun**: JavaScript bundling and build tooling
- **Bandit**: HTTP server (replacement for Cowboy)
- **Swoosh**: Email functionality

## Common Commands

### Development Setup
```bash
# Install dependencies and setup database
mix setup

# Start development server with live reload
mix phx.server

# Run tests with database setup
mix test
```

### Asset Management
```bash
# Build assets
mix assets.build

# Deploy/minify assets
mix assets.deploy

# Setup asset tools (Tailwind, Bun)
mix assets.setup
```

### Testing
```bash
# Run all tests
mix test

# Run specific test file
mix test test/hex_hub_web/controllers/page_controller_test.exs

# Run tests with coverage
mix test --cover
```

## Project Structure

- `lib/hex_hub/` - Core application logic
- `lib/hex_hub_web/` - Web interface (controllers, views, LiveView)
- `priv/static/` - Compiled static assets
- `assets/` - Source assets (CSS, JS)
- `config/` - Environment-specific configuration
- `test/` - Test files and support modules

## Key Files

- `mix.exs` - Dependencies and project configuration
- `config/config.exs` - General configuration (Tailwind, Bun, Endpoint)
- `lib/hex_hub_web/router.ex` - Route definitions
- `hex-api.yaml` - Complete OpenAPI specification for Hex API

## Environment Configuration

The application uses standard Phoenix configuration with:
- PostgreSQL for data storage
- Bandit as the web server
- Tailwind CSS for styling via `assets/css/app.css`
- Bun for JavaScript bundling
- LiveDashboard available at `/dev/dashboard` in development

## API Implementation

The project implements the complete Hex API specification found in `hex-api.yaml`, including:
- User management
- Package publishing and retrieval
- Documentation hosting
- Repository management
- API key authentication