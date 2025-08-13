defmodule HexHubAdminWeb.Layouts do
  use HexHubAdminWeb, :html

  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <.dm_simple_appbar
      title="HexHub"
      class={[
        "z-50 bg-primary",
        "shadow shadow-primary-content"
      ]}
    >
      <:logo></:logo>
      <:user_profile>
        <div class="flex items-center">
          <.dm_theme_switcher />
          <.dm_link href="https://github.com/gsmlg-dev/hex_hub">
            <.dm_mdi name="github" class="w-12 h-12" color="white" />
          </.dm_link>
        </div>
      </:user_profile>
    </.dm_simple_appbar>

    <main class="p-4">
      <div class="mx-auto space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.dm_flash_group flash={@flash} />
    """
  end
end
