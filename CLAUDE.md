# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HexHub is a **complete private hex package manager and hexdocs server** built with Phoenix 1.8.0-rc.4 and Elixir 1.15+. It provides a **drop-in replacement for hex.pm** with complete API compatibility, using Mnesia for zero-database storage and clustering support for high availability.

## Key Architecture

- **Phoenix Framework 1.8.0-rc.4**: Web layer with LiveView for real-time features
- **Mnesia**: In-memory distributed database (no PostgreSQL required)
- **Tailwind CSS + DaisyUI**: Modern styling with responsive design
- **Bun**: JavaScript bundling and build tooling
- **Bandit**: High-performance HTTP server
- **Swoosh**: Email functionality
- **Libcluster**: Automatic cluster formation and discovery
- **Local/S3 Storage**: Flexible package and documentation storage

## Quick Start Commands

### Development Setup
```bash
# Install dependencies and setup (no database setup needed)
mix setup

# Start development server
mix phx.server

# Run comprehensive test suite (94 tests, 100% passing)
mix test

# Start with clustering
PORT=4000 NODE_NAME=hex_hub1 ./scripts/cluster.sh start
```

### Asset Management
```bash
# Build assets for development
mix assets.build

# Deploy/minify assets for production
mix assets.deploy

# Setup asset tools
mix assets.setup
```

### Testing & Quality
```bash
# Run all tests with coverage
mix test --cover

# Run specific test file
mix test test/hex_hub_web/controllers/api/package_controller_test.exs

# Run tests matching pattern
mix test --only user

# Format code
mix format

# Static analysis
mix credo

# Type checking
mix dialyzer

# Check dependency status
mix deps.tree

# Clean and recompile
mix deps.clean --build && mix deps.get && mix compile
```

## Project Structure

```
lib/
├── hex_hub/                    # Core business logic
│   ├── api_keys.ex            # API key management
│   ├── packages.ex            # Package operations
│   ├── users.ex               # User management
│   ├── storage.ex             # File storage abstraction
│   ├── clustering.ex          # Mnesia cluster management
│   └── mnesia.ex              # Database setup and queries
├── hex_hub_web/               # Main web interface
│   ├── controllers/           # Web controllers
│   ├── components/            # LiveView components
│   └── router.ex             # Web routes
├── hex_hub_admin_web/         # Admin dashboard
│   ├── controllers/           # Admin controllers
│   └── components/            # Admin UI components
```

## Key Files

- `mix.exs` - Dependencies and project configuration
- `hex-api.yaml` - Complete OpenAPI specification for Hex API
- `config/config.exs` - General configuration
- `config/clustering.exs` - Mnesia clustering configuration
- `lib/hex_hub/mnesia.ex` - Mnesia database setup and table definitions
- `lib/hex_hub/clustering.ex` - Cluster management logic
- `lib/hex_hub/storage.ex` - Storage abstraction (local/S3)
- `scripts/cluster.sh` - Cluster management script

## Important Development Notes

### Mnesia Database
- **No external database required** - uses Mnesia for storage
- Tables auto-initialize on first run
- Data stored in `Mnesia.<node_name>/` directory
- Test data is isolated automatically
- Use `:mnesia.info()` in IEx for debugging

### Storage Architecture
- **Local storage** (default): `priv/storage/`
- **S3 storage** (production): Configure via environment variables
- Storage abstraction in `lib/hex_hub/storage.ex` handles both

### API Testing
- All endpoints require API key authentication
- Use `mix test` for comprehensive test coverage (94 tests)
- API tests in `test/hex_hub_web/controllers/api/`
- Test users and API keys auto-created in test setup

## Environment Configuration

### Development
- **Mnesia**: Automatic setup, RAM + disk storage
- **Storage**: Local filesystem at `priv/storage/`
- **Clustering**: Optional, via `CLUSTERING_ENABLED=true`

### Production
- **Mnesia**: Disk persistence with clustering
- **Storage**: Configurable (local/S3)
- **Clustering**: Automatic with libcluster

### Environment Variables
```bash
# Required
SECRET_KEY_BASE=your-64-byte-secret  # Generate with `mix phx.gen.secret`
PHX_HOST=your-domain.com             # Host for URL generation

# Optional
CLUSTERING_ENABLED=true              # Enable clustering
MNESIA_DIR=/app/mnesia              # Mnesia data directory
STORAGE_TYPE=local                  # or s3
S3_BUCKET=your-bucket               # S3 configuration

# S3 Configuration (when STORAGE_TYPE=s3)
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
AWS_S3_HOST=your-s3-host            # For S3-compatible services
AWS_S3_PORT=9000                     # Custom S3 port
AWS_S3_PATH_STYLE=true               # Required for MinIO

# Upstream Configuration
UPSTREAM_ENABLED=true                # Enable upstream package fetching
UPSTREAM_URL=https://hex.pm          # Upstream hex repository URL
UPSTREAM_TIMEOUT=30000               # Request timeout in milliseconds
UPSTREAM_RETRY_ATTEMPTS=3            # Number of retry attempts
UPSTREAM_RETRY_DELAY=1000            # Delay between retries in milliseconds
```

## API Implementation Status ✅

### Completed Endpoints
- **Users**: Registration, authentication, profiles, password reset
- **Packages**: Publishing, retrieval, search, metadata
- **Releases**: Version management, retirement, documentation
- **Repositories**: Private/public repository management
- **API Keys**: Generation, management, authentication
- **Documentation**: Upload, serving, version management
- **Ownership**: Package ownership management

