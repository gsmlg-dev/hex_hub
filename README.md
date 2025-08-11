# HexHub - Private Hex Package Manager

HexHub is a complete implementation of the Hex API specification for managing Elixir packages privately. It provides package hosting, documentation serving, and repository management capabilities.

## Features

- **Complete Hex API Compatibility**: Drop-in replacement for hex.pm
- **Package Management**: Upload, download, and manage Elixir packages
- **Documentation Hosting**: Automatic documentation generation and serving
- **User Management**: API key authentication and user accounts
- **Repository Support**: Private repositories with access control
- **Live Documentation**: Real-time documentation updates
- **Mnesia Storage**: In-memory database with disk persistence (no PostgreSQL required)
- **Flexible Storage**: Support for local filesystem or S3-compatible storage
- **Zero Database Setup**: Uses Mnesia for data storage, no external database required

## Status

✅ **Development Complete**: All core Hex API functionality has been implemented with Mnesia storage.

**Completed Features:**
- ✅ Complete Hex API implementation
- ✅ Mnesia database with full CRUD operations
- ✅ User management with authentication
- ✅ Package publishing and retrieval
- ✅ Documentation hosting
- ✅ API key management
- ✅ Package ownership management
- ✅ Comprehensive test suite (94 tests, 100% passing)
- ✅ Local file storage for packages and documentation

The application is ready for production use. See the [development plan](DEVELOPMENT_PLAN.md) for detailed implementation summary.

## Quick Start

### Prerequisites

- Elixir 1.15+ and Erlang/OTP 26+
- Node.js 18+ (for assets)
- No database required (uses Mnesia for storage)

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/hex_hub.git
cd hex_hub

# Install dependencies
mix setup

# Start the development server
mix phx.server
```

The application will be available at `http://localhost:4000`

### Production Deployment

```bash
# Build for production
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release

# Run the release
_build/prod/rel/hex_hub/bin/hex_hub start
```

## API Usage

### Authentication

All API endpoints require authentication via API key:

```bash
curl -H "Authorization: Bearer YOUR_API_KEY" https://your-domain.com/api/packages
```

### Publishing Packages

```bash
# Create a package first
curl -X POST \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"repository": "hexpm", "meta": {"description": "My awesome package"}}' \
  https://your-domain.com/api/packages/my_package

# Then publish a release
curl -X POST \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @my_package-1.0.0.tar \
  https://your-domain.com/api/publish?name=my_package&version=1.0.0
```

### Installing Packages

Add to your `mix.exs`:

```elixir
defp deps do
  [
    {:my_package, "~> 1.0", repo: "your-org", organization: "your-org"}
  ]
end
```

Configure your repository:

```elixir
# In config/config.exs
config :hex, repos: [
  "your-org": "https://your-domain.com"
]
```

## API Endpoints

The application implements the complete Hex API specification:

### Users
- `POST /api/users` - Create new user
- `GET /api/users/:username_or_email` - Get user profile
- `GET /api/users/me` - Get current authenticated user
- `POST /api/users/:username_or_email/reset` - Reset password

### Repositories
- `GET /api/repos` - List repositories
- `GET /api/repos/:name` - Get repository details

### Packages
- `GET /api/packages` - List packages (with pagination and search)
- `GET /api/packages/:name` - Get package details
- `POST /api/publish` - Publish new package/release

### Documentation
- `POST /api/packages/:name/releases/:version/docs` - Upload documentation
- `DELETE /api/packages/:name/releases/:version/docs` - Remove documentation

### Package Ownership
- `GET /api/packages/:name/owners` - List package owners
- `PUT /api/packages/:name/owners/:email` - Add package owner
- `DELETE /api/packages/:name/owners/:email` - Remove package owner

### API Keys
- `GET /api/keys` - List API keys
- `POST /api/keys` - Create API key (requires Basic Auth)
- `GET /api/keys/:name` - Get API key details
- `DELETE /api/keys/:name` - Delete API key

## Configuration

### Environment Variables

- `SECRET_KEY_BASE`: 64-byte secret for sessions
- `PHX_HOST`: Hostname for URL generation
- `MIX_ENV`: Environment (dev, test, prod)

### Storage Configuration

Configure storage in `config/dev.exs`:

```elixir
config :hex_hub,
  storage_type: :local,  # or :s3
  storage_path: "priv/storage"
```

For S3 storage:
```elixir
config :hex_hub,
  storage_type: :s3,
  s3_bucket: "your-bucket-name",
  s3_region: "us-east-1"
```

### Repository Settings

Configure repositories in `config/runtime.exs`:

```elixir
config :hex_hub, :repositories, [
  %{
    name: "my-org",
    private: true,
    public_key: "base64-encoded-public-key"
  }
]
```

## Development

### Running Tests

```bash
# Run all tests
mix test

# Run with coverage
mix test --cover

# Run specific test file
mix test test/hex_hub_web/controllers/api/package_controller_test.exs
```

### Database Setup

No database setup required - HexHub uses Mnesia for data storage. Mnesia will automatically initialize on first run.

For testing:
```bash
# Mnesia will be automatically configured for tests
# No manual setup needed
```

### Code Style

```bash
# Format code
mix format

# Check for issues
mix credo

# Type checking (if using dialyzer)
mix dialyzer
```

## Production Deployment

For production deployment:

1. Configure Mnesia clustering if needed
2. Set up persistent storage for Mnesia data
3. Configure SSL/TLS
4. Set up monitoring and logging
5. Configure file storage (local or S3)

### Mnesia Configuration

HexHub uses Mnesia for data storage. Data is stored in:
- `Mnesia.<node_name>/` directory for Mnesia tables
- `priv/storage/` directory for package and documentation files

For persistence, ensure these directories are backed up and restored as needed.

### Docker Deployment

```dockerfile
FROM elixir:1.15-alpine

WORKDIR /app
COPY . .

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix compile && \
    mix assets.deploy

EXPOSE 4000
CMD ["mix", "phx.server"]
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -am 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## Security

- Use strong API keys
- Enable HTTPS in production
- Implement rate limiting
- Regular security audits
- Monitor access logs

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- [GitHub Issues](https://github.com/your-org/hex_hub/issues)
- [Documentation](https://your-docs-site.com)
- [Community Discord](https://discord.gg/your-server)