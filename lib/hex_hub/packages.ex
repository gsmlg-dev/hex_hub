defmodule HexHub.Packages do
  @moduledoc """
  Package management functions with Mnesia storage and file handling.
  """

  alias HexHub.Storage

  @type package :: %{
          name: String.t(),
          repository_name: String.t(),
          meta: map(),
          private: boolean(),
          downloads: integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t(),
          html_url: String.t(),
          docs_html_url: String.t()
        }

  @type release :: %{
          package_name: String.t(),
          version: String.t(),
          has_docs: boolean(),
          meta: map(),
          requirements: map(),
          retired: boolean(),
          downloads: integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t(),
          url: String.t(),
          package_url: String.t(),
          html_url: String.t(),
          docs_html_url: String.t()
        }

  @packages_table :packages
  @releases_table :package_releases
  @owners_table :package_owners

  @doc """
  Reset test data - mainly for testing purposes.
  """
  def reset_test_store do
    :mnesia.clear_table(@packages_table)
    :mnesia.clear_table(@releases_table)
    :mnesia.clear_table(@owners_table)
    :ok
  end

  @doc """
  Create a new package.
  """
  @spec create_package(String.t(), String.t(), map(), boolean()) ::
          {:ok, package()} | {:error, String.t()}
  def create_package(name, repository_name, meta, private \\ false) do
    with :ok <- validate_package_name(name) do
      now = DateTime.utc_now()

      package = {
        @packages_table,
        name,
        repository_name,
        meta,
        private,
        # downloads
        0,
        now,
        now,
        "/packages/#{name}",
        "/packages/#{name}/docs"
      }

      case :mnesia.transaction(fn ->
             :mnesia.write(package)
           end) do
        {:atomic, :ok} ->
          {:ok, package_to_map(package)}

        {:aborted, reason} ->
          {:error, "Failed to create package: #{inspect(reason)}"}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get package by name.
  """
  @spec get_package(String.t()) :: {:ok, package()} | {:error, :not_found}
  def get_package(name) do
    case :mnesia.transaction(fn ->
           :mnesia.read(@packages_table, name)
         end) do
      {:atomic,
       [
         {@packages_table, name, repository_name, meta, private, downloads, inserted_at,
          updated_at, html_url, docs_html_url}
       ]} ->
        {:ok,
         package_to_map(
           {@packages_table, name, repository_name, meta, private, downloads, inserted_at,
            updated_at, html_url, docs_html_url}
         )}

      {:atomic, []} ->
        {:error, :not_found}

      {:aborted, _reason} ->
        {:error, :not_found}
    end
  end

  @doc """
  List all packages.
  """
  @spec list_packages() :: {:ok, [package()]}
  def list_packages() do
    case :mnesia.transaction(fn ->
           :mnesia.foldl(
             fn {_, name, repository_name, meta, private, downloads, inserted_at, updated_at,
                 html_url, docs_html_url},
                acc ->
               [
                 package_to_map(
                   {@packages_table, name, repository_name, meta, private, downloads, inserted_at,
                    updated_at, html_url, docs_html_url}
                 )
                 | acc
               ]
             end,
             [],
             @packages_table
           )
         end) do
      {:atomic, packages} -> {:ok, packages}
      {:aborted, reason} -> {:error, "Failed to list packages: #{inspect(reason)}"}
    end
  end

  @doc """
  Create a new package release with file upload.
  """
  @spec create_release(String.t(), String.t(), map(), map(), binary()) ::
          {:ok, release()} | {:error, String.t()}
  def create_release(package_name, version, meta, requirements, tarball) do
    with :ok <- validate_version(version),
         {:ok, _package} <- get_package(package_name) do
      # Upload package file
      package_key = Storage.generate_package_key(package_name, version)

      case Storage.upload(package_key, tarball) do
        {:ok, _} ->
          now = DateTime.utc_now()

          release = {
            @releases_table,
            package_name,
            version,
            # has_docs
            false,
            meta,
            requirements,
            # retired
            false,
            # downloads
            0,
            now,
            now,
            "/packages/#{package_name}/releases/#{version}",
            "/packages/#{package_name}/releases/#{version}/package",
            "/packages/#{package_name}/releases/#{version}",
            "/packages/#{package_name}/releases/#{version}/docs"
          }

          case :mnesia.transaction(fn ->
                 :mnesia.write(release)
               end) do
            {:atomic, :ok} ->
              {:ok, release_to_map(release)}

            {:aborted, reason} ->
              # Rollback file upload
              Storage.delete(package_key)
              {:error, "Failed to create release: #{inspect(reason)}"}
          end

        {:error, reason} ->
          {:error, "Failed to upload package: #{reason}"}
      end
    else
      {:error, :not_found} -> {:error, "Package not found"}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get package release.
  """
  @spec get_release(String.t(), String.t()) :: {:ok, release()} | {:error, :not_found}
  def get_release(package_name, version) do
    case :mnesia.transaction(fn ->
           :mnesia.match_object(
             {@releases_table, package_name, version, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_}
           )
         end) do
      {:atomic, []} ->
        {:error, :not_found}

      {:atomic, releases} when is_list(releases) ->
        # For :bag type, take the most recent one (last written)
        release =
          Enum.max_by(releases, fn {_, _, _, _, _, _, _, _, _, updated_at, _, _, _, _} ->
            updated_at
          end)

        {:ok, release_to_map(release)}

      {:aborted, _reason} ->
        {:error, :not_found}
    end
  end

  @doc """
  List releases for a package.
  """
  @spec list_releases(String.t()) :: {:ok, [release()]}
  def list_releases(package_name) do
    case :mnesia.transaction(fn ->
           :mnesia.match_object(
             {@releases_table, package_name, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_}
           )
         end) do
      {:atomic, releases} ->
        {:ok, Enum.map(releases, &release_to_map/1)}

      {:aborted, reason} ->
        {:error, "Failed to list releases: #{inspect(reason)}"}
    end
  end

  @doc """
  Upload documentation for a release.
  """
  @spec upload_docs(String.t(), String.t(), binary()) :: {:ok, release()} | {:error, String.t()}
  def upload_docs(package_name, version, docs_tarball) do
    case get_release(package_name, version) do
      {:ok, _release} ->
        docs_key = Storage.generate_docs_key(package_name, version)

        case Storage.upload(docs_key, docs_tarball) do
          {:ok, _} ->
            # Update release to mark has_docs as true
            case :mnesia.transaction(fn ->
                   releases =
                     :mnesia.match_object(
                       {@releases_table, package_name, version, :_, :_, :_, :_, :_, :_, :_, :_,
                        :_, :_, :_}
                     )

                   case releases do
                     [] ->
                       {:error, "Release not found"}

                     releases ->
                       # For :bag type, update all matching records and delete old ones
                       Enum.each(releases, fn release_tuple ->
                         {_, pkg_name, ver, _has_docs, meta, requirements, retired, downloads,
                          inserted_at, _updated_at, url, package_url, html_url,
                          docs_html_url} = release_tuple

                         updated_release = {
                           @releases_table,
                           pkg_name,
                           ver,
                           # has_docs
                           true,
                           meta,
                           requirements,
                           retired,
                           downloads,
                           inserted_at,
                           DateTime.utc_now(),
                           url,
                           package_url,
                           html_url,
                           docs_html_url
                         }

                         :mnesia.write(updated_release)
                       end)

                       {:ok, hd(releases)}
                   end
                 end) do
              {:atomic, {:ok, _release_tuple}} ->
                case get_release(package_name, version) do
                  {:ok, release} -> {:ok, release}
                  error -> error
                end

              {:atomic, {:error, reason}} ->
                Storage.delete(docs_key)
                {:error, reason}

              {:aborted, reason} ->
                Storage.delete(docs_key)
                {:error, "Failed to update release: #{inspect(reason)}"}
            end

          {:error, reason} ->
            {:error, "Failed to upload docs: #{reason}"}
        end

      {:error, :not_found} ->
        {:error, "Release not found"}
    end
  end

  @doc """
  Download package tarball.
  """
  @spec download_package(String.t(), String.t()) :: {:ok, binary()} | {:error, String.t()}
  def download_package(package_name, version) do
    package_key = Storage.generate_package_key(package_name, version)
    Storage.download(package_key)
  end

  @doc """
  Download documentation tarball.
  """
  @spec download_docs(String.t(), String.t()) :: {:ok, binary()} | {:error, String.t()}
  def download_docs(package_name, version) do
    docs_key = Storage.generate_docs_key(package_name, version)
    Storage.download(docs_key)
  end

  @doc """
  Delete documentation for a release.
  """
  @spec delete_docs(String.t(), String.t()) :: {:ok, release()} | {:error, String.t()}
  def delete_docs(package_name, version) do
    docs_key = Storage.generate_docs_key(package_name, version)

    case Storage.delete(docs_key) do
      :ok ->
        # Update release to mark has_docs as false
        case :mnesia.transaction(fn ->
               releases =
                 :mnesia.match_object(
                   {@releases_table, package_name, version, :_, :_, :_, :_, :_, :_, :_, :_, :_,
                    :_, :_}
                 )

               case releases do
                 [] ->
                   {:error, "Release not found"}

                 releases ->
                   # For :bag type, update all matching records
                   Enum.each(releases, fn release_tuple ->
                     {_, pkg_name, ver, _has_docs, meta, requirements, retired, downloads,
                      inserted_at, _updated_at, url, package_url, html_url,
                      docs_html_url} = release_tuple

                     updated_release = {
                       @releases_table,
                       pkg_name,
                       ver,
                       # has_docs
                       false,
                       meta,
                       requirements,
                       retired,
                       downloads,
                       inserted_at,
                       DateTime.utc_now(),
                       url,
                       package_url,
                       html_url,
                       docs_html_url
                     }

                     :mnesia.write(updated_release)
                   end)

                   {:ok, hd(releases)}
               end
             end) do
          {:atomic, {:ok, _release_tuple}} ->
            case get_release(package_name, version) do
              {:ok, release} -> {:ok, release}
              error -> error
            end

          {:atomic, {:error, reason}} ->
            {:error, reason}

          {:aborted, reason} ->
            {:error, "Failed to update release: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, "Failed to delete docs: #{reason}"}
    end
  end

  ## Helper functions

  defp package_to_map(
         {@packages_table, name, repository_name, meta, private, downloads, inserted_at,
          updated_at, html_url, docs_html_url}
       ) do
    %{
      name: name,
      repository_name: repository_name,
      meta: meta,
      private: private,
      downloads: downloads,
      inserted_at: inserted_at,
      updated_at: updated_at,
      html_url: html_url,
      docs_html_url: docs_html_url
    }
  end

  defp release_to_map(
         {@releases_table, package_name, version, has_docs, meta, requirements, retired,
          downloads, inserted_at, updated_at, url, package_url, html_url, docs_html_url}
       ) do
    %{
      package_name: package_name,
      version: version,
      has_docs: has_docs,
      meta: meta,
      requirements: requirements,
      retired: retired,
      downloads: downloads,
      inserted_at: inserted_at,
      updated_at: updated_at,
      url: url,
      package_url: package_url,
      html_url: html_url,
      docs_html_url: docs_html_url
    }
  end

  defp validate_package_name(name) do
    cond do
      String.length(name) < 1 ->
        {:error, "Package name must not be empty"}

      String.length(name) > 100 ->
        {:error, "Package name must be at most 100 characters"}

      not String.match?(name, ~r/^[a-z][a-z0-9_]*$/) ->
        {:error,
         "Package name must start with lowercase letter and contain only lowercase letters, numbers, and underscores"}

      true ->
        :ok
    end
  end

  defp validate_version(version) do
    cond do
      String.length(version) < 1 ->
        {:error, "Version must not be empty"}

      not String.match?(version, ~r/^\d+\.\d+\.\d+.*$/) ->
        {:error, "Version must be in semantic versioning format"}

      true ->
        :ok
    end
  end
end
