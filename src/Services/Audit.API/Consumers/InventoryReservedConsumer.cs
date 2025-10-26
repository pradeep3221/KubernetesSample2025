using Audit.API.Models;
using Marten;
using MassTransit;
using Shared.Contracts.Events;
using System.Text.Json;

namespace Audit.API.Consumers;

public class InventoryReservedConsumer : IConsumer<InventoryReserved>
{
    private readonly IDocumentSession _session;
    private readonly ILogger<InventoryReservedConsumer> _logger;

    public InventoryReservedConsumer(IDocumentSession session, ILogger<InventoryReservedConsumer> logger)
    {
        _session = session;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<InventoryReserved> context)
    {
        _logger.LogInformation("Processing InventoryReserved event for ReservationId: {ReservationId}", context.Message.ReservationId);

        _session.Events.Append($"inventory-{context.Message.ProductId}", context.Message);

        var auditDoc = new AuditDocument
        {
            Entity = "Inventory",
            Action = "Reserved",
            Timestamp = context.Message.ReservedAt,
            Payload = JsonSerializer.Serialize(context.Message),
            Metadata = new Dictionary<string, string>
            {
                { "ReservationId", context.Message.ReservationId.ToString() },
                { "OrderId", context.Message.OrderId.ToString() },
                { "ProductId", context.Message.ProductId.ToString() },
                { "Quantity", context.Message.Quantity.ToString() }
            }
        };

        _session.Store(auditDoc);
        await _session.SaveChangesAsync();

        _logger.LogInformation("InventoryReserved event processed successfully");
    }
}

