defmodule HexHub.MixProject do
  use Mix.Project

  def project do
    [
      app: :hex_hub,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader],
      releases: [
        hex_hub: [
          include_executables_for: [:unix],
          steps: [:assemble, :tar],
          applications: [
            hex_hub: :permanent
          ]
        ]
      ]
    ]
  end

  def application do
    [
      mod: {HexHub.Application, []},
      extra_applications: [:logger, :runtime_tools, :mnesia]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.8.0-rc.4", override: true},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1.0-rc.0"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_duskmoon, "~> 6.0"},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:bun, "~> 1.4", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:bcrypt_elixir, "~> 3.0"},
      {:uuid, "~> 1.1"},
      {:libcluster, "~> 3.3"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      test: ["test"],
      "assets.setup": ["tailwind.install --if-missing", "bun.install --if-missing"],
      "assets.build": ["tailwind hex_hub", "tailwind hex_hub_admin", "bun hex_hub", "bun hex_hub_admin"],
      "assets.deploy": [
        "tailwind hex_hub --minify",
        "tailwind hex_hub_admin --minify",
        "bun hex_hub --minify",
        "bun hex_hub_admin --minify",
        "phx.digest"
      ]
    ]
  end
end
