using Inventory.API.Data;
using Inventory.API.Models;
using Inventory.API.Repositories;
using MassTransit;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using OpenTelemetry.Metrics;
using Shared.Observability;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Add Observability (includes Serilog configuration)
builder.Services.AddObservability(builder.Configuration, "inventory-api", "1.0.0");

// Use Serilog for request logging
builder.Host.UseSerilog();

// Add DbContext (for migrations)
builder.Services.AddDbContext<InventoryDbContext>(options =>
{
    var connectionString = builder.Configuration.GetConnectionString("InventoryDb")
        ?? "Host=localhost;Database=inventory_db;Username=postgres;Password=postgres";
    options.UseNpgsql(connectionString);
    options.ConfigureWarnings(warnings =>
        warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning));
});

// Add Repositories
builder.Services.AddScoped<IProductRepository, ProductRepository>();

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

// Authentication disabled for development
// builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
//     .AddJwtBearer(options =>
//     {
//         var keycloakUrl = builder.Configuration["Keycloak:Authority"] ?? "http://localhost:8080/realms/microservices";
//         options.Authority = keycloakUrl;
//         options.RequireHttpsMetadata = false;
//         options.TokenValidationParameters = new Microsoft.IdentityModel.Tokens.TokenValidationParameters
//         {
//             ValidateAudience = false,
//             ValidateIssuer = true,
//             ValidIssuer = keycloakUrl
//         };
//     });

// builder.Services.AddAuthorization(options =>
// {
//     options.AddPolicy("InventoryRead", policy => policy.RequireClaim("scope", "inventory.read"));
//     options.AddPolicy("InventoryWrite", policy => policy.RequireClaim("scope", "inventory.write"));
// });

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add Health Checks
builder.Services.AddHealthChecks()
    .AddNpgSql(builder.Configuration.GetConnectionString("InventoryDb") 
        ?? "Host=localhost;Database=inventory_db;Username=postgres;Password=postgres");

var app = builder.Build();

// Add Serilog request logging middleware
app.UseSerilogRequestLogging(options =>
{
    options.EnrichDiagnosticContext = (diagnosticContext, httpContext) =>
    {
        diagnosticContext.Set("RequestHost", httpContext.Request.Host.Value);
        diagnosticContext.Set("RequestScheme", httpContext.Request.Scheme);
    };
});

Log.Information("Starting Inventory API...");

// Auto-migrate database and seed data
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<InventoryDbContext>();
    Log.Information("Running database migrations...");
    db.Database.Migrate();
    Log.Information("Database migrations completed");

    // Seed initial data
    await SeedInventoryData(db);
}

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
app.MapGet("/api/inventory/products", async (IProductRepository repo) =>
{
    var products = await repo.GetAllAsync();
    return Results.Ok(products);
})
// .RequireAuthorization("InventoryRead")
.WithName("GetAllProducts")
.WithOpenApi();

app.MapGet("/api/inventory/products/{id:guid}", async (Guid id, IProductRepository repo) =>
{
    var product = await repo.GetByIdAsync(id);
    return product is not null ? Results.Ok(product) : Results.NotFound();
})
// .RequireAuthorization("InventoryRead")
.WithName("GetProductById")
.WithOpenApi();

app.MapGet("/api/inventory/products/sku/{sku}", async (string sku, IProductRepository repo) =>
{
    var product = await repo.GetBySkuAsync(sku);
    return product is not null ? Results.Ok(product) : Results.NotFound();
})
// .RequireAuthorization("InventoryRead")
.WithName("GetProductBySku")
.WithOpenApi();

app.MapGet("/api/inventory/products/low-stock", async (IProductRepository repo) =>
{
    var products = await repo.GetLowStockProductsAsync();
    return Results.Ok(products);
})
// .RequireAuthorization("InventoryRead")
.WithName("GetLowStockProducts")
.WithOpenApi();

app.MapPost("/api/inventory/products", async (CreateProductRequest request, IProductRepository repo) =>
{
    var product = new Product
    {
        Sku = request.Sku,
        Name = request.Name,
        Description = request.Description,
        Quantity = request.Quantity,
        LowStockThreshold = request.LowStockThreshold,
        Price = request.Price
    };

    var created = await repo.CreateAsync(product);
    return Results.Created($"/api/inventory/products/{created.Id}", created);
})
// .RequireAuthorization("InventoryWrite")
.WithName("CreateProduct")
.WithOpenApi();

app.MapPut("/api/inventory/products/{id:guid}", async (Guid id, UpdateProductRequest request, IProductRepository repo) =>
{
    var existing = await repo.GetByIdAsync(id);
    if (existing is null) return Results.NotFound();

    existing.Sku = request.Sku;
    existing.Name = request.Name;
    existing.Description = request.Description;
    existing.LowStockThreshold = request.LowStockThreshold;
    existing.Price = request.Price;

    var updated = await repo.UpdateAsync(existing);
    return updated is not null ? Results.Ok(updated) : Results.NotFound();
})
// .RequireAuthorization("InventoryWrite")
.WithName("UpdateProduct")
.WithOpenApi();

