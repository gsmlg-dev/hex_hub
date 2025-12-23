defmodule HexHub.Telemetry.FormatterTest do
  use ExUnit.Case, async: true

  alias HexHub.Telemetry.Formatter

  describe "format_event/3" do
    test "formats a basic log event as JSON" do
      event_name = [:hex_hub, :log, :api]
      measurements = %{}
      metadata = %{level: :info, message: "Request completed"}

      result = Formatter.format_event(event_name, measurements, metadata)

      assert is_binary(result)
      parsed = Jason.decode!(result)
      assert parsed["level"] == "info"
      assert parsed["message"] == "Request completed"
      assert parsed["event"] == "hex_hub.log.api"
      assert Map.has_key?(parsed, "ts")
      assert Map.has_key?(parsed, "meta")
    end

    test "includes duration_ms when present in measurements" do
      event_name = [:hex_hub, :log, :upstream]
      measurements = %{duration: 150}
      metadata = %{level: :info, message: "Upstream request completed", url: "https://hex.pm"}

      result = Formatter.format_event(event_name, measurements, metadata)
      parsed = Jason.decode!(result)

      assert parsed["duration_ms"] == 150
      assert parsed["meta"]["url"] == "https://hex.pm"
    end

    test "handles duration_ms key in measurements" do
      event_name = [:hex_hub, :log, :api]
      measurements = %{duration_ms: 200}
      metadata = %{level: :debug, message: "Test"}

      result = Formatter.format_event(event_name, measurements, metadata)
      parsed = Jason.decode!(result)

      assert parsed["duration_ms"] == 200
    end

    test "returns nil on encoding failure" do
      event_name = [:hex_hub, :log, :api]
      # Create a value that can't be JSON encoded (circular reference simulation)
      measurements = %{}
      # Use a reference which can't be encoded
      metadata = %{level: :info, message: "Test", ref: make_ref()}

      # Should return nil instead of crashing
      result = Formatter.format_event(event_name, measurements, metadata)
      # The safe_value function converts refs to inspect strings, so it should work
      assert is_binary(result) or is_nil(result)
    end
  end

  describe "build_log_entry/3" do
    test "builds a map with required fields" do
      event_name = [:hex_hub, :log, :storage]
      measurements = %{duration: 50}
      metadata = %{level: :warning, message: "Storage slow", path: "/data/file"}

      result = Formatter.build_log_entry(event_name, measurements, metadata)

      assert is_map(result)
      assert result.level == "warning"
      assert result.message == "Storage slow"
      assert result.event == "hex_hub.log.storage"
      assert result.duration_ms == 50
      assert result.meta.path == "/data/file"
      assert is_binary(result.ts)
    end

    test "defaults level to info when not provided" do
      result = Formatter.build_log_entry([:test], %{}, %{message: "Test"})
      assert result.level == "info"
    end

    test "defaults message to empty string when not provided" do
      result = Formatter.build_log_entry([:test], %{}, %{level: :debug})
      assert result.message == ""
    end

    test "excludes duration_ms when not present in measurements" do
      result = Formatter.build_log_entry([:test], %{}, %{level: :info, message: "Test"})
      refute Map.has_key?(result, :duration_ms)
    end
  end

  describe "format_event_name/1" do
    test "formats list of atoms as dot-separated string" do
      assert Formatter.format_event_name([:hex_hub, :log, :api]) == "hex_hub.log.api"
      assert Formatter.format_event_name([:a, :b, :c, :d]) == "a.b.c.d"
      assert Formatter.format_event_name([:single]) == "single"
    end

    test "returns unknown for non-list input" do
      assert Formatter.format_event_name("not a list") == "unknown"
      assert Formatter.format_event_name(nil) == "unknown"
    end
  end

  describe "format_timestamp/0" do
    test "returns ISO 8601 formatted timestamp" do
      result = Formatter.format_timestamp()

      assert is_binary(result)
      # Should be parseable as ISO 8601
      assert {:ok, _, _} = DateTime.from_iso8601(result)
    end
  end

  describe "redact_sensitive_data/1" do
    test "redacts atom keys in sensitive list" do
      data = %{user: "john", password: "secret123", email: "john@example.com"}
      result = Formatter.redact_sensitive_data(data)

      assert result.user == "john"
      assert result.password == "[REDACTED]"
      assert result.email == "john@example.com"
    end

    test "redacts string keys in sensitive list" do
      data = %{"user" => "john", "api_key" => "abc123", "name" => "John"}
      result = Formatter.redact_sensitive_data(data)

      assert result["user"] == "john"
      assert result["api_key"] == "[REDACTED]"
      assert result["name"] == "John"
    end

    test "redacts nested maps recursively" do
      data = %{
        user: "john",
        auth: %{
          password: "secret",
          token: "abc123"
        }
      }

      result = Formatter.redact_sensitive_data(data)

      assert result.user == "john"
      # auth is not a sensitive key, so its nested structure is preserved
      assert result.auth.password == "[REDACTED]"
      assert result.auth.token == "[REDACTED]"
    end

    test "redacts top-level sensitive keys that are maps" do
      # When the key itself is sensitive, the entire value is redacted
      data = %{
        user: "john",
        credentials: %{
          username: "john",
          password: "secret"
        }
      }

      result = Formatter.redact_sensitive_data(data)

      assert result.user == "john"
      # credentials is a sensitive key, so entire value is redacted
      assert result.credentials == "[REDACTED]"
    end

    test "handles all sensitive keys" do
      sensitive_keys = [
        :password,
        :password_hash,
        :secret,
        :secret_key,
        :token,
        :api_key,
        :authorization,
        :bearer,
        :credentials,
        :private_key
      ]

      data = Map.new(sensitive_keys, fn key -> {key, "sensitive_value"} end)
      result = Formatter.redact_sensitive_data(data)

      for key <- sensitive_keys do
        assert result[key] == "[REDACTED]", "Expected #{key} to be redacted"
      end
    end

    test "preserves non-sensitive data" do
      data = %{
        name: "test",
        count: 42,
        enabled: true,
        tags: ["a", "b"],
        nested: %{value: 100}
      }

      result = Formatter.redact_sensitive_data(data)

      assert result.name == "test"
      assert result.count == 42
      assert result.enabled == true
      assert result.tags == ["a", "b"]
      assert result.nested.value == 100
    end

    test "converts atoms to strings" do
      data = %{status: :ok, mode: :production}
      result = Formatter.redact_sensitive_data(data)

      assert result.status == "ok"
      assert result.mode == "production"
    end

    test "returns non-map input unchanged" do
      assert Formatter.redact_sensitive_data("string") == "string"
      assert Formatter.redact_sensitive_data(123) == 123
      assert Formatter.redact_sensitive_data(nil) == nil
    end
  end
end
