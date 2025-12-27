defmodule HexHubWeb.DocsHTML do
  @moduledoc """
  View module for documentation pages.

  Parses the OpenAPI specification at compile time and provides helper functions
  for rendering API documentation.
  """
  use HexHubWeb, :html

  embed_templates "docs_html/*"

  @openapi_spec YamlElixir.read_from_file!("priv/static/openapi/hex-api.yaml")

  @doc """
  Returns the full OpenAPI specification map.
  """
  def openapi_spec, do: @openapi_spec

  @doc """
  Returns API metadata from the OpenAPI spec.
  """
  def api_info do
    info = @openapi_spec["info"]

    %{
      title: info["title"],
      version: info["version"],
      description: info["description"]
    }
  end

  @doc """
  Returns all API endpoints grouped by their OpenAPI tag.
  """
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

  @doc """
  Returns list of all tags with their descriptions.
  """
  def tags do
    (@openapi_spec["tags"] || [])
    |> Enum.map(fn tag ->
      %{name: tag["name"], description: tag["description"]}
    end)
  end

  @doc """
  Returns DaisyUI badge classes for HTTP method styling.
  """
  def method_badge_class(method) do
    case String.downcase(method) do
      "get" -> "badge badge-success"
      "post" -> "badge badge-info"
      "put" -> "badge badge-warning"
      "patch" -> "badge badge-warning"
      "delete" -> "badge badge-error"
      _ -> "badge badge-neutral"
    end
  end

  @doc """
  Returns navigation items for the documentation sidebar.
  """
  def nav_items do
    [
      %{page: :index, path: "/docs", label: "Overview"},
      %{page: :getting_started, path: "/docs/getting-started", label: "Getting Started"},
      %{page: :publishing, path: "/docs/publishing", label: "Publishing"},
      %{page: :api_reference, path: "/docs/api-reference", label: "API Reference"}
    ]
  end

  @doc """
  Documentation layout component with sidebar navigation.
  """
  attr :current_page, :atom, required: true
  attr :page_title, :string, default: "Documentation"
  slot :inner_block, required: true

  def docs_layout(assigns) do
    ~H"""
    <div class="drawer lg:drawer-open">
      <input id="docs-drawer" type="checkbox" class="drawer-toggle" />
      <div class="drawer-content">
        <!-- Mobile menu button -->
        <div class="lg:hidden sticky top-0 z-30 flex h-16 w-full justify-start bg-base-100 bg-opacity-90 backdrop-blur">
          <label for="docs-drawer" class="btn btn-ghost drawer-button">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              class="inline-block w-6 h-6 stroke-current"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4 6h16M4 12h16M4 18h16"
              >
              </path>
            </svg>
          </label>
          <div class="flex items-center gap-2 px-4">
            <span class="font-bold text-lg">{@page_title}</span>
          </div>
        </div>
        <!-- Page content -->
        <div class="p-6 lg:p-8">
          {render_slot(@inner_block)}
        </div>
      </div>
      <div class="drawer-side z-40">
        <label for="docs-drawer" aria-label="close sidebar" class="drawer-overlay"></label>
        <aside class="bg-base-200 min-h-screen w-64">
          <div class="sticky top-0 z-20 bg-base-200 bg-opacity-90 backdrop-blur">
            <a href="/docs" class="btn btn-ghost normal-case text-xl px-4 py-2">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-6 h-6"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M12 6.042A8.967 8.967 0 006 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 016 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 016-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0018 18a8.967 8.967 0 00-6 2.292m0-14.25v14.25"
                />
              </svg>
              HexHub Docs
            </a>
          </div>
          <ul class="menu menu-md px-4 py-0">
            <%= for item <- nav_items() do %>
              <li>
                <a
                  href={item.path}
                  class={if @current_page == item.page, do: "active", else: ""}
                >
                  {item.label}
                </a>
              </li>
            <% end %>
          </ul>
          <div class="divider px-4"></div>
          <ul class="menu menu-md px-4 py-0">
            <li>
              <a href="/openapi/hex-api.yaml" target="_blank" class="gap-2">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="w-4 h-4"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3"
                  />
                </svg>
                OpenAPI Spec (YAML)
              </a>
            </li>
            <li>
              <a href="/" class="gap-2">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="w-4 h-4"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"
                  />
                </svg>
                Back to Home
              </a>
            </li>
          </ul>
        </aside>
      </div>
    </div>
    """
  end
end
