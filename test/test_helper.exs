ExUnit.start()

# Initialize Mnesia for testing
:ok = Application.ensure_started(:mnesia)

# Stop Mnesia if it's running, delete schema, then restart fresh
:mnesia.stop()
File.rm_rf!("Mnesia.#{node()}")
:mnesia.create_schema([node()])
:mnesia.start()

# Initialize Mnesia tables
HexHub.Mnesia.init()

# Setup test storage directory
File.mkdir_p!("priv/test_storage")
Application.put_env(:hex_hub, :storage_path, "priv/test_storage")
Application.put_env(:hex_hub, :storage_type, :local)

# Configure upstream for testing
Application.put_env(:hex_hub, :upstream, enabled: true, url: "https://test.hex.pm")
