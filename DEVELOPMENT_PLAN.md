# HexHub Development Plan - Mnesia Edition

## Phase 1: Foundation & Mnesia Setup (Week 1)

### Mnesia Database Design & Setup
1. **Schema Design for Mnesia**:
   - Users table: `{username, email, password_hash, inserted_at, updated_at}`
   - Repositories table: `{name, public, active, billing_active, inserted_at, updated_at}`
   - Packages table: `{name, repository_name, meta, downloads, inserted_at, updated_at}`
   - PackageReleases table: `{package_name, version, has_docs, meta, retired, downloads, inserted_at, updated_at}`
   - PackageOwners table: `{package_name, username, level, inserted_at}`
   - ApiKeys table: `{key_name, user_username, secret_hash, permissions, revoked_at, inserted_at, updated_at}`
   - PackageDownloads table: `{package_name, version, day_count, week_count, all_count}`

2. **Mnesia Configuration**:
   - Set up Mnesia schema and tables with proper indices
   - Configure RAM/disk storage based on access patterns
   - Implement transaction handling and consistency strategies
   - Create backup and recovery procedures

3. **Data Access Layer**:
   - Create Mnesia repository modules for each entity
   - Implement CRUD operations with proper transactions
   - Add query patterns for efficient data retrieval
   - Set up data validation and constraints

### Authentication System (Mnesia-based)
1. User registration with email confirmation
2. Password reset functionality with Mnesia persistence
3. API key authentication using Mnesia storage
4. Session management with Mnesia-backed sessions
5. Basic Auth implementation for API key creation

## Phase 2: Core API Implementation (Week 2-3)

### User Management API with Mnesia
1. `POST /users` - Create user with email confirmation
2. `GET /users/{username_or_email}` - Fetch user profile
3. `GET /users/me` - Fetch authenticated user
4. `POST /users/{username_or_email}/reset` - Password reset

### Repository Management
1. `GET /repos` - List repositories using Mnesia queries
2. `GET /repos/{name}` - Fetch repository details from Mnesia

### Package Management
1. `GET /packages` - List packages with Mnesia-based pagination
2. `GET /packages/{name}` - Fetch package details
3. Package search using Mnesia pattern matching and indexing

### Release Management
1. `GET /packages/{name}/releases/{version}` - Fetch release
2. `POST /publish` - Publish new package/release with Mnesia storage
3. `POST /packages/{name}/releases/{version}/retire` - Retire release
4. `DELETE /packages/{name}/releases/{version}/retire` - Unretire release

### Documentation Management
1. `POST /packages/{name}/releases/{version}/docs` - Upload documentation
2. `DELETE /packages/{name}/releases/{version}/docs` - Remove documentation
3. Static file serving with Mnesia metadata tracking

### Package Ownership
1. `GET /packages/{name}/owners` - List package owners
2. `PUT /packages/{name}/owners/{email}` - Add owner
3. `DELETE /packages/{name}/owners/{email}` - Remove owner

### API Key Management
1. `GET /keys` - List API keys from Mnesia
2. `POST /keys` - Create API key (Basic Auth required)
3. `GET /keys/{name}` - Fetch API key details
4. `DELETE /keys/{name}` - Revoke API key

## Phase 3: Web Interface (Week 4)

### Frontend Setup (Unchanged)
1. Set up Tailwind CSS with DaisyUI components
2. Create responsive layouts and components
3. Implement Phoenix LiveView for real-time features

### Mnesia Integration in Web Layer
1. LiveView integration with Mnesia queries
2. Real-time updates using Mnesia notifications
3. Efficient data fetching patterns for web interface
4. Cache warming strategies

### User Interface Pages
1. Homepage with Mnesia-powered package search
2. User registration/login pages
3. User dashboard with Mnesia-backed data
4. Package detail pages with documentation links
5. Repository management interface

## Phase 4: Advanced Features (Week 5)

### Package Analytics with Mnesia
1. Download statistics aggregation using Mnesia counters
2. Popular packages ranking with efficient queries
3. Real-time analytics dashboard

### Advanced Search
1. Full-text search using Mnesia pattern matching
2. Secondary indices for complex queries
3. Search suggestions with Mnesia-based autocomplete
4. Filter by repository, license, etc.

### Security Features
1. Rate limiting with Mnesia-based tracking
2. Package vulnerability scanning
3. Security advisories system
4. Package integrity verification

### Documentation Hosting
1. Documentation metadata tracking in Mnesia
2. Efficient file serving with Mnesia coordination
3. Version switching for documentation
4. Access control for private documentation

## Phase 5: Production & Deployment (Week 6)

### Mnesia-Specific Optimization
1. **Clustering Setup**:
   - Configure Mnesia clustering for high availability
   - Set up node discovery and failover
   - Implement data replication strategies
   
