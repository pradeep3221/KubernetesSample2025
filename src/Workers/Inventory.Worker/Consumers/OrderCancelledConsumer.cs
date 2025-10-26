using MassTransit;
using Shared.Contracts.Events;

namespace Inventory.Worker.Consumers;

public class OrderCancelledConsumer : IConsumer<OrderCancelled>
{
    private readonly IInventoryService _inventoryService;
    private readonly ILogger<OrderCancelledConsumer> _logger;

    public OrderCancelledConsumer(
        IInventoryService inventoryService,
        ILogger<OrderCancelledConsumer> logger)
    {
        _inventoryService = inventoryService;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<OrderCancelled> context)
    {
        _logger.LogInformation("Processing OrderCancelled event for order {OrderId}", context.Message.OrderId);

        var success = await _inventoryService.ReleaseInventoryAsync(context.Message.OrderId);

        if (success)
        {
            _logger.LogInformation("Successfully released inventory for cancelled order {OrderId}", context.Message.OrderId);
        }
        else
        {
            _logger.LogWarning("Failed to release inventory for cancelled order {OrderId}", context.Message.OrderId);
        }
    }
}

