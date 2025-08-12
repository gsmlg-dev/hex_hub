#!/bin/bash

# HexHub Cluster Management Script
# This script helps manage Mnesia clustering for high availability

set -e

NODE_NAME=${NODE_NAME:-hex_hub}
COOKIE=${COOKIE:-hex_hub_cluster_cookie}
CLUSTER_NODES=${CLUSTER_NODES:-}
CLUSTERING_ENABLED=${CLUSTERING_ENABLED:-false}

show_help() {
    echo "Usage: $0 {start|join|leave|status|help}"
    echo ""
    echo "Commands:"
    echo "  start [port]  - Start a single node with optional port (default: 4000)"
    echo "  join node     - Join an existing cluster"
    echo "  leave         - Leave the current cluster"
    echo "  status        - Show cluster status"
    echo "  help          - Show this help"
    echo ""
    echo "Environment Variables:"
    echo "  NODE_NAME     - Node name (default: hex_hub)"
    echo "  COOKIE        - Erlang cookie for cluster communication"
    echo "  CLUSTER_NODES - Comma-separated list of cluster nodes"
    echo "  PORT          - HTTP port (default: 4000)"
}

start_node() {
    local port=${1:-4000}
    local node_name="${NODE_NAME}@127.0.0.1"
    
    echo "Starting HexHub node: $node_name on port $port"
    echo "Clustering enabled: $CLUSTERING_ENABLED"
    
    if [ "$CLUSTERING_ENABLED" = "true" ]; then
        export CLUSTERING_ENABLED=true
        export CLUSTER_NODES="$CLUSTER_NODES"
    fi
    
    # Set Erlang cookie for clustering
    export ERL_AFLAGS="-kernel prevent_overlapping_partitions false"
    export ERL_EPMD_ADDRESS=127.0.0.1
    
    # Start Phoenix with proper node name
    elixir --name "$node_name" --cookie "$COOKIE" -S mix phx.server --port "$port"
}

join_cluster() {
    local target_node="$1"
    
    if [ -z "$target_node" ]; then
        echo "Error: Target node required"
        show_help
        exit 1
    fi
    
    echo "Attempting to join cluster: $target_node"
    
    # Make HTTP request to join cluster
    curl -X POST "http://localhost:4000/api/cluster/join" \
         -H "Content-Type: application/json" \
         -d "{\"node\":\"$target_node\"}"
    echo
}

leave_cluster() {
    echo "Leaving cluster..."
    
    # Make HTTP request to leave cluster
    curl -X POST "http://localhost:4000/api/cluster/leave" \
         -H "Content-Type: application/json"
    echo
}

show_status() {
    echo "Cluster Status:"
    curl -s "http://localhost:4000/api/cluster/status" | jq '.' || echo "Node not accessible"
}

# Main script logic
case "$1" in
    start)
        start_node "$2"
        ;;
    join)
        join_cluster "$2"
        ;;
    leave)
        leave_cluster
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Error: Unknown command '$1'"
        show_help
        exit 1
        ;;
esac