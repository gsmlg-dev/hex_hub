defmodule HexHub.Repositories do
  @moduledoc """
  Repository management functions.

  This is a stub implementation for MCP tools compatibility.
  The actual repository functionality is handled by other modules.
  """

  @doc """
  List all repositories.
  """
  def list_repositories do
    # Return default repository
    [
      %{
        name: "hexpm",
        url: "https://repo.hex.pm",
        public: true,
        description: "Hex.pm public repository"
      }
    ]
  end

  @doc """
  Get repository by name.
  """
  @spec get_repository(String.t()) :: {:ok, map()} | {:error, String.t()}
  def get_repository(name) do
    if name == "hexpm" do
      {:ok,
       %{
         name: "hexpm",
         url: "https://repo.hex.pm",
         public: true,
         description: "Hex.pm public repository"
       }}
    else
      {:error, "Repository not found: #{name}"}
    end
  end

  @doc """
  Create a new repository.
  """
  def create_repository(_repo) do
    {:error, "Not implemented"}
  end

  @doc """
  Update a repository.
  """
  def update_repository(_repo) do
    {:error, "Not implemented"}
  end

  @doc """
  Delete a repository.
  """
  def delete_repository(_name) do
    {:error, "Not implemented"}
  end
end
