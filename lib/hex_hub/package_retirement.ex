defmodule HexHub.PackageRetirement do
  @moduledoc """
  Handles package release retirement functionality.

  Retirement allows marking specific versions as deprecated with a reason
  and optional message, helping users migrate to safer or newer versions.
  """

  alias HexHub.Audit

  @retirement_reasons [
    :renamed,
    :deprecated,
    :security,
    :invalid,
    :other
  ]

  @doc """
  Retire a specific release version of a package.
  """
  @spec retire_release(String.t(), String.t(), atom(), String.t() | nil, String.t()) ::
          :ok | {:error, String.t()}
  def retire_release(package_name, version, reason, message \\ nil, retired_by) do
    if reason not in @retirement_reasons do
      {:error, "Invalid retirement reason. Must be one of: #{Enum.join(@retirement_reasons, ", ")}"}
    else
      # Check if release exists
      case get_release(package_name, version) do
        {:ok, _release} ->
          case :mnesia.transaction(fn ->
            # Check if already retired
            case :mnesia.read({:retired_releases, {package_name, version}}) do
              [] ->
                # Add retirement record
                :mnesia.write({
                  :retired_releases,
                  {package_name, version},
                  package_name,
                  version,
                  reason,
                  message,
                  DateTime.utc_now(),
                  retired_by
                })

              [_existing] ->
                {:error, "Release is already retired"}
            end
          end) do
            {:atomic, :ok} ->
              # Log the retirement
              Audit.log_event("package.release.retired", "release",
                "#{package_name}:#{version}", %{
                  retired_by: retired_by,
                  reason: reason,
                  message: message
                }, nil)
              :ok

            {:atomic, error} ->
              error

            {:aborted, reason} ->
              {:error, "Failed to retire release: #{inspect(reason)}"}
          end

        {:error, _} ->
          {:error, "Release not found"}
      end
    end
  end

  @doc """
  Unretire a previously retired release.
  """
  @spec unretire_release(String.t(), String.t(), String.t()) :: :ok | {:error, String.t()}
  def unretire_release(package_name, version, unretired_by) do
    case :mnesia.transaction(fn ->
      case :mnesia.read({:retired_releases, {package_name, version}}) do
        [{:retired_releases, key, _, _, _, _, _, _}] ->
          :mnesia.delete({:retired_releases, key})
          :ok

        [] ->
          {:error, "Release is not retired"}
      end
    end) do
      {:atomic, :ok} ->
        # Log the unretirement
        Audit.log_event("package.release.unretired", "release",
          "#{package_name}:#{version}", %{
            unretired_by: unretired_by
          }, nil)
        :ok

      {:atomic, error} ->
        error

      {:aborted, reason} ->
        {:error, "Failed to unretire release: #{inspect(reason)}"}
    end
  end

  @doc """
  Get retirement information for a release.
  """
  @spec get_retirement_info(String.t(), String.t()) ::
          {:ok, map()} | {:error, :not_retired}
  def get_retirement_info(package_name, version) do
    case :mnesia.transaction(fn ->
      :mnesia.read({:retired_releases, {package_name, version}})
    end) do
      {:atomic, [{:retired_releases, _key, _pkg, _ver, reason, message, retired_at, retired_by}]} ->
        {:ok, %{
          reason: reason,
          message: message,
          retired_at: retired_at,
          retired_by: retired_by
        }}

      {:atomic, []} ->
        {:error, :not_retired}

      {:aborted, _reason} ->
        {:error, :not_retired}
    end
  end

  @doc """
  Check if a release is retired.
  """
  @spec retired?(String.t(), String.t()) :: boolean()
  def retired?(package_name, version) do
    case get_retirement_info(package_name, version) do
      {:ok, _} -> true
      _ -> false
    end
  end

  @doc """
  List all retired releases for a package.
  """
  @spec list_retired_releases(String.t()) :: list(map())
  def list_retired_releases(package_name) do
    case :mnesia.transaction(fn ->
      :mnesia.index_read(:retired_releases, package_name, 2)
    end) do
      {:atomic, releases} ->
        Enum.map(releases, fn {:retired_releases, _key, _pkg, version, reason, message, retired_at, retired_by} ->
          %{
            version: version,
            reason: reason,
            message: message,
            retired_at: retired_at,
            retired_by: retired_by
          }
        end)

      {:aborted, _reason} ->
        []
    end
  end

  @doc """
  Get all retired releases across all packages.
  """
  @spec list_all_retired_releases() :: list(map())
  def list_all_retired_releases() do
    case :mnesia.transaction(fn ->
      :mnesia.select(:retired_releases, [{:"$1", [], [:"$1"]}])
    end) do
      {:atomic, releases} ->
        Enum.map(releases, fn {:retired_releases, {pkg, ver}, _pkg2, _ver2, reason, message, retired_at, retired_by} ->
          %{
            package: pkg,
            version: ver,
            reason: reason,
            message: message,
            retired_at: retired_at,
            retired_by: retired_by
          }
        end)

      {:aborted, _reason} ->
        []
    end
  end

  @doc """
  Validate retirement reason.
  """
  @spec valid_reason?(atom()) :: boolean()
  def valid_reason?(reason) when is_atom(reason) do
    reason in @retirement_reasons
  end

  def valid_reason?(_), do: false

  @doc """
  Get list of valid retirement reasons.
  """
  @spec retirement_reasons() :: list(atom())
  def retirement_reasons, do: @retirement_reasons

  # Private helper to check if release exists
  defp get_release(package_name, version) do
    case :mnesia.transaction(fn ->
      :mnesia.match_object({:package_releases, package_name, version, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_})
    end) do
      {:atomic, [release | _]} ->
        {:ok, release}

      {:atomic, []} ->
        {:error, "Release not found"}

      {:aborted, reason} ->
        {:error, "Database error: #{inspect(reason)}"}
    end
  end
end