app.MapPost("/api/inventory/products/{id:guid}/adjust", async (Guid id, AdjustQuantityRequest request, IProductRepository repo) =>
{
    var success = await repo.AdjustQuantityAsync(id, request.QuantityChange, request.Reason);
    return success ? Results.Ok() : Results.NotFound();
})
// .RequireAuthorization("InventoryWrite")
.WithName("AdjustQuantity")
.WithOpenApi();

app.MapDelete("/api/inventory/products/{id:guid}", async (Guid id, IProductRepository repo) =>
{
    var success = await repo.DeleteAsync(id);
    return success ? Results.NoContent() : Results.NotFound();
})
// .RequireAuthorization("InventoryWrite")
.WithName("DeleteProduct")
.WithOpenApi();

app.MapControllers();

Log.Information("Inventory API started successfully");

// Seed data function
async Task SeedInventoryData(InventoryDbContext db)
{
    try
    {
        // Check if data already exists
        if (await db.Products.AnyAsync())
        {
            Log.Information("Inventory data already exists, skipping seed");
            return;
        }

        Log.Information("Seeding inventory data...");

        var products = new List<Product>
        {
            new Product
            {
                Id = Guid.Parse("10000000-0000-0000-0000-000000000001"),
                Sku = "LAPTOP-001",
                Name = "Dell XPS 13",
                Description = "High-performance ultrabook with Intel Core i7, 16GB RAM, 512GB SSD",
                Quantity = 50,
                ReservedQuantity = 0,
                LowStockThreshold = 10,
                Price = 1299.99m,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            },
            new Product
            {
                Id = Guid.Parse("10000000-0000-0000-0000-000000000002"),
                Sku = "MOUSE-001",
                Name = "Logitech MX Master 3S",
                Description = "Advanced wireless mouse with precision scrolling and customizable buttons",
                Quantity = 150,
                ReservedQuantity = 0,
                LowStockThreshold = 20,
                Price = 99.99m,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            },
            new Product
            {
                Id = Guid.Parse("10000000-0000-0000-0000-000000000003"),
                Sku = "KEYBOARD-001",
                Name = "Mechanical Keyboard RGB",
                Description = "Mechanical keyboard with RGB backlighting, Cherry MX switches",
                Quantity = 75,
                ReservedQuantity = 0,
                LowStockThreshold = 15,
                Price = 149.99m,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            },
            new Product
            {
                Id = Guid.Parse("10000000-0000-0000-0000-000000000004"),
                Sku = "MONITOR-001",
                Name = "LG UltraWide 34\"",
                Description = "34-inch ultrawide monitor with 3440x1440 resolution, 144Hz refresh rate",
                Quantity = 25,
                ReservedQuantity = 0,
                LowStockThreshold = 5,
                Price = 799.99m,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            },
            new Product
            {
                Id = Guid.Parse("10000000-0000-0000-0000-000000000005"),
                Sku = "HEADPHONES-001",
                Name = "Sony WH-1000XM5",
                Description = "Premium noise-cancelling wireless headphones with 30-hour battery",
                Quantity = 40,
                ReservedQuantity = 0,
                LowStockThreshold = 8,
                Price = 399.99m,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            },
            new Product
            {
                Id = Guid.Parse("10000000-0000-0000-0000-000000000006"),
                Sku = "WEBCAM-001",
                Name = "Logitech C920 Pro",
                Description = "1080p HD webcam with auto-focus and stereo microphone",
                Quantity = 60,
                ReservedQuantity = 0,
                LowStockThreshold = 12,
                Price = 79.99m,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            },
            new Product
            {
                Id = Guid.Parse("10000000-0000-0000-0000-000000000007"),
                Sku = "DOCK-001",
                Name = "USB-C Docking Station",
                Description = "Universal USB-C dock with HDMI, USB 3.0, and power delivery",
                Quantity = 35,
                ReservedQuantity = 0,
                LowStockThreshold = 7,
                Price = 129.99m,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            },
            new Product
            {
                Id = Guid.Parse("10000000-0000-0000-0000-000000000008"),
                Sku = "CABLE-001",
                Name = "HDMI 2.1 Cable 6ft",
                Description = "High-speed HDMI 2.1 cable supporting 8K resolution",
                Quantity = 200,
                ReservedQuantity = 0,
                LowStockThreshold = 30,
                Price = 19.99m,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            }
        };

        await db.Products.AddRangeAsync(products);
        await db.SaveChangesAsync();

        Log.Information("Successfully seeded {ProductCount} products", products.Count);
    }
    catch (Exception ex)
    {
        Log.Error(ex, "Error seeding inventory data");
    }
}

try
{
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Inventory API terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}

public record CreateProductRequest(
    string Sku,
    string Name,
    string Description,
    int Quantity,
    int LowStockThreshold,
    decimal Price
);

public record UpdateProductRequest(
    string Sku,
    string Name,
    string Description,
    int LowStockThreshold,
    decimal Price
);

public record AdjustQuantityRequest(
    int QuantityChange,
    string Reason
);

