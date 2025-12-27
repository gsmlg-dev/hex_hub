# Research: API Documentation Page

**Feature**: 004-api-docs
**Date**: 2025-12-26
**Status**: Complete

## Research Areas

### 1. OpenAPI YAML Parsing Libraries for Elixir

**Recommendation**: Use `yaml_elixir` (v2.11.0+)

| Library | Version | License | Notes |
|---------|---------|---------|-------|
| yaml_elixir | 2.11.0 | MIT | Most popular, wraps native Erlang yamerl |
| fast_yaml | 1.0.39 | Apache 2.0 | Native library, performance-focused |
| yamel | - | - | Newer alternative |
| yamerl | - | - | Pure Erlang, used by yaml_elixir |

**yaml_elixir Usage**:
```elixir
# Add to mix.exs
{:yaml_elixir, "~> 2.11"}

# Parse YAML file
{:ok, data} = YamlElixir.read_from_file("priv/static/openapi/hex-api.yaml")
# Returns nested map structure
```

**Decision**: Use `yaml_elixir` - it's the standard choice for Elixir projects, well-maintained, MIT licensed, and already used across the Elixir ecosystem.

Sources:
- [yaml_elixir on Hex.pm](https://hex.pm/packages/yaml_elixir)
- [fast_yaml on Hex.pm](https://hex.pm/packages/fast_yaml)

---

### 2. Existing Documentation Page Patterns in Phoenix

**Existing Patterns in HexHub**:

1. **Controller + View Module Pattern**: All controllers follow the pattern:
   - Controller: `lib/hex_hub_web/controllers/{name}_controller.ex`
   - View module: `lib/hex_hub_web/controllers/{name}_html.ex` with `use HexHubWeb, :html` and `embed_templates "{name}_html/*"`
   - Templates: `lib/hex_hub_web/controllers/{name}_html/*.html.heex`

2. **Layout Pattern**: Uses `<Layouts.app flash={@flash}>` wrapper component from `HexHubWeb.Layouts`

3. **Styling**: DaisyUI components with Tailwind CSS utility classes. Key patterns observed:
   - Cards: `card bg-base-100 shadow-xl`, `card-body`, `card-title`
   - Alerts: `alert alert-info`, `alert alert-warning`
   - Code blocks: `mockup-code` with `<pre data-prefix="n"><code>...</code></pre>`
   - Buttons: `btn btn-primary btn-lg`, `btn btn-outline`
   - Collapsible sections: `collapse collapse-arrow bg-base-200`

4. **Helper Functions**: View modules can define helper functions (see `PageHTML.hex_hub_url/1`, `hex_hub_api_url/1`)

**Decision**: Follow the established controller/view/template pattern. Create `DocsController`, `DocsHTML`, and templates in `docs_html/` directory.

---

### 3. Syntax Highlighting for Code Snippets

**Current Approach in HexHub**:
The home page uses DaisyUI's `mockup-code` component which provides:
- Line numbering via `data-prefix`
- Colored text via CSS classes: `text-success`, `text-info`, `text-comment`
- Terminal-style appearance

**Example**:
```heex
<div class="mockup-code">
  <pre data-prefix="1"><code class="text-success">export</code> <code class="text-info">HEX_MIRROR=...</code></pre>
  <pre data-prefix="2"><code class="text-comment"># Comment text</code></pre>
</div>
```

**Available CSS Classes for Syntax Highlighting**:
- `text-success` - Green (keywords like export, def)
- `text-info` - Blue (values, strings)
- `text-warning` - Orange/yellow
- `text-error` - Red
- `text-primary`, `text-secondary`, `text-accent` - Theme colors
- `text-base-content/70` - Muted text (comments)

**Decision**: Continue using DaisyUI `mockup-code` component with inline CSS classes for manual syntax highlighting. This keeps the implementation simple and consistent with the existing home page.

---

### 4. Anchor Links and Navigation Patterns

**Multi-Page Navigation Requirements**:
- Documentation has 4+ pages (landing, getting-started, publishing, api-reference)
- Need sidebar navigation for quick access between pages
- Within-page anchor links for long pages (especially API reference)

**Recommended Pattern**:

1. **Documentation Layout Component**: Create a dedicated layout or wrapper for docs pages with:
   - Fixed sidebar navigation
   - Active page highlighting
   - Table of contents for current page

2. **DaisyUI Menu Component**:
```heex
<ul class="menu bg-base-200 w-56 rounded-box">
  <li><a class="active">Getting Started</a></li>
  <li><a>Publishing</a></li>
  <li><a>API Reference</a></li>
  <li><a>OpenAPI Spec</a></li>
</ul>
```

3. **Anchor Links**: Use standard HTML anchors with Tailwind's scroll-margin:
```heex
<h2 id="configuration" class="scroll-mt-20">Configuration</h2>
<a href="#configuration" class="link link-hover">Configuration</a>
```

4. **Responsive Design**: Use drawer or off-canvas nav for mobile:
```heex
<div class="drawer lg:drawer-open">
  <input id="docs-drawer" type="checkbox" class="drawer-toggle" />
  <div class="drawer-content">
    <!-- Page content -->
  </div>
  <div class="drawer-side">
    <!-- Sidebar navigation -->
  </div>
</div>
```

**Decision**: Implement a two-column layout (sidebar + content) using DaisyUI drawer component. Each page will have its own template, with navigation highlighting the current page.

---

### 5. OpenAPI to HTML Rendering Pipeline

**Approach**: Server-side parsing and rendering (no client-side JavaScript required)

**Pipeline**:
1. **Load at Compile Time**: Parse `hex-api.yaml` once during compilation and store as module attribute
2. **Group by Tags**: OpenAPI spec has tags (Users, Packages, Releases, etc.) for organization
3. **Render to HEEx**: Generate HTML sections for each endpoint

**Implementation Sketch**:
```elixir
defmodule HexHubWeb.DocsHTML do
  use HexHubWeb, :html

  # Parse OpenAPI at compile time
  @openapi_spec YamlElixir.read_from_file!("priv/static/openapi/hex-api.yaml")

  def openapi_spec, do: @openapi_spec

  def paths_by_tag do
    @openapi_spec["paths"]
    |> Enum.flat_map(fn {path, methods} ->
      Enum.map(methods, fn {method, spec} ->
        {path, method, spec}
      end)
    end)
    |> Enum.group_by(fn {_path, _method, spec} ->
      List.first(spec["tags"] || ["Other"])
    end)
  end
end
```

**Template Rendering**:
```heex
<%= for {tag, endpoints} <- DocsHTML.paths_by_tag() do %>
  <section id={tag} class="mb-8">
    <h2 class="text-2xl font-bold mb-4"><%= tag %></h2>
    <%= for {path, method, spec} <- endpoints do %>
      <div class="card bg-base-100 shadow mb-4">
        <div class="card-body">
          <h3 class="font-mono">
            <span class={method_class(method)}><%= String.upcase(method) %></span>
            <%= path %>
          </h3>
          <p><%= spec["description"] %></p>
        </div>
      </div>
    <% end %>
  </section>
<% end %>
```

**Decision**: Parse OpenAPI YAML at compile time using module attributes. Group endpoints by tags. Render as styled HTML cards. Provide a download link for raw YAML file.

---

## Summary of Decisions

| Area | Decision |
|------|----------|
| YAML Parsing | Add `yaml_elixir` dependency |
| Controller Pattern | Standard Phoenix controller/view/template |
| Syntax Highlighting | DaisyUI `mockup-code` with CSS color classes |
| Navigation | DaisyUI drawer + menu for sidebar |
| OpenAPI Rendering | Compile-time parsing, group by tags, render as HTML cards |
| OpenAPI Download | Serve YAML file from `priv/static/openapi/` |

---

## Dependencies to Add

```elixir
# mix.exs deps
{:yaml_elixir, "~> 2.11"}
```

---

## Routes to Add

```elixir
# In router.ex, browser scope
scope "/", HexHubWeb do
  pipe_through :browser

  get "/docs", DocsController, :index
  get "/docs/getting-started", DocsController, :getting_started
  get "/docs/publishing", DocsController, :publishing
  get "/docs/api-reference", DocsController, :api_reference
end
```

Static file for OpenAPI spec download will be served automatically from `priv/static/openapi/hex-api.yaml`.

---

## Open Questions (Resolved)

1. ~~Should documentation be single page or multi-page?~~ → **Multi-page** (per clarification)
2. ~~Should API reference use Swagger UI or styled HTML?~~ → **Styled HTML** (per clarification)
