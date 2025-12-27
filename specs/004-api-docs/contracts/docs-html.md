# Contract: DocsHTML

**Feature**: 004-api-docs
**Module**: `HexHubWeb.DocsHTML`

## Overview

View module for documentation pages. Responsible for:
1. Embedding HEEx templates for documentation pages
2. Parsing and exposing OpenAPI specification data
3. Helper functions for rendering API reference

## Module Attributes

### `@openapi_spec`
OpenAPI specification parsed at compile time from `priv/static/openapi/hex-api.yaml`.

```elixir
@openapi_spec YamlElixir.read_from_file!("priv/static/openapi/hex-api.yaml")
```

## Public Functions

### `openapi_spec/0`
Returns the full OpenAPI specification map.

```elixir
@spec openapi_spec() :: map()
```

---

### `api_info/0`
Returns API metadata from the OpenAPI spec.

```elixir
@spec api_info() :: %{
  title: String.t(),
  version: String.t(),
  description: String.t()
}
```

**Example**:
```elixir
%{
  title: "Hex API",
  version: "1.0.0",
  description: "This is the complete OpenAPI specification..."
}
```

---

### `paths_by_tag/0`
Returns all API endpoints grouped by their OpenAPI tag.

```elixir
@spec paths_by_tag() :: %{
  String.t() => [{path :: String.t(), method :: String.t(), spec :: map()}]
}
```

**Example**:
```elixir
%{
  "Users" => [
    {"/users", "post", %{"summary" => "Create a User", ...}},
    {"/users/{username}", "get", %{"summary" => "Fetch a User", ...}}
  ],
  "Packages" => [...],
  "API Keys" => [...]
}
```

---

### `tags/0`
Returns list of all tags with their descriptions.

```elixir
@spec tags() :: [%{name: String.t(), description: String.t()}]
```

---

### `method_badge_class/1`
Returns DaisyUI badge classes for HTTP method styling.

```elixir
@spec method_badge_class(String.t()) :: String.t()

method_badge_class("get")    # => "badge badge-success"
method_badge_class("post")   # => "badge badge-info"
method_badge_class("put")    # => "badge badge-warning"
method_badge_class("delete") # => "badge badge-error"
method_badge_class(_)        # => "badge badge-neutral"
```

---

### `nav_items/0`
Returns navigation items for the documentation sidebar.

```elixir
@spec nav_items() :: [%{page: atom(), path: String.t(), label: String.t()}]
```

**Returns**:
```elixir
[
  %{page: :index, path: "/docs", label: "Overview"},
  %{page: :getting_started, path: "/docs/getting-started", label: "Getting Started"},
  %{page: :publishing, path: "/docs/publishing", label: "Publishing"},
  %{page: :api_reference, path: "/docs/api-reference", label: "API Reference"}
]
```

## Templates

Embedded from `docs_html/`:

| Template | Description |
|----------|-------------|
| `index.html.heex` | Documentation overview/landing page |
| `getting_started.html.heex` | Mix configuration guide |
| `publishing.html.heex` | Package publishing workflow |
| `api_reference.html.heex` | API endpoints from OpenAPI |

## Component Usage

Templates should use shared navigation component:

```heex
<.docs_layout current_page={@current_page}>
  <!-- Page content -->
</.docs_layout>
```

Where `docs_layout/1` provides:
- Two-column layout (sidebar + content)
- Navigation menu with active state
- Responsive drawer for mobile
