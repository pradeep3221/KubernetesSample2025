using Inventory.Worker;
using Inventory.Worker.Consumers;
using MassTransit;
using Shared.Observability;
using Serilog;

var builder = Host.CreateApplicationBuilder(args);

// Add Observability (includes Serilog configuration)
builder.Services.AddObservability(builder.Configuration, "inventory-worker", "1.0.0");

// Use Serilog
builder.Services.AddSerilog();

// Add Database Connection String
builder.Services.AddSingleton(sp => 
    builder.Configuration.GetConnectionString("InventoryDb") 
    ?? "Host=localhost;Database=inventory_db;Username=postgres;Password=postgres");

// Add Services
builder.Services.AddScoped<IInventoryService, InventoryService>();

// Configure MassTransit
builder.Services.AddMassTransit(x =>
{
    x.AddConsumer<OrderCreatedConsumer>();
    x.AddConsumer<OrderCancelledConsumer>();

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

var host = builder.Build();

Log.Information("Starting Inventory Worker...");

try
{
    host.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Inventory Worker terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}

