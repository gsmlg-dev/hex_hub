# HexHub

Private hex package manager and hexdocs server implementing the complete Hex API specification.

## Features

- **Complete Hex API Implementation**: All endpoints defined in hex-api.yaml
- **Mnesia Storage**: In-memory database with disk persistence
- **Flexible Storage**: Support for local filesystem or S3-compatible storage
- **Package Management**: Upload, download, and manage hex packages
- **Documentation Hosting**: Automatic documentation serving
- **API Authentication**: API keys and Basic Auth support

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

## Development

1. Install dependencies:
   ```bash
   mix deps.get
   ```

2. Start the development server:
   ```bash
   mix phx.server
   ```

3. The API will be available at `http://localhost:4000/api`

## Testing

Run tests:
```bash
mix test
```

## Production

For production deployment:

1. Configure Mnesia clustering if needed
2. Set up persistent storage
3. Configure SSL/TLS
4. Set up monitoring and logging

