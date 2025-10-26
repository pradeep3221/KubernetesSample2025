# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2025-01-26

### Added - Core Microservices

#### Shared Libraries
- **Shared.Contracts** - Event contracts library
  - OrderEvents (OrderCreated, OrderConfirmed, OrderCancelled, OrderShipped)
  - InventoryEvents (InventoryAdjusted, InventoryReserved, InventoryReleased, LowStockAlert)
  - NotificationEvents (NotificationRequested, NotificationSent)
  
- **Shared.Observability** - OpenTelemetry configuration library
  - Automatic instrumentation for ASP.NET Core, HttpClient, EF Core, SQL Client
  - Serilog integration with Loki sink
  - Trace, metrics, and logs export to OTLP
  - Prometheus metrics endpoint

#### Orders API
- Order management endpoints (Create, Get, Confirm, Cancel, Ship)
- SQL Server database with Entity Framework Core
- Event publishing to RabbitMQ
- Full OpenTelemetry instrumentation
- Health checks for database connectivity
- Swagger/OpenAPI documentation
- Keycloak JWT authentication
- Docker support

#### Inventory API
- Product and inventory management endpoints
- PostgreSQL database with Dapper for queries
- Stock adjustment and reservation logic
- Low stock alert system
- Event publishing to RabbitMQ
- Full OpenTelemetry instrumentation
- Health checks for database connectivity
- Swagger/OpenAPI documentation
- Keycloak JWT authentication
- Docker support

#### Notifications API
- Notification management endpoints
- Redis for notification storage
- Support for multiple notification types (Email, SMS, Push, InApp)
- Event consumption from RabbitMQ
- User notification history
- Full OpenTelemetry instrumentation
- Health checks for Redis connectivity
- Swagger/OpenAPI documentation
- Keycloak JWT authentication
- Docker support

#### Audit API
- Event sourcing with Marten
- Document store for audit trails
- Event stream querying
- Event replay capability
- Consumes all domain events from RabbitMQ
- Full OpenTelemetry instrumentation
- Health checks for database connectivity
- Swagger/OpenAPI documentation
- Keycloak JWT authentication
- Docker support

### Added - Observability Stack

#### OpenTelemetry Collector
- OTLP receiver (gRPC and HTTP)
- Batch processing for efficiency
- Memory limiter to prevent OOM
- Exports to Tempo (traces), Prometheus (metrics), and Loki (logs)
- Configuration file with best practices

#### Prometheus
- Metrics collection from all microservices
- Service discovery configuration
- Scrape configs for all services
- Exemplar storage for trace correlation
- 15-second scrape interval
- Configuration file

#### Loki
- Log aggregation from all services
- 7-day retention policy
- Compaction and retention management
- Label-based indexing
- Configuration file

#### Tempo
- Distributed tracing backend
- OTLP receiver for traces
- Metrics generator for service graphs
- Span metrics generation
- Configuration file

#### Grafana
- Pre-configured datasources (Prometheus, Loki, Tempo)
- Trace-to-logs correlation
- Trace-to-metrics correlation
- Service dependency graphs
- TraceQL editor enabled
- Configuration files for datasources and dashboards

### Added - Infrastructure

#### Docker Compose
- Complete local development environment
- 14 services orchestrated
- SQL Server for Orders database
- PostgreSQL for Inventory and Audit databases
- Redis for Notifications
- RabbitMQ with management UI
- Keycloak for authentication
- Full observability stack (OTel, Prometheus, Loki, Tempo, Grafana)
- Health checks for all services
- Proper networking and volume management
- Environment variable configuration

#### Database Setup
- PostgreSQL multi-database initialization script
- Automatic database creation for inventory_db and audit_db
- SQL Server automatic migration on startup
- Connection string configuration via environment variables

### Added - Documentation

- **README.md** - Comprehensive project documentation
  - Architecture overview
  - Quick start guide
  - API endpoints documentation
  - Observability features
  - Monitoring best practices
  - Development guidelines
  
- **QUICKSTART.md** - Step-by-step getting started guide
  - Prerequisites
  - Installation steps
  - Testing instructions
  - Troubleshooting tips
  - Common commands
  
- **ARCHITECTURE.md** - Detailed architecture documentation
  - System architecture diagrams
  - Component details
  - Data flow diagrams
  - Database schemas
  - Event contracts
  - Security architecture
  - Scalability considerations
  - Resilience patterns
  
- **PROJECT_SUMMARY.md** - Project overview and status
  - Completed components
  - Key features
  - Current statistics
  - Learning outcomes
  - Next steps
  
- **CHANGELOG.md** - This file
  - Version history
  - Feature tracking

### Added - Development Tools

- **.gitignore** - Comprehensive .NET gitignore
- **kubernetes Samples.sln** - Visual Studio solution file
- **Dockerfiles** - Multi-stage builds for all services
- **appsettings.json** - Configuration files for all services

### Technical Stack

- **.NET 9** - Latest .NET framework
- **ASP.NET Core** - Web API framework
- **Entity Framework Core 9** - ORM for SQL Server
- **Dapper 2.1** - Micro-ORM for PostgreSQL
- **Marten 7.31** - Event Store and Document DB
- **MassTransit 8.2** - Distributed application framework
- **RabbitMQ 3** - Message broker
- **Redis 7** - In-memory data store
- **Keycloak 23** - Identity and Access Management
- **OpenTelemetry 1.9** - Observability framework
- **Prometheus 2.48** - Metrics and monitoring
- **Grafana 10.2** - Visualization platform
- **Loki 2.9** - Log aggregation
- **Tempo 2.3** - Distributed tracing backend
- **Docker** - Containerization
- **Docker Compose** - Multi-container orchestration

### Features

#### Event-Driven Architecture
- Asynchronous communication via RabbitMQ
- Event sourcing with complete audit trail
- Eventual consistency across services
- Automatic retry and error handling

#### Observability
- **Distributed Tracing** - End-to-end request tracking
- **Metrics Collection** - Application, runtime, and business metrics
- **Structured Logging** - Centralized logs with trace correlation
- **Service Health** - Comprehensive health checks
- **Correlation** - Traces linked to logs and metrics

#### Security
- OAuth2/OpenID Connect with Keycloak
- JWT Bearer token authentication
- Scope-based authorization
- Policy-based access control

#### Polyglot Persistence
- SQL Server for transactional data (Orders)
- PostgreSQL for relational data (Inventory, Audit)
- Redis for caching and fast access (Notifications)
- Marten for event sourcing (Audit)

#### Developer Experience
- One-command startup with Docker Compose
- Swagger/OpenAPI for all APIs
- Comprehensive documentation
- Easy local development setup
- Hot reload support

## [Unreleased]

### Planned Features

#### Short-term
- Inventory Worker service
- Notifications Console application
- Ocelot API Gateway
- Integration tests
- Unit tests

#### Medium-term
- Helm charts for Kubernetes deployment
- Angular Customer SPA
- Angular Admin PWA
- CQRS implementation
- Redis caching layer

#### Long-term
- CI/CD pipeline
- Production deployment guides
- Performance testing
- Advanced monitoring dashboards
- Service mesh integration
- Automated alerting

## Version History

### [1.0.0] - 2025-01-26
- Initial release
- 4 microservices with full observability
- Complete local development environment
- Comprehensive documentation

---

## Notes

This project follows [Semantic Versioning](https://semver.org/).

### Version Format
- **MAJOR** version for incompatible API changes
- **MINOR** version for new functionality in a backward compatible manner
- **PATCH** version for backward compatible bug fixes

### Categories
- **Added** - New features
- **Changed** - Changes in existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Security improvements

