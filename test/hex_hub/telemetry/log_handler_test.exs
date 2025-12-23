defmodule HexHub.Telemetry.LogHandlerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias HexHub.Telemetry.LogHandler

  # Configure logger to capture all levels during tests
  setup do
    Logger.configure(level: :debug)
    on_exit(fn -> Logger.configure(level: :info) end)
    :ok
  end

  describe "handle_event/4" do
    test "logs info level events when configured for info" do
      event_name = [:hex_hub, :log, :api]
      measurements = %{}
      metadata = %{level: :info, message: "Request completed"}
      config = [level: :info]

      log =
        capture_log(fn ->
          LogHandler.handle_event(event_name, measurements, metadata, config)
        end)

      assert log =~ "Request completed"
      assert log =~ "hex_hub.log.api"
    end

    test "logs warning level events when configured for info" do
      event_name = [:hex_hub, :log, :auth]
      measurements = %{}
      metadata = %{level: :warning, message: "Auth failed"}
      config = [level: :info]

      log =
        capture_log(fn ->
          LogHandler.handle_event(event_name, measurements, metadata, config)
        end)

      assert log =~ "Auth failed"
    end

    test "filters debug events when configured for info" do
      event_name = [:hex_hub, :log, :storage]
      measurements = %{}
      metadata = %{level: :debug, message: "Debug message"}
      config = [level: :info]

      log =
        capture_log(fn ->
          LogHandler.handle_event(event_name, measurements, metadata, config)
        end)

      assert log == ""
    end

    test "logs debug events when configured for debug" do
      event_name = [:hex_hub, :log, :storage]
      measurements = %{}
      metadata = %{level: :debug, message: "Debug message"}
      config = [level: :debug]

      log =
        capture_log(fn ->
          LogHandler.handle_event(event_name, measurements, metadata, config)
        end)

      assert log =~ "Debug message"
    end

    test "includes duration_ms in output when present" do
      event_name = [:hex_hub, :log, :upstream]
      measurements = %{duration: 150}
      metadata = %{level: :info, message: "Upstream request"}
      config = [level: :info]

      log =
        capture_log(fn ->
          LogHandler.handle_event(event_name, measurements, metadata, config)
        end)

      assert log =~ "duration_ms"
      assert log =~ "150"
    end

    test "includes metadata in output" do
      event_name = [:hex_hub, :log, :api]
      measurements = %{}
      metadata = %{level: :info, message: "Test", path: "/api/packages", status: 200}
      config = [level: :info]

      log =
        capture_log(fn ->
          LogHandler.handle_event(event_name, measurements, metadata, config)
        end)

      assert log =~ "/api/packages"
      assert log =~ "200"
    end

    test "defaults to info level when event level not specified" do
      event_name = [:hex_hub, :log, :general]
      measurements = %{}
      metadata = %{message: "No level specified"}
      config = [level: :info]

      log =
        capture_log(fn ->
          LogHandler.handle_event(event_name, measurements, metadata, config)
        end)

      assert log =~ "No level specified"
    end

    test "defaults to info level when config level not specified" do
      event_name = [:hex_hub, :log, :general]
      measurements = %{}
      metadata = %{level: :info, message: "Test"}
      config = []

      log =
        capture_log(fn ->
          LogHandler.handle_event(event_name, measurements, metadata, config)
        end)

      assert log =~ "Test"
    end
  end

  describe "should_log?/2" do
    test "returns true when event level equals min level" do
      assert LogHandler.should_log?(:info, :info) == true
      assert LogHandler.should_log?(:debug, :debug) == true
      assert LogHandler.should_log?(:warning, :warning) == true
      assert LogHandler.should_log?(:error, :error) == true
    end

    test "returns true when event level is higher than min level" do
      assert LogHandler.should_log?(:info, :debug) == true
      assert LogHandler.should_log?(:warning, :info) == true
      assert LogHandler.should_log?(:error, :warning) == true
      assert LogHandler.should_log?(:error, :debug) == true
    end

    test "returns false when event level is lower than min level" do
      assert LogHandler.should_log?(:debug, :info) == false
      assert LogHandler.should_log?(:info, :warning) == false
      assert LogHandler.should_log?(:warning, :error) == false
      assert LogHandler.should_log?(:debug, :error) == false
    end
  end
end
