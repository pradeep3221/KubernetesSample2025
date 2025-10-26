using MassTransit;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Shared.Contracts.Events;
using Spectre.Console;
using Serilog;

// Configure Serilog for console app
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .Enrich.FromLogContext()
    .WriteTo.Console(outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}")
    .CreateLogger();

var builder = Host.CreateApplicationBuilder(args);

// Add Serilog
builder.Services.AddLogging(loggingBuilder =>
{
    loggingBuilder.ClearProviders();
    loggingBuilder.AddSerilog(dispose: true);
});

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
    });
});

var host = builder.Build();

Log.Information("Notifications Console started");

// Display welcome banner
AnsiConsole.Write(
    new FigletText("Notifications Console")
        .LeftJustified()
        .Color(Color.Blue));

AnsiConsole.MarkupLine("[bold yellow]Event Publishing Tool for Microservices[/]");
AnsiConsole.WriteLine();

var publishEndpoint = host.Services.GetRequiredService<IPublishEndpoint>();

Log.Information("Ready to publish events");

while (true)
{
    var choice = AnsiConsole.Prompt(
        new SelectionPrompt<string>()
            .Title("[green]What would you like to do?[/]")
            .PageSize(10)
            .AddChoices(new[]
            {
                "Send Notification Request",
                "Publish Order Created Event",
                "Publish Inventory Adjusted Event",
                "Publish Low Stock Alert",
                "View Configuration",
                "Exit"
            }));

    switch (choice)
    {
        case "Send Notification Request":
            await SendNotificationRequest(publishEndpoint);
            break;
        case "Publish Order Created Event":
            await PublishOrderCreated(publishEndpoint);
            break;
        case "Publish Inventory Adjusted Event":
            await PublishInventoryAdjusted(publishEndpoint);
            break;
        case "Publish Low Stock Alert":
            await PublishLowStockAlert(publishEndpoint);
            break;
        case "View Configuration":
            ViewConfiguration(builder.Configuration);
            break;
        case "Exit":
            AnsiConsole.MarkupLine("[yellow]Goodbye![/]");
            return;
    }

    AnsiConsole.WriteLine();
}

static async Task SendNotificationRequest(IPublishEndpoint publishEndpoint)
{
    AnsiConsole.MarkupLine("[bold blue]Send Notification Request[/]");

    var userId = AnsiConsole.Ask<string>("Enter [green]User ID[/] (GUID):", Guid.NewGuid().ToString());
    var type = AnsiConsole.Prompt(
        new SelectionPrompt<string>()
            .Title("Select [green]notification type[/]:")
            .AddChoices("Email", "Sms", "Push", "InApp"));
    var title = AnsiConsole.Ask<string>("Enter [green]title[/]:");
    var message = AnsiConsole.Ask<string>("Enter [green]message[/]:");

    var notificationType = Enum.Parse<NotificationType>(type);

    await publishEndpoint.Publish(new NotificationRequested
    {
        NotificationId = Guid.NewGuid(),
        UserId = Guid.Parse(userId),
        Type = notificationType,
        Title = title,
        Message = message,
        Metadata = new Dictionary<string, string>
        {
            { "Source", "Console" },
            { "Timestamp", DateTime.UtcNow.ToString("O") }
        },
        RequestedAt = DateTime.UtcNow
    });

    AnsiConsole.MarkupLine("[green]✓[/] Notification request published successfully!");
}

static async Task PublishOrderCreated(IPublishEndpoint publishEndpoint)
{
    AnsiConsole.MarkupLine("[bold blue]Publish Order Created Event[/]");

    var orderId = Guid.NewGuid();
    var customerId = AnsiConsole.Ask<string>("Enter [green]Customer ID[/] (GUID):", Guid.NewGuid().ToString());
    var itemCount = AnsiConsole.Ask<int>("How many [green]items[/] in the order?", 1);

    var items = new List<Shared.Contracts.Events.OrderItem>();
    decimal totalAmount = 0;

    for (int i = 0; i < itemCount; i++)
    {
        AnsiConsole.MarkupLine($"[yellow]Item {i + 1}:[/]");
        var productName = AnsiConsole.Ask<string>("  Product name:");
        var quantity = AnsiConsole.Ask<int>("  Quantity:");
        var unitPrice = AnsiConsole.Ask<decimal>("  Unit price:");

        items.Add(new Shared.Contracts.Events.OrderItem
        {
            ProductId = Guid.NewGuid(),
            ProductName = productName,
            Quantity = quantity,
            UnitPrice = unitPrice
        });

        totalAmount += quantity * unitPrice;
    }

    await publishEndpoint.Publish(new OrderCreated
    {
        OrderId = orderId,
        CustomerId = Guid.Parse(customerId),
        CreatedAt = DateTime.UtcNow,
        TotalAmount = totalAmount,
        Items = items
    });

    AnsiConsole.MarkupLine($"[green]✓[/] Order created event published! Order ID: [cyan]{orderId}[/]");
}

static async Task PublishInventoryAdjusted(IPublishEndpoint publishEndpoint)
{
    AnsiConsole.MarkupLine("[bold blue]Publish Inventory Adjusted Event[/]");

    var productId = AnsiConsole.Ask<string>("Enter [green]Product ID[/] (GUID):", Guid.NewGuid().ToString());
    var productName = AnsiConsole.Ask<string>("Enter [green]Product Name[/]:");
    var quantityChange = AnsiConsole.Ask<int>("Enter [green]Quantity Change[/] (positive or negative):");
    var newQuantity = AnsiConsole.Ask<int>("Enter [green]New Total Quantity[/]:");
    var reason = AnsiConsole.Ask<string>("Enter [green]Reason[/]:");

    await publishEndpoint.Publish(new InventoryAdjusted
    {
        ProductId = Guid.Parse(productId),
        ProductName = productName,
        QuantityChange = quantityChange,
        NewQuantity = newQuantity,
        Reason = reason,
        AdjustedAt = DateTime.UtcNow
    });

    AnsiConsole.MarkupLine("[green]✓[/] Inventory adjusted event published successfully!");
}

static async Task PublishLowStockAlert(IPublishEndpoint publishEndpoint)
{
    AnsiConsole.MarkupLine("[bold blue]Publish Low Stock Alert[/]");

    var productId = AnsiConsole.Ask<string>("Enter [green]Product ID[/] (GUID):", Guid.NewGuid().ToString());
    var productName = AnsiConsole.Ask<string>("Enter [green]Product Name[/]:");
    var currentQuantity = AnsiConsole.Ask<int>("Enter [green]Current Quantity[/]:");
    var thresholdQuantity = AnsiConsole.Ask<int>("Enter [green]Threshold Quantity[/]:");

    await publishEndpoint.Publish(new LowStockAlert
    {
        ProductId = Guid.Parse(productId),
        ProductName = productName,
        CurrentQuantity = currentQuantity,
        ThresholdQuantity = thresholdQuantity,
        AlertedAt = DateTime.UtcNow
    });

    AnsiConsole.MarkupLine("[green]✓[/] Low stock alert published successfully!");
}

static void ViewConfiguration(IConfiguration configuration)
{
    var table = new Table();
    table.AddColumn("Setting");
    table.AddColumn("Value");

    table.AddRow("RabbitMQ Host", configuration["RabbitMQ:Host"] ?? "localhost");
    table.AddRow("RabbitMQ User", configuration["RabbitMQ:User"] ?? "guest");
    table.AddRow("Environment", configuration["Environment"] ?? "development");

    AnsiConsole.Write(table);
}

