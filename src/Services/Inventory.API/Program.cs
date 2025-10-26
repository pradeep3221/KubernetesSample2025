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

// Add Authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        var keycloakUrl = builder.Configuration["Keycloak:Authority"] ?? "http://localhost:8080/realms/microservices";
        options.Authority = keycloakUrl;
        options.Audience = "inventory-api";
        options.RequireHttpsMetadata = false;
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("InventoryRead", policy => policy.RequireClaim("scope", "inventory.read"));
    options.AddPolicy("InventoryWrite", policy => policy.RequireClaim("scope", "inventory.write"));
});

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

// Auto-migrate database
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<InventoryDbContext>();
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
app.MapGet("/api/inventory/products", async (IProductRepository repo) =>
{
    var products = await repo.GetAllAsync();
    return Results.Ok(products);
})
.RequireAuthorization("InventoryRead")
.WithName("GetAllProducts")
.WithOpenApi();

app.MapGet("/api/inventory/products/{id:guid}", async (Guid id, IProductRepository repo) =>
{
    var product = await repo.GetByIdAsync(id);
    return product is not null ? Results.Ok(product) : Results.NotFound();
})
.RequireAuthorization("InventoryRead")
.WithName("GetProductById")
.WithOpenApi();

app.MapGet("/api/inventory/products/sku/{sku}", async (string sku, IProductRepository repo) =>
{
    var product = await repo.GetBySkuAsync(sku);
    return product is not null ? Results.Ok(product) : Results.NotFound();
})
.RequireAuthorization("InventoryRead")
.WithName("GetProductBySku")
.WithOpenApi();

app.MapGet("/api/inventory/products/low-stock", async (IProductRepository repo) =>
{
    var products = await repo.GetLowStockProductsAsync();
    return Results.Ok(products);
})
.RequireAuthorization("InventoryRead")
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
.RequireAuthorization("InventoryWrite")
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
.RequireAuthorization("InventoryWrite")
.WithName("UpdateProduct")
.WithOpenApi();

app.MapPost("/api/inventory/products/{id:guid}/adjust", async (Guid id, AdjustQuantityRequest request, IProductRepository repo) =>
{
    var success = await repo.AdjustQuantityAsync(id, request.QuantityChange, request.Reason);
    return success ? Results.Ok() : Results.NotFound();
})
.RequireAuthorization("InventoryWrite")
.WithName("AdjustQuantity")
.WithOpenApi();

app.MapDelete("/api/inventory/products/{id:guid}", async (Guid id, IProductRepository repo) =>
{
    var success = await repo.DeleteAsync(id);
    return success ? Results.NoContent() : Results.NotFound();
})
.RequireAuthorization("InventoryWrite")
.WithName("DeleteProduct")
.WithOpenApi();

app.MapControllers();

Log.Information("Inventory API started successfully");

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

