defmodule HexHub.Clustering do
  @moduledoc """
  Mnesia clustering configuration and management for high availability.
  
  This module provides functionality to:
  - Configure Mnesia clustering between nodes
  - Handle node discovery and joining
  - Manage table replication across nodes
  - Provide failover and recovery capabilities
  """

  require Logger

  @doc """
  Initialize Mnesia clustering based on configuration.
  """
  def init_clustering do
    case Application.get_env(:hex_hub, :clustering, %{}) do
      %{enabled: true} = config ->
        configure_clustering(config)
      _ ->
        :ok
    end
  end

  @doc """
  Configure Mnesia clustering with the given configuration.
  """
  def configure_clustering(config) do
    Logger.info("Configuring Mnesia clustering...")
    
    # Set Mnesia directory
    mnesia_dir = Application.get_env(:hex_hub, :mnesia_dir, "./mnesia/#{node()}")
    :mnesia.stop()
    :mnesia.change_config(:dir, to_charlist(mnesia_dir))
    
    # Set schema location
    :mnesia.set_master_nodes([node()])
    
    # Configure table replication
    configure_table_replication(config)
    
    # Start Mnesia
    case :mnesia.start() do
      :ok ->
        Logger.info("Mnesia started successfully")
        :ok
      {:error, {:already_started, _}} ->
        Logger.info("Mnesia already started")
        :ok
      error ->
        Logger.error("Failed to start Mnesia: #{inspect(error)}")
        error
    end
  end

  @doc """
  Configure table replication across cluster nodes.
  """
  def configure_table_replication(config) do
    nodes = get_cluster_nodes(config)
    
    if Enum.empty?(nodes) do
      Logger.info("Running in single-node mode")
      :ok
    else
      Logger.info("Configuring replication across nodes: #{inspect(nodes)}")
      
      # Ensure schema is created on all nodes
      :mnesia.change_table_copy_type(:schema, node(), :disc_copies)
      
      Enum.each(nodes, fn node ->
        if node != node() do
          :mnesia.change_table_copy_type(:schema, node, :disc_copies)
        end
      end)
      
      # Configure replication for each table
      tables = [:packages, :package_releases, :package_owners, :users, :keys, :audit_logs]
      
      Enum.each(tables, fn table ->
        configure_table_replication_for(table, nodes, config)
      end)
      
      :ok
    end
  end

  defp configure_table_replication_for(table, nodes, config) do
    replication_factor = Map.get(config, :replication_factor, 2)
    
    case :mnesia.create_table(table, [
           attributes: get_table_attributes(table),
           type: get_table_type(table),
           disc_copies: Enum.take(nodes ++ [node()], replication_factor)
         ]) do
      {:atomic, :ok} ->
        Logger.info("Created table #{table} with replication")
      {:aborted, {:already_exists, ^table}} ->
        Logger.info("Table #{table} already exists, updating replication")
        update_table_replication(table, nodes, replication_factor)
      error ->
        Logger.error("Failed to create table #{table}: #{inspect(error)}")
    end
  end

  defp update_table_replication(table, nodes, replication_factor) do
    current_copies = :mnesia.table_info(table, :disc_copies)
    target_nodes = Enum.take(nodes ++ [node()], replication_factor)
    
    # Add missing copies
    Enum.each(target_nodes -- current_copies, fn node ->
      Logger.info("Adding #{table} replica on #{node}")
      :mnesia.add_table_copy(table, node, :disc_copies)
    end)
    
    # Remove extra copies
    Enum.each(current_copies -- target_nodes, fn node ->
      Logger.info("Removing #{table} replica from #{node}")
      :mnesia.del_table_copy(table, node)
    end)
  end

  defp get_table_attributes(:packages), do: [:name, :repository_name, :meta, :private, :downloads, :inserted_at, :updated_at, :html_url, :docs_html_url]
  defp get_table_attributes(:package_releases), do: [:package_name, :version, :has_docs, :meta, :requirements, :retired, :downloads, :inserted_at, :updated_at, :url, :package_url, :html_url, :docs_html_url]
  defp get_table_attributes(:package_owners), do: [:package_name, :user_id, :level, :inserted_at]
  defp get_table_attributes(:users), do: [:id, :username, :email, :full_name, :inserted_at, :updated_at]
  defp get_table_attributes(:keys), do: [:id, :user_id, :name, :permissions, :last_used_at, :inserted_at]
  defp get_table_attributes(:audit_logs), do: [:id, :action, :entity_type, :entity_id, :metadata, :user_id, :timestamp]
  defp get_table_attributes(_), do: []

  defp get_table_type(:packages), do: :set
  defp get_table_type(:package_releases), do: :bag
  defp get_table_type(:package_owners), do: :bag
  defp get_table_type(:users), do: :set
  defp get_table_type(:keys), do: :set
  defp get_table_type(:audit_logs), do: :set

  @doc """
  Get cluster nodes from configuration.
  """
  def get_cluster_nodes(config) do
    case config do
      %{nodes: nodes} when is_list(nodes) ->
        Enum.map(nodes, &String.to_atom/1)
      %{discovery: %{type: "dns", hostname: hostname}} ->
        discover_nodes_via_dns(hostname)
      %{discovery: %{type: "epmd"}} ->
        discover_nodes_via_epmd()
      _ ->
        []
    end
  end

  @doc """
  Discover cluster nodes via DNS SRV records.
  """
  def discover_nodes_via_dns(hostname) do
    case :inet_res.getbyname(to_charlist("_epmd._tcp.#{hostname}"), :srv) do
      {:ok, {:hostent, _name, _aliases, :srv, _class, records}} ->
        Enum.map(records, fn {_priority, _weight, _port, host} ->
          String.to_atom("#{node_name()}@#{to_string(host)}")
        end)
      _ ->
        []
    end
  end

  @doc """
  Discover cluster nodes via EPMD.
  """
  def discover_nodes_via_epmd do
    case :net_adm.names() do
      {:ok, names} ->
        Enum.map(names, fn {name, _port} ->
          String.to_atom("#{name}@#{node_host()}")
        end)
      _ ->
        []
    end
  end

  @doc """
  Join an existing cluster.
  """
  def join_cluster(node) when is_binary(node), do: join_cluster(String.to_atom(node))
  def join_cluster(node) do
    Logger.info("Attempting to join cluster node: #{node}")
    
    case :net_adm.ping(node) do
      :pong ->
        Logger.info("Successfully connected to #{node}")
        
        # Stop Mnesia to change configuration
        :mnesia.stop()
        
        # Change schema to include new node
        :mnesia.change_config(:extra_db_nodes, [node])
        
        # Start Mnesia
        :mnesia.start()
        
        # Wait for tables to load
        wait_for_tables()
        
        Logger.info("Successfully joined cluster")
        {:ok, :joined}
      :pang ->
        Logger.error("Failed to connect to #{node}")
        {:error, :connection_failed}
    end
  end

  @doc """
  Leave the cluster.
  """
  def leave_cluster do
    Logger.info("Leaving cluster...")
    
    # Stop Mnesia
    :mnesia.stop()
    
    # Reset schema
    :mnesia.delete_schema([node()])
    
    # Start fresh
    :mnesia.start()
    
    Logger.info("Left cluster successfully")
    {:ok, :left}
  end

  @doc """
  Wait for all tables to be loaded.
  """
  def wait_for_tables do
    tables = [:packages, :package_releases, :package_owners, :users, :keys, :audit_logs]
    
    case :mnesia.wait_for_tables(tables, 30_000) do
      :ok ->
        Logger.info("All tables loaded successfully")
        :ok
      {:timeout, failed_tables} ->
        Logger.error("Timeout waiting for tables: #{inspect(failed_tables)}")
        {:error, :timeout}
      error ->
        Logger.error("Error waiting for tables: #{inspect(error)}")
        error
    end
  end

  @doc """
  Get cluster status information.
  """
  def get_cluster_status do
    %{
      node: node(),
      running: :mnesia.system_info(:is_running),
      tables: Enum.map([:packages, :package_releases, :package_owners, :users, :keys, :audit_logs], fn table ->
        %{
          name: table,
          size: :mnesia.table_info(table, :size),
          memory: :mnesia.table_info(table, :memory),
          disc_copies: :mnesia.table_info(table, :disc_copies),
          ram_copies: :mnesia.table_info(table, :ram_copies)
        }
      end),
      connected_nodes: Node.list()
    }
  end

  defp node_name do
    node()
    |> Atom.to_string()
    |> String.split("@")
    |> hd()
  end

  defp node_host do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end
end