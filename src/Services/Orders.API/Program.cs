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

// Auto-migrate database and seed data
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<OrdersDbContext>();
    Log.Information("Running database migrations...");
    db.Database.Migrate();
    Log.Information("Database migrations completed");

    // Seed initial data
    await SeedOrdersData(db);
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

// Seed data function
async Task SeedOrdersData(OrdersDbContext db)
{
    try
    {
        // Check if data already exists
        if (await db.Orders.AnyAsync())
        {
            Log.Information("Orders data already exists, skipping seed");
            return;
        }

        Log.Information("Seeding orders data...");

        var customerId = Guid.Parse("00000000-0000-0000-0000-000000000001");

        var orders = new List<Order>
        {
            new Order
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000001"),
                OrderNumber = "ORD-2025-001",
                CustomerId = customerId,
                CreatedAt = DateTime.UtcNow.AddDays(-5),
                ConfirmedAt = DateTime.UtcNow.AddDays(-5),
                Status = OrderStatus.Confirmed,
                TotalAmount = 1399.98m,
                Items = new List<Orders.API.Models.OrderItem>
                {
                    new Orders.API.Models.OrderItem
                    {
                        Id = Guid.NewGuid(),
                        ProductId = Guid.Parse("10000000-0000-0000-0000-000000000001"),
                        ProductName = "Dell XPS 13",
                        Quantity = 1,
                        UnitPrice = 1299.99m
                    },
                    new Orders.API.Models.OrderItem
                    {
                        Id = Guid.NewGuid(),
                        ProductId = Guid.Parse("10000000-0000-0000-0000-000000000002"),
                        ProductName = "Logitech MX Master 3S",
                        Quantity = 1,
                        UnitPrice = 99.99m
                    }
                }
            },
            new Order
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000002"),
                OrderNumber = "ORD-2025-002",
                CustomerId = customerId,
                CreatedAt = DateTime.UtcNow.AddDays(-3),
                ConfirmedAt = DateTime.UtcNow.AddDays(-3),
                ShippedAt = DateTime.UtcNow.AddDays(-1),
                Status = OrderStatus.Shipped,
                TotalAmount = 949.98m,
                TrackingNumber = "TRACK-2025-001",
                Items = new List<Orders.API.Models.OrderItem>
                {
                    new Orders.API.Models.OrderItem
                    {
                        Id = Guid.NewGuid(),
                        ProductId = Guid.Parse("10000000-0000-0000-0000-000000000003"),
                        ProductName = "Mechanical Keyboard RGB",
                        Quantity = 1,
                        UnitPrice = 149.99m
                    },
                    new Orders.API.Models.OrderItem
                    {
                        Id = Guid.NewGuid(),
                        ProductId = Guid.Parse("10000000-0000-0000-0000-000000000005"),
                        ProductName = "Sony WH-1000XM5",
                        Quantity = 1,
                        UnitPrice = 399.99m
                    },
                    new Orders.API.Models.OrderItem
                    {
                        Id = Guid.NewGuid(),
                        ProductId = Guid.Parse("10000000-0000-0000-0000-000000000006"),
                        ProductName = "Logitech C920 Pro",
                        Quantity = 1,
                        UnitPrice = 79.99m
                    }
                }
            },
            new Order
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000003"),
                OrderNumber = "ORD-2025-003",
                CustomerId = customerId,
                CreatedAt = DateTime.UtcNow.AddDays(-1),
                Status = OrderStatus.Pending,
                TotalAmount = 799.99m,
                Items = new List<Orders.API.Models.OrderItem>
                {
                    new Orders.API.Models.OrderItem
                    {
                        Id = Guid.NewGuid(),
                        ProductId = Guid.Parse("10000000-0000-0000-0000-000000000004"),
                        ProductName = "LG UltraWide 34\"",
                        Quantity = 1,
                        UnitPrice = 799.99m
                    }
                }
            },
            new Order
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000004"),
                OrderNumber = "ORD-2025-004",
                CustomerId = customerId,
                CreatedAt = DateTime.UtcNow.AddHours(-12),
                Status = OrderStatus.Pending,
                TotalAmount = 129.99m,
                Items = new List<Orders.API.Models.OrderItem>
                {
                    new Orders.API.Models.OrderItem
                    {
                        Id = Guid.NewGuid(),
                        ProductId = Guid.Parse("10000000-0000-0000-0000-000000000007"),
                        ProductName = "USB-C Docking Station",
                        Quantity = 1,
                        UnitPrice = 129.99m
                    }
                }
            }
        };

        await db.Orders.AddRangeAsync(orders);
        await db.SaveChangesAsync();

        Log.Information("Successfully seeded {OrderCount} orders", orders.Count);
    }
    catch (Exception ex)
    {
        Log.Error(ex, "Error seeding orders data");
    }
}

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
