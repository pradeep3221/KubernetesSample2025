using MassTransit;
using Shared.Contracts.Events;

namespace Inventory.Worker.Consumers;

public class OrderCreatedConsumer : IConsumer<OrderCreated>
{
    private readonly IInventoryService _inventoryService;
    private readonly ILogger<OrderCreatedConsumer> _logger;

    public OrderCreatedConsumer(
        IInventoryService inventoryService,
        ILogger<OrderCreatedConsumer> logger)
    {
        _inventoryService = inventoryService;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<OrderCreated> context)
    {
        _logger.LogInformation("Processing OrderCreated event for order {OrderId}", context.Message.OrderId);

        var items = context.Message.Items
            .Select(i => (i.ProductId, i.Quantity))
            .ToList();

        var success = await _inventoryService.ReserveInventoryAsync(context.Message.OrderId, items);

        if (success)
        {
            _logger.LogInformation("Successfully reserved inventory for order {OrderId}", context.Message.OrderId);
        }
        else
        {
            _logger.LogWarning("Failed to reserve inventory for order {OrderId}", context.Message.OrderId);
            // In a real system, you might publish an OrderInventoryReservationFailed event
            // which would trigger order cancellation
        }
    }
}

