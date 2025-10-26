using Audit.API.Consumers;
using Audit.API.Models;
using Marten;
using MassTransit;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using OpenTelemetry.Metrics;
using Shared.Observability;
using Weasel.Core;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Add Observability (OpenTelemetry + Serilog + Loki)
builder.Services.AddObservability(builder.Configuration, "audit-api", "1.0.0");

// Use Serilog for request logging
builder.Host.UseSerilog();

// Configure Marten (Document & Event Store)
builder.Services.AddMarten(options =>
{
    var connectionString = builder.Configuration.GetConnectionString("AuditDb") 
        ?? "Host=localhost;Database=audit_db;Username=postgres;Password=postgres";
    
    options.Connection(connectionString);
    options.AutoCreateSchemaObjects = AutoCreate.All;
    options.Events.DatabaseSchemaName = "events";
    options.DatabaseSchemaName = "documents";
    
    // Register document types
    options.Schema.For<AuditDocument>().Index(x => x.Entity);
    options.Schema.For<AuditDocument>().Index(x => x.Action);
    options.Schema.For<AuditDocument>().Index(x => x.Timestamp);
})
.UseLightweightSessions()
.AddAsyncDaemon(Weasel.Core.AutoCreate.All);

// Configure MassTransit with RabbitMQ
builder.Services.AddMassTransit(x =>
{
    x.AddConsumer<OrderCreatedConsumer>();
    x.AddConsumer<OrderConfirmedConsumer>();
    x.AddConsumer<OrderCancelledConsumer>();
    x.AddConsumer<InventoryAdjustedConsumer>();
    x.AddConsumer<InventoryReservedConsumer>();
    x.AddConsumer<NotificationSentConsumer>();

    x.UsingRabbitMq((context, cfg) =>
    {
        var rabbitHost = builder.Configuration["RabbitMQ:Host"] ?? "localhost";
        var rabbitUser = builder.Configuration["RabbitMQ:User"] ?? "guest";
        var rabbitPassword = builder.Configuration["RabbitMQ:Password"] ?? "guest";

        cfg.Host(rabbitHost, h =>
        {
            h.Username(rabbitUser);
            h.Password(rabbitPassword);
        });

        cfg.ConfigureEndpoints(context);
    });
});

// Add Authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        var keycloakUrl = builder.Configuration["Keycloak:Authority"] ?? "http://localhost:8080/realms/microservices";
        options.Authority = keycloakUrl;
        options.Audience = "audit-api";
        options.RequireHttpsMetadata = false;
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AuditRead", policy => policy.RequireClaim("scope", "audit.read"));
    options.AddPolicy("AuditWrite", policy => policy.RequireClaim("scope", "audit.write"));
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add Health Checks
builder.Services.AddHealthChecks()
    .AddNpgSql(builder.Configuration.GetConnectionString("AuditDb") ?? "Host=localhost;Database=audit_db;Username=postgres;Password=postgres");

var app = builder.Build();

// Add Serilog request logging middleware
app.UseSerilogRequestLogging(options =>
{
    options.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
    {
        diagnosticContext.Set("RequestHost", httpContext.Request.Host.Value);
    };
});

Log.Information("Starting Audit API...");

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthentication();
app.UseAuthorization();

// Prometheus metrics endpoint
app.MapPrometheusScrapingEndpoint();

// Health check endpoints
app.MapHealthChecks("/health");
app.MapHealthChecks("/health/ready");
app.MapHealthChecks("/health/live");

// API Endpoints
app.MapGet("/api/audit/events", async (IDocumentSession session) =>
{
    var events = await session.Events.QueryAllRawEvents().ToListAsync();
    return Results.Ok(events);
})
.RequireAuthorization("AuditRead")
.WithName("GetAllEvents")
.WithOpenApi();

app.MapGet("/api/audit/events/{streamId}", async (string streamId, IDocumentSession session) =>
{
    var events = await session.Events.FetchStreamAsync(streamId);
    return events.Any() ? Results.Ok(events) : Results.NotFound();
})
.RequireAuthorization("AuditRead")
.WithName("GetEventsByStream")
.WithOpenApi();

app.MapGet("/api/audit/documents", async (IDocumentSession session) =>
{
    var documents = await session.Query<AuditDocument>().ToListAsync();
    return Results.Ok(documents);
})
.RequireAuthorization("AuditRead")
.WithName("GetAllDocuments")
.WithOpenApi();

app.MapGet("/api/audit/documents/{entity}", async (string entity, IDocumentSession session) =>
{
    var documents = await session.Query<AuditDocument>()
        .Where(d => d.Entity == entity)
        .OrderByDescending(d => d.Timestamp)
        .ToListAsync();
    return Results.Ok(documents);
})
.RequireAuthorization("AuditRead")
.WithName("GetDocumentsByEntity")
.WithOpenApi();

app.MapPost("/api/audit/replay/{streamId}", async (string streamId, IDocumentSession session) =>
{
    var events = await session.Events.FetchStreamAsync(streamId);
    if (!events.Any())
        return Results.NotFound();

    // Replay logic would go here
    return Results.Ok(new { StreamId = streamId, EventCount = events.Count, Message = "Replay initiated" });
})
.RequireAuthorization("AuditWrite")
.WithName("ReplayEvents")
.WithOpenApi();

app.MapControllers();

Log.Information("Audit API started successfully");

try
{
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Audit API terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}

