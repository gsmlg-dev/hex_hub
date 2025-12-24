defmodule HexHub.TestHelpers do
  @moduledoc """
  Helper functions for setting up test data.
  """

  alias HexHub.{ApiKeys, Users, Packages}

  def create_user(attrs \\ %{}) do
    username = Map.get(attrs, :username) || "testuser#{System.unique_integer([:positive])}"
    email = Map.get(attrs, :email) || "test#{System.unique_integer([:positive])}@example.com"
    password = Map.get(attrs, :password) || "password123"

    case Users.create_user(username, email, password) do
      {:ok, user} ->
        user

      {:error, "Username already taken"} ->
        {:ok, user} = Users.get_user(username)
        user

      {:error, reason} ->
        raise "Failed to create test user: #{inspect(reason)}"
    end
  end

  def setup_authenticated_user(attrs \\ %{}) do
    user = create_user(attrs)
    {:ok, api_key} = ApiKeys.generate_key("test-key", user.username)
    %{user: user, api_key: api_key}
  end

  def authenticated_conn(conn, api_key) do
    conn
    |> Plug.Conn.put_req_header("authorization", "Bearer #{api_key}")
  end

  def create_package(attrs \\ %{}) do
    name = Map.get(attrs, :name) || "test_package#{System.unique_integer([:positive])}"
    repository = Map.get(attrs, :repository) || "hexpm"
    meta = Map.get(attrs, :meta) || %{description: "Test package"}

    case Packages.create_package(name, repository, meta) do
      {:ok, package} -> package
      {:error, reason} -> raise "Failed to create test package: #{inspect(reason)}"
    end
  end

  def create_release(attrs \\ %{}) do
    default_attrs = %{
      name: "test_package",
      version: "1.0.0",
      requirements: %{},
      meta: %{
        app: "test_package",
        description: "Test package",
        version: "1.0.0"
      }
    }

    Map.merge(default_attrs, attrs)
  end

  @doc """
  Create a valid hex tarball for testing.
  Hex tarballs have a specific format: VERSION header + embedded tar files.
  """
  def create_test_tarball(name, version, opts \\ []) do
    description = Keyword.get(opts, :description, "Test package")

    # Create metadata.config in Erlang term format
    # Note: Using [] instead of #{} for empty maps as Erlang term format
    metadata_content = """
    {<<"name">>,<<"#{name}">>}.
    {<<"version">>,<<"#{version}">>}.
    {<<"app">>,<<"#{name}">>}.
    {<<"description">>,<<"#{description}">>}.
    {<<"build_tools">>,[<<"mix">>]}.
    {<<"licenses">>,[<<"MIT">>]}.
    {<<"links">>,[]}.
    {<<"requirements">>,[]}.
    {<<"elixir">>,<<"~> 1.15">>}.
    {<<"files">>,[<<"lib">>,<<"mix.exs">>]}.
    """

    # Create a simple mix.exs
    mix_exs = """
    defmodule #{Macro.camelize(name)}.MixProject do
      use Mix.Project

      def project do
        [
          app: :#{name},
          version: "#{version}",
          elixir: "~> 1.15"
        ]
      end
    end
    """

    # Create main lib file
    lib_file = """
    defmodule #{Macro.camelize(name)} do
      @moduledoc "#{description}"
    end
    """

    # Build tarball using temp directory and files
    unique_id = :erlang.unique_integer([:positive])
    tmp_base = Path.join(System.tmp_dir!(), "hexhub_test_#{unique_id}")
    File.mkdir_p!(tmp_base)

    # Write source files to disk
    lib_dir = Path.join(tmp_base, "lib")
    File.mkdir_p!(lib_dir)
    lib_file_path = Path.join(lib_dir, "#{name}.ex")
    mix_file_path = Path.join(tmp_base, "mix.exs")
    File.write!(lib_file_path, lib_file)
    File.write!(mix_file_path, mix_exs)

    # Create contents.tar.gz using file paths
    contents_tar_path = Path.join(tmp_base, "contents.tar.gz")
    {:ok, contents_handle} = :erl_tar.open(to_charlist(contents_tar_path), [:write, :compressed])
    :ok = :erl_tar.add(contents_handle, to_charlist(lib_file_path), ~c"lib/#{name}.ex", [])
    :ok = :erl_tar.add(contents_handle, to_charlist(mix_file_path), ~c"mix.exs", [])
    :ok = :erl_tar.close(contents_handle)
    contents_tar = File.read!(contents_tar_path)

    # VERSION content (padded to 64 bytes with null bytes)
    version_content = String.pad_trailing("3", 64, <<0>>)

    # CHECKSUM is the SHA256 of contents.tar.gz as hex string
    checksum = :crypto.hash(:sha256, contents_tar) |> Base.encode16(case: :lower)

    # Write metadata files to disk
    version_path = Path.join(tmp_base, "VERSION")
    metadata_path = Path.join(tmp_base, "metadata.config")
    checksum_path = Path.join(tmp_base, "CHECKSUM")
    File.write!(version_path, version_content)
    File.write!(metadata_path, metadata_content)
    File.write!(checksum_path, checksum)

    # Create outer tar using file paths
    outer_tar_path = Path.join(tmp_base, "package.tar")
    {:ok, outer_handle} = :erl_tar.open(to_charlist(outer_tar_path), [:write])
    :ok = :erl_tar.add(outer_handle, to_charlist(version_path), ~c"VERSION", [])
    :ok = :erl_tar.add(outer_handle, to_charlist(metadata_path), ~c"metadata.config", [])
    :ok = :erl_tar.add(outer_handle, to_charlist(checksum_path), ~c"CHECKSUM", [])
    :ok = :erl_tar.add(outer_handle, to_charlist(contents_tar_path), ~c"contents.tar.gz", [])
    :ok = :erl_tar.close(outer_handle)
    outer_tar = File.read!(outer_tar_path)

    # Cleanup temp dir
    File.rm_rf!(tmp_base)

    outer_tar
  end
end
