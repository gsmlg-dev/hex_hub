defmodule HexHub.Telemetry.FileHandlerTest do
  use ExUnit.Case, async: false

  alias HexHub.Telemetry.FileHandler

  @test_log_dir "test/tmp/logs"
  @test_log_file "#{@test_log_dir}/test.log"

  setup do
    # Clean up test log directory before each test
    File.rm_rf(@test_log_dir)
    File.mkdir_p(@test_log_dir)

    on_exit(fn ->
      File.rm_rf(@test_log_dir)
    end)

    :ok
  end

  describe "handle_event/4" do
    test "writes log entry to file" do
      event_name = [:hex_hub, :log, :api]
      measurements = %{}
      metadata = %{level: :info, message: "Request completed"}
      config = [path: @test_log_file, level: :info]

      FileHandler.handle_event(event_name, measurements, metadata, config)

      assert File.exists?(@test_log_file)
      content = File.read!(@test_log_file)
      assert content =~ "Request completed"
      assert content =~ "hex_hub.log.api"
    end

    test "appends multiple log entries" do
      event_name = [:hex_hub, :log, :api]
      config = [path: @test_log_file, level: :info]

      FileHandler.handle_event(event_name, %{}, %{level: :info, message: "First"}, config)
      FileHandler.handle_event(event_name, %{}, %{level: :info, message: "Second"}, config)
      FileHandler.handle_event(event_name, %{}, %{level: :info, message: "Third"}, config)

      content = File.read!(@test_log_file)
      lines = String.split(content, "\n", trim: true)

      assert length(lines) == 3
      assert Enum.at(lines, 0) =~ "First"
      assert Enum.at(lines, 1) =~ "Second"
      assert Enum.at(lines, 2) =~ "Third"
    end

    test "filters events below minimum level" do
      event_name = [:hex_hub, :log, :storage]
      measurements = %{}
      metadata = %{level: :debug, message: "Debug message"}
      config = [path: @test_log_file, level: :info]

      FileHandler.handle_event(event_name, measurements, metadata, config)

      refute File.exists?(@test_log_file)
    end

    test "writes debug events when configured for debug" do
      event_name = [:hex_hub, :log, :storage]
      measurements = %{}
      metadata = %{level: :debug, message: "Debug message"}
      config = [path: @test_log_file, level: :debug]

      FileHandler.handle_event(event_name, measurements, metadata, config)

      assert File.exists?(@test_log_file)
      content = File.read!(@test_log_file)
      assert content =~ "Debug message"
    end

    test "includes duration_ms in output when present" do
      event_name = [:hex_hub, :log, :upstream]
      measurements = %{duration: 150}
      metadata = %{level: :info, message: "Upstream request"}
      config = [path: @test_log_file, level: :info]

      FileHandler.handle_event(event_name, measurements, metadata, config)

      content = File.read!(@test_log_file)
      assert content =~ "duration_ms"
      assert content =~ "150"
    end

    test "includes metadata in output" do
      event_name = [:hex_hub, :log, :api]
      measurements = %{}
      metadata = %{level: :info, message: "Test", path: "/api/packages", status: 200}
      config = [path: @test_log_file, level: :info]

      FileHandler.handle_event(event_name, measurements, metadata, config)

      content = File.read!(@test_log_file)
      assert content =~ "/api/packages"
      assert content =~ "200"
    end

    test "creates parent directories if they don't exist" do
      nested_path = "#{@test_log_dir}/nested/deep/test.log"
      event_name = [:hex_hub, :log, :api]
      metadata = %{level: :info, message: "Test"}
      config = [path: nested_path, level: :info]

      FileHandler.handle_event(event_name, %{}, metadata, config)

      assert File.exists?(nested_path)
      content = File.read!(nested_path)
      assert content =~ "Test"
    end

    test "does nothing when path is nil" do
      event_name = [:hex_hub, :log, :api]
      metadata = %{level: :info, message: "Test"}
      config = [path: nil, level: :info]

      # Should not raise
      result = FileHandler.handle_event(event_name, %{}, metadata, config)
      assert result == :ok
    end

    test "handles file write errors gracefully" do
      # Try to write to a path that's a directory (will fail)
      File.mkdir_p!("#{@test_log_dir}/is_a_directory")
      event_name = [:hex_hub, :log, :api]
      metadata = %{level: :info, message: "Test"}
      config = [path: "#{@test_log_dir}/is_a_directory", level: :info]

      # Should not raise, fails silently
      result = FileHandler.handle_event(event_name, %{}, metadata, config)
      assert result == :ok
    end

    test "writes valid JSON on each line" do
      event_name = [:hex_hub, :log, :api]
      config = [path: @test_log_file, level: :info]

      FileHandler.handle_event(event_name, %{}, %{level: :info, message: "First"}, config)
      FileHandler.handle_event(event_name, %{}, %{level: :warning, message: "Second"}, config)

      content = File.read!(@test_log_file)
      lines = String.split(content, "\n", trim: true)

      for line <- lines do
        assert {:ok, _} = Jason.decode(line)
      end
    end
  end

  describe "should_log?/2" do
    test "returns true when event level equals min level" do
      assert FileHandler.should_log?(:info, :info) == true
      assert FileHandler.should_log?(:debug, :debug) == true
      assert FileHandler.should_log?(:warning, :warning) == true
      assert FileHandler.should_log?(:error, :error) == true
    end

    test "returns true when event level is higher than min level" do
      assert FileHandler.should_log?(:info, :debug) == true
      assert FileHandler.should_log?(:warning, :info) == true
      assert FileHandler.should_log?(:error, :warning) == true
      assert FileHandler.should_log?(:error, :debug) == true
    end

    test "returns false when event level is lower than min level" do
      assert FileHandler.should_log?(:debug, :info) == false
      assert FileHandler.should_log?(:info, :warning) == false
      assert FileHandler.should_log?(:warning, :error) == false
      assert FileHandler.should_log?(:debug, :error) == false
    end
  end

  describe "concurrent writes" do
    test "handles concurrent writes safely" do
      event_name = [:hex_hub, :log, :api]
      config = [path: @test_log_file, level: :info]

      # Spawn multiple processes writing concurrently
      tasks =
        for i <- 1..50 do
          Task.async(fn ->
            metadata = %{level: :info, message: "Message #{i}"}
            FileHandler.handle_event(event_name, %{}, metadata, config)
          end)
        end

      # Wait for all tasks to complete
      Enum.each(tasks, &Task.await/1)

      # Verify all entries were written
      content = File.read!(@test_log_file)
      lines = String.split(content, "\n", trim: true)

      assert length(lines) == 50

      # Each line should be valid JSON
      for line <- lines do
        assert {:ok, _} = Jason.decode(line)
      end
    end
  end
end
