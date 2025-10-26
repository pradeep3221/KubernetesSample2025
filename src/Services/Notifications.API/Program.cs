using MassTransit;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Notifications.API.Consumers;
using Notifications.API.Services;
using OpenTelemetry.Metrics;
using Shared.Observability;
using StackExchange.Redis;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Add Observability (includes Serilog configuration)
builder.Services.AddObservability(builder.Configuration, "notifications-api", "1.0.0");

// Use Serilog for request logging
builder.Host.UseSerilog();

// Add Redis
builder.Services.AddSingleton<IConnectionMultiplexer>(sp =>
{
    var configuration = builder.Configuration["Redis:ConnectionString"] ?? "localhost:6379";
    return ConnectionMultiplexer.Connect(configuration);
});

// Add Services
builder.Services.AddScoped<INotificationService, NotificationService>();

// Configure MassTransit
builder.Services.AddMassTransit(x =>
{
    x.AddConsumer<NotificationRequestedConsumer>();
    x.AddConsumer<LowStockAlertConsumer>();

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

// Authentication disabled for development
// builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
//     .AddJwtBearer(options =>
//     {
//         var keycloakUrl = builder.Configuration["Keycloak:Authority"] ?? "http://localhost:8080/realms/microservices";
//         options.Authority = keycloakUrl;
//         options.Audience = "notifications-api";
//         options.RequireHttpsMetadata = false;
//     });

// builder.Services.AddAuthorization(options =>
// {
//     options.AddPolicy("NotificationsRead", policy => policy.RequireClaim("scope", "notifications.read"));
//     options.AddPolicy("NotificationsWrite", policy => policy.RequireClaim("scope", "notifications.write"));
// });

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add Health Checks
builder.Services.AddHealthChecks()
    .AddRedis(builder.Configuration["Redis:ConnectionString"] ?? "localhost:6379");

var app = builder.Build();

// Add Serilog request logging middleware
app.UseSerilogRequestLogging(options =>
{
    options.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
    {
        diagnosticContext.Set("RequestHost", httpContext.Request.Host.Value);
    };
});

Log.Information("Starting Notifications API...");

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Authentication disabled for development
// app.UseAuthentication();
// app.UseAuthorization();

// Prometheus metrics
app.MapPrometheusScrapingEndpoint();

// Health checks
app.MapHealthChecks("/health");
app.MapHealthChecks("/health/ready");
app.MapHealthChecks("/health/live");

// API Endpoints
app.MapGet("/api/notifications/user/{userId:guid}", async (Guid userId, INotificationService service) =>
{
    var notifications = await service.GetUserNotificationsAsync(userId);
    return Results.Ok(notifications);
})
// .RequireAuthorization("NotificationsRead")
.WithName("GetUserNotifications")
.WithOpenApi();

app.MapGet("/api/notifications/{id:guid}", async (Guid id, INotificationService service) =>
{
    var notification = await service.GetNotificationAsync(id);
    return notification is not null ? Results.Ok(notification) : Results.NotFound();
})
// .RequireAuthorization("NotificationsRead")
.WithName("GetNotification")
.WithOpenApi();

app.MapPost("/api/notifications", async (SendNotificationRequest request, INotificationService service) =>
{
    var notification = await service.SendNotificationAsync(
        request.UserId,
        request.Type,
        request.Title,
        request.Message,
        request.Metadata);
    return Results.Created($"/api/notifications/{notification.Id}", notification);
})
// .RequireAuthorization("NotificationsWrite")
.WithName("SendNotification")
.WithOpenApi();

app.MapPost("/api/notifications/{id:guid}/mark-read", async (Guid id, INotificationService service) =>
{
    var success = await service.MarkAsReadAsync(id);
    return success ? Results.Ok() : Results.NotFound();
})
// .RequireAuthorization("NotificationsWrite")
.WithName("MarkNotificationAsRead")
.WithOpenApi();

app.MapControllers();

Log.Information("Notifications API started successfully");

try
{
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Notifications API terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}

public record SendNotificationRequest(
    Guid UserId,
    string Type,
    string Title,
    string Message,
    Dictionary<string, string>? Metadata
);

