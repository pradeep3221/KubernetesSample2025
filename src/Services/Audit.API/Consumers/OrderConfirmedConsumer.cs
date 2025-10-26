using Audit.API.Models;
using Marten;
using MassTransit;
using Shared.Contracts.Events;
using System.Text.Json;

namespace Audit.API.Consumers;

public class OrderConfirmedConsumer : IConsumer<OrderConfirmed>
{
    private readonly IDocumentSession _session;
    private readonly ILogger<OrderConfirmedConsumer> _logger;

    public OrderConfirmedConsumer(IDocumentSession session, ILogger<OrderConfirmedConsumer> logger)
    {
        _session = session;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<OrderConfirmed> context)
    {
        _logger.LogInformation("Processing OrderConfirmed event for OrderId: {OrderId}", context.Message.OrderId);

        _session.Events.Append(context.Message.OrderId.ToString(), context.Message);

        var auditDoc = new AuditDocument
        {
            Entity = "Order",
            Action = "Confirmed",
            Timestamp = context.Message.ConfirmedAt,
            Payload = JsonSerializer.Serialize(context.Message),
            Metadata = new Dictionary<string, string>
            {
                { "OrderId", context.Message.OrderId.ToString() }
            }
        };

        _session.Store(auditDoc);
        await _session.SaveChangesAsync();

        _logger.LogInformation("OrderConfirmed event processed successfully");
    }
}

