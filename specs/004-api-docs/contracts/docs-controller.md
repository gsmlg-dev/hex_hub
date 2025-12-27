# Contract: DocsController

**Feature**: 004-api-docs
**Module**: `HexHubWeb.DocsController`

## Overview

HTTP controller handling documentation page requests. All actions render HTML pages using the browser pipeline.

## Actions

### `index/2`
**Route**: `GET /docs`
**Description**: Documentation landing page with overview and quick links to other sections.

**Input**:
- `conn` - Plug.Conn
- `_params` - Map (unused)

**Output**: Rendered HTML page with documentation overview.

**Assigns**:
- `page_title: "Documentation"`
- `current_page: :index`

---

### `getting_started/2`
**Route**: `GET /docs/getting-started`
**Description**: Guide for configuring mix to use HexHub as package mirror.

**Input**:
- `conn` - Plug.Conn
- `_params` - Map (unused)

**Output**: Rendered HTML page with HEX_MIRROR configuration instructions.

**Assigns**:
- `page_title: "Getting Started"`
- `current_page: :getting_started`
- `hex_hub_url: String.t()` - Base URL for configuration examples

---

### `publishing/2`
**Route**: `GET /docs/publishing`
**Description**: Guide for publishing packages to HexHub.

**Input**:
- `conn` - Plug.Conn
- `_params` - Map (unused)

**Output**: Rendered HTML page with publishing workflow documentation.

**Assigns**:
- `page_title: "Publishing Packages"`
- `current_page: :publishing`
- `hex_hub_api_url: String.t()` - API URL for publishing examples

---

### `api_reference/2`
**Route**: `GET /docs/api-reference`
**Description**: Complete API reference generated from OpenAPI specification.

**Input**:
- `conn` - Plug.Conn
- `_params` - Map (unused)

**Output**: Rendered HTML page with all API endpoints grouped by category.

**Assigns**:
- `page_title: "API Reference"`
- `current_page: :api_reference`
- `endpoints_by_tag: %{String.t() => [{path, method, spec}]}`
- `api_info: %{title: String.t(), version: String.t(), description: String.t()}`

## Router Configuration

```elixir
scope "/", HexHubWeb do
  pipe_through :browser

  # Documentation routes
  get "/docs", DocsController, :index
  get "/docs/getting-started", DocsController, :getting_started
  get "/docs/publishing", DocsController, :publishing
  get "/docs/api-reference", DocsController, :api_reference
end
```

## Telemetry Events

Following Constitution Principle VII (Telemetry-First Logging):

```elixir
# Emit on each page view
:telemetry.execute(
  [:hex_hub, :docs, :page_view],
  %{duration: duration_ms},
  %{page: page_name}
)
```
