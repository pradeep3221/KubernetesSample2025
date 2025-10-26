using MassTransit;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using OpenTelemetry.Metrics;
using Orders.API.Data;
using Orders.API.Models;
using Orders.API.Services;
using Shared.Contracts.Events;
using Shared.Observability;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Add Observability (includes Serilog configuration)
builder.Services.AddObservability(builder.Configuration, "orders-api", "1.0.0");

// Use Serilog for request logging
builder.Host.UseSerilog();

// Add DbContext
builder.Services.AddDbContext<OrdersDbContext>(options =>
{
    var connectionString = builder.Configuration.GetConnectionString("OrdersDb")
        ?? "Server=localhost;Database=orders_db;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True;";
    options.UseSqlServer(connectionString);
    options.ConfigureWarnings(warnings =>
        warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning));
});

// Add Services
builder.Services.AddScoped<IOrderService, OrderService>();

// Configure MassTransit
builder.Services.AddMassTransit(x =>
{
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
        options.Audience = "orders-api";
        options.RequireHttpsMetadata = false;
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("OrdersRead", policy => policy.RequireClaim("scope", "orders.read"));
    options.AddPolicy("OrdersWrite", policy => policy.RequireClaim("scope", "orders.write"));
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add Health Checks
builder.Services.AddHealthChecks()
    .AddSqlServer(builder.Configuration.GetConnectionString("OrdersDb") 
        ?? "Server=localhost;Database=orders_db;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True;");

var app = builder.Build();

// Add Serilog request logging middleware
app.UseSerilogRequestLogging(options =>
{
    options.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
    {
        diagnosticContext.Set("RequestHost", httpContext.Request.Host.Value);
        diagnosticContext.Set("RequestScheme", httpContext.Request.Scheme);
        diagnosticContext.Set("UserAgent", httpContext.Request.Headers["User-Agent"].ToString());
    };
});

Log.Information("Starting Orders API...");

// Auto-migrate database
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<OrdersDbContext>();
    Log.Information("Running database migrations...");
    db.Database.Migrate();
    Log.Information("Database migrations completed");
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthentication();
app.UseAuthorization();

// Prometheus metrics
app.MapPrometheusScrapingEndpoint();

// Health checks
app.MapHealthChecks("/health");
app.MapHealthChecks("/health/ready");
app.MapHealthChecks("/health/live");

// API Endpoints
app.MapGet("/api/orders", async (OrdersDbContext db) =>
{
    var orders = await db.Orders.Include(o => o.Items).ToListAsync();
    return Results.Ok(orders);
})
.RequireAuthorization("OrdersRead")
.WithName("GetAllOrders")
.WithOpenApi();

app.MapGet("/api/orders/{id:guid}", async (Guid id, OrdersDbContext db) =>
{
    var order = await db.Orders.Include(o => o.Items).FirstOrDefaultAsync(o => o.Id == id);
    return order is not null ? Results.Ok(order) : Results.NotFound();
})
.RequireAuthorization("OrdersRead")
.WithName("GetOrderById")
.WithOpenApi();

app.MapPost("/api/orders", async (CreateOrderRequest request, IOrderService orderService) =>
{
    var order = await orderService.CreateOrderAsync(request);
    return Results.Created($"/api/orders/{order.Id}", order);
})
.RequireAuthorization("OrdersWrite")
.WithName("CreateOrder")
.WithOpenApi();

app.MapPost("/api/orders/{id:guid}/confirm", async (Guid id, IOrderService orderService) =>
{
    var order = await orderService.ConfirmOrderAsync(id);
    return order is not null ? Results.Ok(order) : Results.NotFound();
})
.RequireAuthorization("OrdersWrite")
.WithName("ConfirmOrder")
.WithOpenApi();

app.MapPost("/api/orders/{id:guid}/cancel", async (Guid id, string reason, IOrderService orderService) =>
{
    var order = await orderService.CancelOrderAsync(id, reason);
    return order is not null ? Results.Ok(order) : Results.NotFound();
})
.RequireAuthorization("OrdersWrite")
.WithName("CancelOrder")
.WithOpenApi();

app.MapPost("/api/orders/{id:guid}/ship", async (Guid id, string trackingNumber, IOrderService orderService) =>
{
    var order = await orderService.ShipOrderAsync(id, trackingNumber);
    return order is not null ? Results.Ok(order) : Results.NotFound();
})
.RequireAuthorization("OrdersWrite")
.WithName("ShipOrder")
.WithOpenApi();

app.MapControllers();

Log.Information("Orders API started successfully on {Urls}", app.Urls);

try
{
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Orders API terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}
