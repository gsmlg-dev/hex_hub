defmodule HexHub.UpstreamSimpleTest do
  use ExUnit.Case, async: false

  alias HexHub.{Upstream, UpstreamConfig}

  setup do
    # Reset upstream config to default state for each test
    :ok = UpstreamConfig.reset_to_defaults()
    :ok
  end

  describe "upstream configuration" do
    test "returns default configuration" do
      config = Upstream.config()

      assert config.enabled == true
      assert config.api_url == "https://hex.pm"
      assert config.repo_url == "https://repo.hex.pm"
      assert config.timeout == 30_000
      assert config.retry_attempts == 3
      assert config.retry_delay == 1_000
      assert config.api_key == nil
    end

    test "checks if upstream is enabled" do
      assert Upstream.enabled?() == true

      # Temporarily disable
      UpstreamConfig.update_config(%{enabled: false})
      assert Upstream.enabled?() == false

      # Re-enable
      UpstreamConfig.update_config(%{enabled: true})
      assert Upstream.enabled?() == true
    end

    test "respects custom configuration" do
      custom_config = %{
        enabled: false,
        api_url: "https://custom.example.com",
        repo_url: "https://repo.custom.example.com",
        timeout: 60_000,
        retry_attempts: 5,
        retry_delay: 2_000,
        api_key: "test_key"
      }

      UpstreamConfig.update_config(custom_config)

      config = Upstream.config()
      assert config.enabled == false
      assert config.api_url == "https://custom.example.com"
      assert config.repo_url == "https://repo.custom.example.com"
      assert config.timeout == 60_000
      assert config.retry_attempts == 5
      assert config.retry_delay == 2_000
      assert config.api_key == "test_key"
    end
  end

  describe "upstream disabled behavior" do
    test "returns error when upstream disabled" do
      # Disable upstream using string key (like form submissions)
      :ok = UpstreamConfig.update_config(%{"enabled" => false})

      # Verify the config was actually updated
      config = UpstreamConfig.get_config()
      if config.enabled != false do
        raise "Failed to disable upstream. Current enabled state: #{config.enabled}"
      end

      # Verify Upstream module sees the disabled state
      if Upstream.enabled?() != false do
        raise "Upstream module still sees enabled state: #{Upstream.enabled?()}"
      end

      # All upstream functions should return disabled error
      assert {:error, "Upstream is disabled"} = Upstream.fetch_package("any_package")
      assert {:error, "Upstream is disabled"} = Upstream.fetch_release_tarball("any", "1.0.0")
      assert {:error, "Upstream is disabled"} = Upstream.fetch_docs_tarball("any", "1.0.0")
      assert {:error, "Upstream is disabled"} = Upstream.fetch_releases("any_package")

      # Re-enable
      UpstreamConfig.update_config(%{"enabled" => true})
    end
  end
end