2. **Performance Tuning**:
   - Optimize Mnesia table types (set, bag, ordered_set)
   - Configure RAM/disk storage ratios
   - Implement efficient indexing strategies
   - Set up load balancing across nodes

3. **Backup & Recovery**:
   - Automated Mnesia backup procedures
   - Point-in-time recovery capabilities
   - Cross-node backup synchronization
   - Disaster recovery procedures

### Deployment Setup (Mnesia-focused)
1. **Containerization**:
   - Docker configuration with Mnesia persistence volumes
   - Kubernetes deployment with StatefulSets
   - Persistent volume claims for Mnesia data
   
2. **Monitoring**:
   - Mnesia-specific metrics (table sizes, transaction rates)
   - Node health monitoring
   - Data consistency checks
   - Performance monitoring

## Phase 6: Advanced Repository Features (Week 7)

### Organization Support with Mnesia
1. Team/organization accounts as Mnesia records
2. Role-based access control using Mnesia queries
3. Organization package management
4. Multi-tenant data isolation

### Advanced Repository Features
1. Private repository hosting with Mnesia access control
2. Repository replication and mirroring
3. Package promotion workflows
4. Integration with CI/CD systems using Mnesia webhooks

## Mnesia-Specific Considerations

### Table Design Strategy
```erlang
% Example table definitions:
:create_table(users, [
  {attributes, [:username, :email, :password_hash, :inserted_at, :updated_at]},
  {disc_copies, [node()]},
  {type, set},
  {index, [:email]}
])

:create_table(packages, [
  {attributes, [:name, :repository_name, :meta, :downloads, :inserted_at, :updated_at]},
  {disc_copies, [node()]},
  {type, set},
  {index, [:repository_name]}
])
```

### Data Partitioning Strategy
1. **Hot data**: RAM-only tables for frequent queries
2. **Warm data**: RAM + disk copies for balance
3. **Cold data**: Disk-only tables for archival

### Query Optimization
1. **Primary keys**: Use package names as keys for direct access
2. **Secondary indices**: Email, repository name, version
3. **Pattern matching**: Leverage Erlang pattern matching for queries
4. **Aggregation**: Use Mnesia counters for download statistics

### Transaction Handling
1. **Atomic operations**: Use Mnesia transactions for consistency
2. **Conflict resolution**: Implement application-level conflict resolution
3. **Deadlock prevention**: Use proper transaction ordering
4. **Performance**: Batch operations where possible

## Testing Strategy with Mnesia

### Test Setup
1. **In-memory testing**: Use RAM-only Mnesia tables for tests
2. **Isolation**: Each test runs in isolated Mnesia schema
3. **Fixtures**: Pre-populate test data efficiently
4. **Performance**: Test with realistic data volumes

### Test Coverage
1. **Unit tests**: Mnesia operations and business logic
2. **Integration tests**: API endpoints with Mnesia backend
3. **Concurrency tests**: Multiple concurrent operations
4. **Failover tests**: Node failure and recovery scenarios

### Security Testing
1. **Data integrity**: Verify Mnesia consistency under load
2. **Access control**: Test Mnesia-based authorization
3. **Backup/restore**: Verify data recovery procedures
4. **Cluster security**: Node authentication and encryption

## Technology Stack Changes

**Backend**: Elixir/Phoenix 1.8, Mnesia (replacing Ecto/PostgreSQL)
**Frontend**: Phoenix LiveView, Tailwind CSS, DaisyUI (unchanged)
**Authentication**: API Keys, Basic Auth, Session-based (adapted for Mnesia)
**Storage**: Mnesia for all data, File storage for packages/docs
**Clustering**: Erlang distribution for Mnesia clustering
**Monitoring**: LiveDashboard, Telemetry, Mnesia-specific metrics
**Deployment**: Docker with persistent volumes, Kubernetes StatefulSets

## Migration Strategy from Ecto

Since this is a greenfield project, no actual migration needed, but:
1. Remove Ecto/PostgreSQL dependencies from mix.exs
2. Add :mnesia to extra_applications
3. Update configuration to use Mnesia
4. Create Mnesia initialization on application start

## Success Metrics (Mnesia-specific)

1. **Performance**: <50ms Mnesia queries, linear scaling with cluster size
2. **Availability**: 99.9% uptime with automatic failover
3. **Consistency**: Zero data loss during node failures
4. **Scalability**: Handle 10,000+ concurrent users across cluster
5. **Recovery**: <30 second failover time, <5 minute full recovery

This plan leverages Mnesia's strengths (in-memory performance, clustering, distribution) while addressing its challenges (CAP theorem tradeoffs, operational complexity) to build a highly scalable, distributed hex package manager.