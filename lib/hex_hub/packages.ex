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
    start_time = System.monotonic_time()

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
          package_map = package_to_map(package)

          duration_ms =
            (System.monotonic_time() - start_time)
            |> System.convert_time_unit(:native, :millisecond)

          HexHub.Telemetry.track_mnesia_operation("create_package", duration_ms)
          HexHub.Telemetry.track_package_published(repository_name)

          HexHub.Audit.log_event("package_created", "package", name, %{
            repository: repository_name,
            private: private
          })

          {:ok, package_map}

        {:aborted, reason} ->
          duration_ms =
            (System.monotonic_time() - start_time)
            |> System.convert_time_unit(:native, :millisecond)

          HexHub.Telemetry.track_mnesia_operation("create_package", duration_ms)
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
           # Use dirty_read for better performance when we know the exact key
           case :mnesia.dirty_read(@packages_table, name) do
             [
               {@packages_table, name, repository_name, meta, private, downloads, inserted_at,
                updated_at, html_url, docs_html_url}
             ] ->
               {:ok,
                package_to_map(
                  {@packages_table, name, repository_name, meta, private, downloads, inserted_at,
                   updated_at, html_url, docs_html_url}
                )}

             [] ->
               {:error, :not_found}
           end
         end) do
      {:atomic, result} -> result
      {:aborted, _reason} -> {:error, :not_found}
    end
  end

  @doc """
  List all packages with optional search and pagination.
  """
  @spec list_packages(keyword()) :: {:ok, [package()], integer()}
  def list_packages(opts \\ []) do
    search_term = Keyword.get(opts, :search)
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 50)

    offset = (page - 1) * per_page

    case :mnesia.transaction(fn ->
           # Use transaction for consistency
           packages =
             :mnesia.foldl(
               fn {_, name, repository_name, meta, private, downloads, inserted_at, updated_at,
                   html_url, docs_html_url},
                  acc ->
                 package =
                   package_to_map(
                     {@packages_table, name, repository_name, meta, private, downloads,
                      inserted_at, updated_at, html_url, docs_html_url}
                   )

                 # Filter by search term if provided
                 if matches_search?(package, search_term) do
                   [package | acc]
                 else
                   acc
                 end
               end,
               [],
               @packages_table
             )

           # Sort by downloads (descending) and then by name
           sorted_packages = Enum.sort_by(packages, &{-&1.downloads, &1.name})

           total_count = length(sorted_packages)

           paginated_packages =
             sorted_packages
             |> Enum.drop(offset)
             |> Enum.take(per_page)

           {paginated_packages, total_count}
         end) do
      {:atomic, {packages, total}} -> {:ok, packages, total}
      {:aborted, reason} -> {:error, "Failed to list packages: #{inspect(reason)}"}
    end
  end

  @doc """
  Search packages by name or description.
  """
  @spec search_packages(String.t(), keyword()) :: {:ok, [package()], integer()}
  def search_packages(query, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 50)

    list_packages(search: query, page: page, per_page: per_page)
  end

  defp matches_search?(_package, nil), do: true
  defp matches_search?(_package, ""), do: true

  defp matches_search?(package, search_term) do
    search_term = String.downcase(search_term)
    name_match = package.name |> String.downcase() |> String.contains?(search_term)

    description_match =
      case package.meta["description"] do
        nil -> false
        description -> description |> String.downcase() |> String.contains?(search_term)
      end

    name_match or description_match
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
              release_map = release_to_map(release)

              HexHub.Audit.log_event(
                "release_created",
                "package_release",
                "#{package_name}-#{version}",
                %{
                  package_name: package_name,
                  version: version,
                  meta: meta
                }
              )

              {:ok, release_map}

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
           # Match all releases for this package and version
           :mnesia.match_object(
             {@releases_table, package_name, version, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_}
           )
         end) do
      {:atomic, []} ->
        {:error, :not_found}

      {:atomic, releases} when is_list(releases) ->
        # For :bag type, take the most recent one (last written)
        release =
          Enum.max_by(releases, fn release_tuple ->
            case release_tuple do
              {@releases_table, _, _, _, _, _, _, _, updated_at, _, _, _, _} -> updated_at
              # fallback
              _ -> DateTime.utc_now()
            end
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
                         {@releases_table, pkg_name, ver, _has_docs, meta, requirements, retired,
                          downloads, inserted_at, _updated_at, url, package_url, html_url,
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

                       {:ok, :updated}
                   end
                 end) do
              {:atomic, {:ok, _}} ->
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
                     {@releases_table, pkg_name, ver, _has_docs, meta, requirements, retired,
                      downloads, inserted_at, _updated_at, url, package_url, html_url,
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

                   {:ok, :updated}
               end
             end) do
          {:atomic, {:ok, _}} ->
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

  @doc """
  Retire a package release.
  """
  @spec retire_release(String.t(), String.t()) :: {:ok, release()} | {:error, String.t()}
  def retire_release(package_name, version) do
    case get_release(package_name, version) do
      {:ok, _release} ->
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
                     {_, pkg_name, ver, has_docs, meta, requirements, _retired, downloads,
                      inserted_at, _updated_at, url, package_url, html_url,
                      docs_html_url} = release_tuple

                     updated_release = {
                       @releases_table,
                       pkg_name,
                       ver,
                       has_docs,
                       meta,
                       requirements,
                       # retired
                       true,
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
          {:atomic, {:ok, release_tuple}} ->
            {:ok, release_to_map(release_tuple)}

          {:atomic, {:error, reason}} ->
            {:error, reason}

          {:aborted, reason} ->
            {:error, "Failed to retire release: #{inspect(reason)}"}
        end

      {:error, :not_found} ->
        {:error, "Release not found"}
    end
  end

  @doc """
  Unretire a package release.
  """
  @spec unretire_release(String.t(), String.t()) :: {:ok, release()} | {:error, String.t()}
  def unretire_release(package_name, version) do
    case get_release(package_name, version) do
      {:ok, _release} ->
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
                     {_, pkg_name, ver, has_docs, meta, requirements, _retired, downloads,
                      inserted_at, _updated_at, url, package_url, html_url,
                      docs_html_url} = release_tuple

                     updated_release = {
                       @releases_table,
                       pkg_name,
                       ver,
                       has_docs,
                       meta,
                       requirements,
                       # retired
                       false,
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
          {:atomic, {:ok, release_tuple}} ->
            {:ok, release_to_map(release_tuple)}

          {:atomic, {:error, reason}} ->
            {:error, reason}

          {:aborted, reason} ->
            {:error, "Failed to unretire release: #{inspect(reason)}"}
        end

      {:error, :not_found} ->
        {:error, "Release not found"}
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

  @doc """
  List all unique repository names from packages.
  """
  @spec list_repositories() :: list(map())
  def list_repositories() do
    case :mnesia.transaction(fn ->
           :mnesia.foldl(
             fn {_, _name, repository_name, _meta, _private, _downloads, _inserted_at,
                 _updated_at, _html_url, _docs_html_url},
                acc ->
               MapSet.put(acc, repository_name)
             end,
             MapSet.new(),
             @packages_table
           )
         end) do
      {:atomic, repository_names} ->
        Enum.map(MapSet.to_list(repository_names), fn name ->
          %{
            name: name,
            package_count: count_packages_in_repository(name),
            inserted_at: DateTime.utc_now(),
            updated_at: DateTime.utc_now()
          }
        end)

      {:aborted, _reason} ->
        []
    end
  end

  @doc """
  Get a specific repository by name.
  """
  @spec get_repository(String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_repository(name) do
    case :mnesia.transaction(fn ->
           :mnesia.match_object({@packages_table, :_, name, :_, :_, :_, :_, :_, :_, :_})
         end) do
      {:atomic, []} ->
        {:error, :not_found}

      {:atomic, packages} ->
        {:ok,
         %{
           name: name,
           package_count: length(packages),
           inserted_at: DateTime.utc_now(),
           updated_at: DateTime.utc_now()
         }}

      {:aborted, _reason} ->
        {:error, :not_found}
    end
  end

  @doc """
  Create a new repository. This is a logical operation since repositories
  are currently just names associated with packages.
  """
  @spec create_repository(map()) :: {:ok, map()} | {:error, Ecto.Changeset.t()}
  def create_repository(params) do
    name = params["name"] || params[:name]

    if String.trim(name) == "" do
      {:error, %{name: ["can't be blank"]}}
    else
      # Check if repository already exists
      case :mnesia.transaction(fn ->
             :mnesia.match_object({@packages_table, :_, name, :_, :_, :_, :_, :_, :_, :_})
           end) do
        {:atomic, []} ->
          {:ok,
           %{
             name: name,
             package_count: 0,
             inserted_at: DateTime.utc_now(),
             updated_at: DateTime.utc_now()
           }}

        {:atomic, _packages} ->
          {:error, %{name: ["has already been taken"]}}

        {:aborted, _reason} ->
          {:error, %{name: ["database error"]}}
      end
    end
  end

  @doc """
  Update a repository name. This involves updating all packages in the repository.
  """
  @spec update_repository(String.t(), map()) :: {:ok, map()} | {:error, Ecto.Changeset.t()}
  def update_repository(old_name, params) do
    new_name = params["name"] || params[:name]

    if String.trim(new_name) == "" do
      {:error, %{name: ["can't be blank"]}}
    else
      case :mnesia.transaction(fn ->
             packages =
               :mnesia.match_object({@packages_table, :_, old_name, :_, :_, :_, :_, :_, :_, :_})

             # Update all packages with the new repository name
             Enum.each(packages, fn {table, pkg_name, _old_repo, meta, private, downloads,
                                     inserted_at, _updated_at, html_url, docs_html_url} ->
               updated_package = {
                 table,
                 pkg_name,
                 new_name,
                 meta,
                 private,
                 downloads,
                 inserted_at,
                 DateTime.utc_now(),
                 html_url,
                 docs_html_url
               }

               :mnesia.write(updated_package)
             end)

             :ok
           end) do
        {:atomic, :ok} ->
          {:ok,
           %{
             name: new_name,
             package_count: count_packages_in_repository(new_name),
             inserted_at: DateTime.utc_now(),
             updated_at: DateTime.utc_now()
           }}

        {:aborted, _reason} ->
          {:error, %{name: ["update failed"]}}
      end
    end
  end

  @doc """
  Delete a repository. This involves deleting all packages in the repository.
  """
  @spec delete_repository(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def delete_repository(name) do
    case :mnesia.transaction(fn ->
           packages =
             :mnesia.match_object({@packages_table, :_, name, :_, :_, :_, :_, :_, :_, :_})

           # Delete all packages in the repository
           Enum.each(packages, fn {table, pkg_name, _repo, _meta, _private, _downloads,
                                   _inserted_at, _updated_at, _html_url, _docs_html_url} ->
             :mnesia.delete({table, pkg_name})
           end)

           # Also delete all releases for packages in this repository
           Enum.each(packages, fn {_table, pkg_name, _repo, _meta, _private, _downloads,
                                   _inserted_at, _updated_at, _html_url, _docs_html_url} ->
             releases =
               :mnesia.match_object(
                 {@releases_table, pkg_name, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_}
               )

             Enum.each(releases, fn {rel_table, _pkg_name, version, _has_docs, _meta,
                                     _requirements, _retired, _downloads, _inserted_at,
                                     _updated_at, _url, _package_url, _html_url,
                                     _docs_html_url} ->
               :mnesia.delete({rel_table, {pkg_name, version}})
             end)
           end)

           :ok
         end) do
      {:atomic, :ok} ->
        {:ok, name}

      {:aborted, _reason} ->
        {:error, "delete failed"}
    end
  end

  @doc """
  Delete a specific package and all its releases.
  """
  @spec delete_package(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def delete_package(name) do
    case :mnesia.transaction(fn ->
           # Get the package first
           case :mnesia.read({@packages_table, name}) do
             [] ->
               {:error, :not_found}

             [_package] ->
               # Delete the package
               :mnesia.delete({@packages_table, name})

               # Delete all releases for this package
               releases =
                 :mnesia.match_object(
                   {@releases_table, name, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_}
                 )

               Enum.each(releases, fn {rel_table, _pkg_name, version, _has_docs, _meta,
                                       _requirements, _retired, _downloads, _inserted_at,
                                       _updated_at, _url, _package_url, _html_url,
                                       _docs_html_url} ->
                 :mnesia.delete({rel_table, {name, version}})
               end)

               # Delete package owners
               owners =
                 :mnesia.match_object({@owners_table, name, :_})

               Enum.each(owners, fn {owner_table, _pkg_name, _username} ->
                 :mnesia.delete({owner_table, name})
               end)

               {:ok, name}
           end
         end) do
      {:atomic, {:ok, name}} ->
        {:ok, name}

      {:atomic, {:error, reason}} ->
        {:error, reason}

      {:aborted, _reason} ->
        {:error, "delete failed"}
    end
  end

  @spec count_packages_in_repository(String.t()) :: integer()
  defp count_packages_in_repository(name) do
    case :mnesia.transaction(fn ->
           :mnesia.match_object({@packages_table, :_, name, :_, :_, :_, :_, :_, :_, :_})
         end) do
      {:atomic, packages} -> length(packages)
      {:aborted, _reason} -> 0
    end
  end
end