### Test Coverage ✅
- 94 comprehensive tests
- 100% API endpoint coverage
- Mnesia transaction testing
- Clustering and failover tests
- Security and authorization tests

## Advanced Features

### Mnesia Clustering
- **High Availability**: Automatic failover and data replication
- **Scalability**: Add nodes dynamically
- **Persistence**: Disk-based storage with RAM caching
- **Consistency**: Transactional guarantees

### Storage Options
- **Local Filesystem**: Default for development
- **S3 Compatible**: Production-ready with CDN support
- **Hybrid**: Mixed storage strategies

### Security
- **API Key Authentication**: Bearer token support
- **Basic Auth**: For API key creation
- **Rate Limiting**: Configurable per-endpoint
- **HTTPS Ready**: Production deployment ready

## Clustering Commands

### Development Cluster
```bash
# Start 3-node cluster
PORT=4000 NODE_NAME=hex_hub1 ./scripts/cluster.sh start
PORT=4001 NODE_NAME=hex_hub2 ./scripts/cluster.sh start  
PORT=4002 NODE_NAME=hex_hub3 ./scripts/cluster.sh start

# Join cluster
./scripts/cluster.sh join hex_hub1@127.0.0.1

# Check status
./scripts/cluster.sh status
```

### Production Cluster
```bash
# Docker deployment
docker-compose up -d

# Kubernetes
kubectl apply -f k8s/

# Build and deploy release
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release
_build/prod/rel/hex_hub/bin/hex_hub start
```

## Monitoring & Debugging

### LiveDashboard
- Available at `/dev/dashboard` in development
- Mnesia-specific metrics and queries
- Cluster status and node health
- Real-time performance monitoring

### Health Checks
- `/health` - Basic health check
- `/health/ready` - Kubernetes readiness
- `/health/live` - Kubernetes liveness
- `/api/cluster/status` - Cluster status

## Performance Characteristics

- **Query Performance**: <50ms Mnesia queries
- **Horizontal Scaling**: Linear scaling with cluster nodes
- **Storage**: Efficient binary storage for packages/docs
- **Memory**: RAM + disk hybrid storage strategy

## Common Development Patterns

### Adding New API Endpoints
1. Define route in `lib/hex_hub_web/router.ex`
2. Create controller in `lib/hex_hub_web/controllers/api/`
3. Add business logic to appropriate context in `lib/hex_hub/`
4. Add tests in `test/hex_hub_web/controllers/api/`
5. Update `hex-api.yaml` if exposing public API

### Database Schema Changes
1. Modify table definitions in `lib/hex_hub/mnesia.ex`
2. Add migration logic for existing data
3. Update test fixtures in `test/support/`
4. Test with `mix test` (data automatically reset between tests)

### Adding New Storage Types
1. Implement storage callbacks in `lib/hex_hub/storage.ex`
2. Add configuration to `config/config.exs`
3. Add tests for new storage type
4. Update environment variable documentation

### Upstream Package Fetching
HexHub supports automatic upstream package fetching when packages are not available locally. This allows you to create a transparent caching proxy for hex.pm or any other hex-compatible repository.

#### Upstream Features
- **Transparent Fallback**: Automatically fetches packages from upstream when not found locally
- **Permanent Caching**: Once fetched, packages are cached indefinitely for faster access
- **Configurable Upstream**: Support for any hex-compatible repository
- **Retry Logic**: Automatic retry with exponential backoff for network failures
- **Telemetry**: Comprehensive monitoring of upstream requests and performance

#### Upstream Configuration
```elixir
# config/config.exs
config :hex_hub, :upstream,
  enabled: true,                    # Enable/disable upstream fetching
  url: "https://hex.pm",           # Upstream repository URL
  timeout: 30_000,                 # Request timeout (ms)
  retry_attempts: 3,               # Number of retry attempts
  retry_delay: 1_000               # Delay between retries (ms)
```

#### Environment Variables
- `UPSTREAM_ENABLED`: Enable/disable upstream fetching (default: true)
- `UPSTREAM_URL`: Upstream hex repository URL (default: https://hex.pm)
- `UPSTREAM_TIMEOUT`: Request timeout in milliseconds (default: 30000)
- `UPSTREAM_RETRY_ATTEMPTS`: Number of retry attempts (default: 3)
- `UPSTREAM_RETRY_DELAY`: Delay between retries in milliseconds (default: 1000)

#### How It Works
1. **Package Request**: When a package is requested, HexHub first checks local storage
2. **Upstream Fallback**: If not found locally and upstream is enabled, HexHub fetches from upstream
3. **Local Caching**: The fetched package is stored locally for future requests
4. **Telemetry**: All upstream requests are tracked with performance metrics

#### API Endpoints
- `GET /api/packages/:name` - Package metadata with upstream fallback
- `GET /api/packages/:name/releases/:version` - Release metadata with upstream fallback
- `GET /api/packages/:name/releases/:version/download` - Package tarball with upstream fallback
- `GET /api/packages/:name/releases/:version/docs/download` - Documentation with upstream fallback

#### Example Usage
```bash
# Fetch a package that doesn't exist locally
curl http://localhost:4000/api/packages/phoenix

# Download a package tarball (will fetch from upstream if needed)
curl http://localhost:4000/api/packages/phoenix/releases/1.7.0/download

# Download documentation (will fetch from upstream if needed)
curl http://localhost:4000/api/packages/phoenix/releases/1.7.0/docs/download
```
- When add a new page, wrap the page in <Layouts.app />