using Audit.API.Models;
using Marten;
using MassTransit;
using Shared.Contracts.Events;
using System.Text.Json;

namespace Audit.API.Consumers;

public class OrderCancelledConsumer : IConsumer<OrderCancelled>
{
    private readonly IDocumentSession _session;
    private readonly ILogger<OrderCancelledConsumer> _logger;

    public OrderCancelledConsumer(IDocumentSession session, ILogger<OrderCancelledConsumer> logger)
    {
        _session = session;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<OrderCancelled> context)
    {
        _logger.LogInformation("Processing OrderCancelled event for OrderId: {OrderId}", context.Message.OrderId);

        _session.Events.Append(context.Message.OrderId.ToString(), context.Message);

        var auditDoc = new AuditDocument
        {
            Entity = "Order",
            Action = "Cancelled",
            Timestamp = context.Message.CancelledAt,
            Payload = JsonSerializer.Serialize(context.Message),
            Metadata = new Dictionary<string, string>
            {
                { "OrderId", context.Message.OrderId.ToString() },
                { "Reason", context.Message.Reason }
            }
        };

        _session.Store(auditDoc);
        await _session.SaveChangesAsync();

        _logger.LogInformation("OrderCancelled event processed successfully");
    }
}

