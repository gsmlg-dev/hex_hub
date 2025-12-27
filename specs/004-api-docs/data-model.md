# Data Model: API Documentation Page

**Feature**: 004-api-docs
**Date**: 2025-12-26
**Status**: Complete

## Overview

The API Documentation feature does not introduce new database entities. All documentation content is:
1. **Static templates** - Getting Started, Publishing guides stored as HEEx templates
2. **Compile-time parsed data** - OpenAPI spec parsed at compile time into Elixir data structures
3. **Static files** - OpenAPI YAML served from `priv/static/`

## Data Structures

### 1. OpenAPI Specification (Compile-time)

The OpenAPI spec is loaded at compile time and stored as a module attribute in `DocsHTML`.

```elixir
# Loaded from hex-api.yaml at compile time
@type openapi_spec :: %{
  "openapi" => String.t(),
  "info" => %{
    "title" => String.t(),
    "version" => String.t(),
    "description" => String.t()
  },
  "servers" => [%{"url" => String.t(), "description" => String.t()}],
  "tags" => [%{"name" => String.t(), "description" => String.t()}],
  "paths" => %{
    String.t() => %{
      String.t() => endpoint_spec()
    }
  },
  "components" => %{...}
}

@type endpoint_spec :: %{
  "tags" => [String.t()],
  "summary" => String.t(),
  "description" => String.t(),
  "operationId" => String.t(),
  "parameters" => [parameter_spec()],
  "requestBody" => request_body_spec() | nil,
  "responses" => %{String.t() => response_spec()}
}
```

### 2. Processed Endpoint Data

For rendering, endpoints are grouped by tag:

```elixir
@type grouped_endpoints :: %{
  String.t() => [
    {
      path :: String.t(),
      method :: String.t(),
      spec :: endpoint_spec()
    }
  ]
}

# Example structure after processing:
%{
  "Users" => [
    {"/users", "post", %{"summary" => "Create a User", ...}},
    {"/users/{username}", "get", %{"summary" => "Fetch a User", ...}}
  ],
  "Packages" => [
    {"/packages", "get", %{"summary" => "List packages", ...}},
    ...
  ]
}
```

### 3. Navigation State

Page navigation is determined by route matching:

```elixir
@type doc_page :: :index | :getting_started | :publishing | :api_reference

# Sidebar navigation items
@nav_items [
  %{page: :index, path: "/docs", label: "Overview"},
  %{page: :getting_started, path: "/docs/getting-started", label: "Getting Started"},
  %{page: :publishing, path: "/docs/publishing", label: "Publishing"},
  %{page: :api_reference, path: "/docs/api-reference", label: "API Reference"}
]
```

## No Database Changes Required

This feature is purely presentational:
- No new Mnesia tables
- No data persistence
- No user-generated content
- All content is either static templates or parsed from `hex-api.yaml`

## File Structure

```text
priv/
└── static/
    └── openapi/
        └── hex-api.yaml      # Moved/copied for static serving

lib/hex_hub_web/
├── controllers/
│   ├── docs_controller.ex    # Route handlers
│   └── docs_html.ex          # View module with OpenAPI parsing
└── controllers/docs_html/
    ├── index.html.heex       # Overview/landing page
    ├── getting_started.html.heex
    ├── publishing.html.heex
    ├── api_reference.html.heex
    └── _nav.html.heex        # Shared navigation component
```

## Data Flow

```
[hex-api.yaml] → [Compile-time parsing] → [@openapi_spec module attr]
                                                    ↓
[Browser Request] → [DocsController] → [DocsHTML] → [HEEx Template]
                                          ↑
                    [paths_by_tag/0] ← [@openapi_spec]
```
