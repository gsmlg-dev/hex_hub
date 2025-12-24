defmodule E2eTestPkg.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :e2e_test_pkg,
      version: @version,
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
    "E2E test package for HexHub publish testing. Do not use in production."
  end

  defp package do
    [
      name: "e2e_test_pkg",
      licenses: ["MIT"],
      links: %{},
      files: ~w(lib mix.exs README.md)
    ]
  end

  defp deps do
    # NOTE: Keep deps empty for E2E package publishing tests
    # Adding dependencies here requires running deps.get before publishing
    # which complicates the test fixture setup.
    # ex_doc would be added here for US4 documentation publishing tests:
    # {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    []
  end
end
