defmodule InvalidPublishProject.MixProject do
  use Mix.Project

  # NOTE: This fixture intentionally has NO version field for testing error handling
  # Version is commented out to trigger validation errors

  def project do
    [
      app: :invalid_publish_project,
      # version: "0.1.0",  # Intentionally missing for testing
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    "Invalid fixture for E2E error handling tests. Missing version field."
  end

  defp package do
    [
      name: "invalid_publish_project",
      licenses: ["MIT"],
      links: %{},
      files: ~w(lib mix.exs)
    ]
  end

  defp deps do
    []
  end
end
