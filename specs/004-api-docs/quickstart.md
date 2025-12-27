# Quickstart: API Documentation Page

**Feature**: 004-api-docs
**Date**: 2025-12-26

## Prerequisites

- HexHub development environment running
- Branch: `004-api-docs`

## Quick Implementation Steps

### 1. Add Dependency

```elixir
# mix.exs
defp deps do
  [
    # ... existing deps ...
    {:yaml_elixir, "~> 2.11"}
  ]
end
```

```bash
mix deps.get
```

### 2. Copy OpenAPI Spec for Static Serving

```bash
mkdir -p priv/static/openapi
cp hex-api.yaml priv/static/openapi/
```

### 3. Create Controller

```elixir
# lib/hex_hub_web/controllers/docs_controller.ex
defmodule HexHubWeb.DocsController do
  use HexHubWeb, :controller

  def index(conn, _params) do
    render(conn, :index, page_title: "Documentation", current_page: :index)
  end

  def getting_started(conn, _params) do
    render(conn, :getting_started,
      page_title: "Getting Started",
      current_page: :getting_started,
      hex_hub_url: HexHubWeb.PageHTML.hex_hub_url(conn)
    )
  end

  def publishing(conn, _params) do
    render(conn, :publishing,
      page_title: "Publishing Packages",
      current_page: :publishing,
      hex_hub_api_url: HexHubWeb.PageHTML.hex_hub_api_url(conn)
    )
  end

  def api_reference(conn, _params) do
    render(conn, :api_reference,
      page_title: "API Reference",
      current_page: :api_reference,
      endpoints_by_tag: HexHubWeb.DocsHTML.paths_by_tag(),
      api_info: HexHubWeb.DocsHTML.api_info()
    )
  end
end
```

### 4. Create View Module

```elixir
# lib/hex_hub_web/controllers/docs_html.ex
defmodule HexHubWeb.DocsHTML do
  use HexHubWeb, :html

  embed_templates "docs_html/*"

  @openapi_spec YamlElixir.read_from_file!("priv/static/openapi/hex-api.yaml")

  def openapi_spec, do: @openapi_spec

  def api_info do
    info = @openapi_spec["info"]
    %{
      title: info["title"],
      version: info["version"],
      description: info["description"]
    }
  end

  def paths_by_tag do
    @openapi_spec["paths"]
    |> Enum.flat_map(fn {path, methods} ->
      methods
      |> Enum.reject(fn {k, _} -> k == "parameters" end)
      |> Enum.map(fn {method, spec} -> {path, method, spec} end)
    end)
    |> Enum.group_by(fn {_path, _method, spec} ->
      List.first(spec["tags"] || ["Other"])
    end)
    |> Enum.sort_by(fn {tag, _} -> tag end)
  end

  def method_badge_class(method) do
    case String.downcase(method) do
      "get" -> "badge badge-success"
      "post" -> "badge badge-info"
      "put" -> "badge badge-warning"
      "delete" -> "badge badge-error"
      _ -> "badge badge-neutral"
    end
  end

  def nav_items do
    [
      %{page: :index, path: "/docs", label: "Overview"},
      %{page: :getting_started, path: "/docs/getting-started", label: "Getting Started"},
      %{page: :publishing, path: "/docs/publishing", label: "Publishing"},
      %{page: :api_reference, path: "/docs/api-reference", label: "API Reference"}
    ]
  end
end
```

### 5. Add Routes

```elixir
# lib/hex_hub_web/router.ex - add to browser scope
scope "/", HexHubWeb do
  pipe_through :browser

  # ... existing routes ...

  # Documentation routes
  get "/docs", DocsController, :index
  get "/docs/getting-started", DocsController, :getting_started
  get "/docs/publishing", DocsController, :publishing
  get "/docs/api-reference", DocsController, :api_reference
end
```

### 6. Update Home Page Link

```heex
<!-- Change /api/users to /docs -->
<a href="/docs" class="btn btn-outline btn-lg">
  API Documentation
  ...
</a>
```

### 7. Create Templates

Create templates in `lib/hex_hub_web/controllers/docs_html/`:
- `index.html.heex` - Overview page
- `getting_started.html.heex` - Mix configuration guide
- `publishing.html.heex` - Publishing workflow
- `api_reference.html.heex` - API endpoints

### 8. Run Tests

```bash
mix test test/hex_hub_web/controllers/docs_controller_test.exs
```

## Verification Checklist

- [ ] `mix deps.get` succeeds with yaml_elixir
- [ ] `/docs` page renders without errors
- [ ] `/docs/getting-started` shows mix configuration
- [ ] `/docs/publishing` shows publishing workflow
- [ ] `/docs/api-reference` shows all API endpoints grouped by tag
- [ ] Home page "API Documentation" link points to `/docs`
- [ ] OpenAPI YAML downloadable from `/openapi/hex-api.yaml`
- [ ] All pages are responsive (mobile-friendly)
- [ ] Navigation sidebar works correctly
