defmodule HexHub.UpstreamSimpleTest do
  use ExUnit.Case

  alias HexHub.Upstream

  describe "upstream configuration" do
    test "returns default configuration" do
      config = Upstream.config()

      assert config.enabled == true
      assert config.url in ["https://hex.pm", "https://test.hex.pm"]
      assert config.timeout == 30_000
      assert config.retry_attempts == 3
      assert config.retry_delay == 1_000
    end

    test "checks if upstream is enabled" do
      assert Upstream.enabled?() == true

      # Temporarily disable
      Application.put_env(:hex_hub, :upstream, enabled: false)
      assert Upstream.enabled?() == false

      # Re-enable
      Application.put_env(:hex_hub, :upstream, enabled: true)
      assert Upstream.enabled?() == true
    end

    test "respects custom configuration" do
      custom_config = [
        enabled: false,
        url: "https://custom.example.com",
        timeout: 60_000,
        retry_attempts: 5,
        retry_delay: 2_000
      ]

      Application.put_env(:hex_hub, :upstream, custom_config)

      config = Upstream.config()
      assert config.enabled == false
      assert config.url == "https://custom.example.com"
      assert config.timeout == 60_000
      assert config.retry_attempts == 5
      assert config.retry_delay == 2_000

      # Reset to default
      Application.put_env(:hex_hub, :upstream,
        enabled: true,
        url: "https://hex.pm",
        timeout: 30_000,
        retry_attempts: 3,
        retry_delay: 1_000
      )
    end
  end

  describe "upstream disabled behavior" do
    test "returns error when upstream disabled" do
      # Disable upstream
      Application.put_env(:hex_hub, :upstream, enabled: false)

      # All upstream functions should return disabled error
      assert {:error, "Upstream is disabled"} = Upstream.fetch_package("any_package")
      assert {:error, "Upstream is disabled"} = Upstream.fetch_release_tarball("any", "1.0.0")
      assert {:error, "Upstream is disabled"} = Upstream.fetch_docs_tarball("any", "1.0.0")
      assert {:error, "Upstream is disabled"} = Upstream.fetch_releases("any_package")

      # Re-enable
      Application.put_env(:hex_hub, :upstream, enabled: true)
    end
  end
end
