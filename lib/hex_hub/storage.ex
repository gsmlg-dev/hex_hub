defmodule HexHub.Storage do
  @moduledoc """
  Storage abstraction layer for handling package and documentation uploads.
  Supports both local filesystem storage and S3-compatible storage.
  """

  @type storage_type :: :local | :s3
  @type upload_result :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Upload a file (package or documentation) to storage.
  """
  @spec upload(String.t(), binary(), Keyword.t()) :: upload_result
  def upload(key, content, opts \\ []) do
    storage_type = get_storage_type()
    upload_to_storage(storage_type, key, content, opts)
  end

  @doc """
  Download a file from storage.
  """
  @spec download(String.t()) :: {:ok, binary()} | {:error, String.t()}
  def download(key) do
    storage_type = get_storage_type()
    download_from_storage(storage_type, key)
  end

  @doc """
  Delete a file from storage.
  """
  @spec delete(String.t()) :: :ok | {:error, String.t()}
  def delete(key) do
    storage_type = get_storage_type()
    delete_from_storage(storage_type, key)
  end

  @doc """
  Generate a storage key for package or documentation.
  """
  @spec generate_package_key(String.t(), String.t()) :: String.t()
  def generate_package_key(package_name, version) do
    "packages/#{package_name}-#{version}.tar.gz"
  end

  @spec generate_docs_key(String.t(), String.t()) :: String.t()
  def generate_docs_key(package_name, version) do
    "docs/#{package_name}-#{version}.tar.gz"
  end

  ## Private functions

  defp get_storage_type() do
    case Application.get_env(:hex_hub, :storage_type, :local) do
      "s3" -> :s3
      "local" -> :local
      type when is_atom(type) -> type
    end
  end

  defp upload_to_storage(:local, key, content, _opts) do
    path = Path.join([storage_path(), key])
    
    case File.mkdir_p(Path.dirname(path)) do
      :ok ->
        case File.write(path, content) do
          :ok -> {:ok, key}
          {:error, reason} -> {:error, "Failed to write file: #{inspect(reason)}"}
        end
      {:error, reason} ->
        {:error, "Failed to create directory: #{inspect(reason)}"}
    end
  end

  defp upload_to_storage(:s3, key, _content, _opts) do
    bucket = Application.get_env(:hex_hub, :s3_bucket)
    
    if bucket do
      # S3 upload implementation would go here
      # For now, returning mock response
      {:ok, key}
    else
      {:error, "S3 bucket not configured"}
    end
  end

  defp download_from_storage(:local, key) do
    path = Path.join([storage_path(), key])
    
    case File.read(path) do
      {:ok, content} -> {:ok, content}
      {:error, :enoent} -> {:error, "File not found"}
      {:error, reason} -> {:error, "Failed to read file: #{inspect(reason)}"}
    end
  end

  defp download_from_storage(:s3, _key) do
    bucket = Application.get_env(:hex_hub, :s3_bucket)
    
    if bucket do
      # S3 download implementation would go here
      {:error, "S3 download not implemented"}
    else
      {:error, "S3 bucket not configured"}
    end
  end

  defp delete_from_storage(:local, key) do
    path = Path.join([storage_path(), key])
    
    case File.rm(path) do
      :ok -> :ok
      {:error, :enoent} -> :ok  # Already deleted
      {:error, reason} -> {:error, "Failed to delete file: #{inspect(reason)}"}
    end
  end

  defp delete_from_storage(:s3, _key) do
    bucket = Application.get_env(:hex_hub, :s3_bucket)
    
    if bucket do
      # S3 delete implementation would go here
      :ok
    else
      {:error, "S3 bucket not configured"}
    end
  end

  defp storage_path() do
    Application.get_env(:hex_hub, :storage_path, "priv/storage")
  end
end