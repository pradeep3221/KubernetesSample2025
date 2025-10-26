using MassTransit;
using Notifications.API.Services;
using Shared.Contracts.Events;

namespace Notifications.API.Consumers;

public class LowStockAlertConsumer : IConsumer<LowStockAlert>
{
    private readonly INotificationService _notificationService;
    private readonly ILogger<LowStockAlertConsumer> _logger;

    public LowStockAlertConsumer(
        INotificationService notificationService,
        ILogger<LowStockAlertConsumer> logger)
    {
        _notificationService = notificationService;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<LowStockAlert> context)
    {
        _logger.LogInformation("Processing LowStockAlert for product {ProductId}", context.Message.ProductId);

        // In a real scenario, you'd get admin user IDs from a configuration or database
        // For now, we'll use a placeholder admin user ID
        var adminUserId = Guid.Parse("00000000-0000-0000-0000-000000000001");

        await _notificationService.SendNotificationAsync(
            adminUserId,
            "InApp",
            "Low Stock Alert",
            $"Product '{context.Message.ProductName}' is running low on stock. Current: {context.Message.CurrentQuantity}, Threshold: {context.Message.ThresholdQuantity}",
            new Dictionary<string, string>
            {
                { "ProductId", context.Message.ProductId.ToString() },
                { "ProductName", context.Message.ProductName },
                { "CurrentQuantity", context.Message.CurrentQuantity.ToString() },
                { "ThresholdQuantity", context.Message.ThresholdQuantity.ToString() }
            });

        _logger.LogInformation("LowStockAlert processed successfully");
    }
}

