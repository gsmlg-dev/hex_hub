defmodule HexHubWeb.ErrorJSONTest do
  use HexHubWeb.ConnCase, async: true
  @moduletag timeout: 120_000

  test "renders 404" do
    assert HexHubWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert HexHubWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
