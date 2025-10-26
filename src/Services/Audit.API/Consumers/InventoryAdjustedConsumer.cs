using Audit.API.Models;
using Marten;
using MassTransit;
using Shared.Contracts.Events;
using System.Text.Json;

namespace Audit.API.Consumers;

public class InventoryAdjustedConsumer : IConsumer<InventoryAdjusted>
{
    private readonly IDocumentSession _session;
    private readonly ILogger<InventoryAdjustedConsumer> _logger;

    public InventoryAdjustedConsumer(IDocumentSession session, ILogger<InventoryAdjustedConsumer> logger)
    {
        _session = session;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<InventoryAdjusted> context)
    {
        _logger.LogInformation("Processing InventoryAdjusted event for ProductId: {ProductId}", context.Message.ProductId);

        _session.Events.Append($"inventory-{context.Message.ProductId}", context.Message);

        var auditDoc = new AuditDocument
        {
            Entity = "Inventory",
            Action = "Adjusted",
            Timestamp = context.Message.AdjustedAt,
            Payload = JsonSerializer.Serialize(context.Message),
            Metadata = new Dictionary<string, string>
            {
                { "ProductId", context.Message.ProductId.ToString() },
                { "ProductName", context.Message.ProductName },
                { "QuantityChange", context.Message.QuantityChange.ToString() },
                { "NewQuantity", context.Message.NewQuantity.ToString() },
                { "Reason", context.Message.Reason }
            }
        };

        _session.Store(auditDoc);
        await _session.SaveChangesAsync();

        _logger.LogInformation("InventoryAdjusted event processed successfully");
    }
}

