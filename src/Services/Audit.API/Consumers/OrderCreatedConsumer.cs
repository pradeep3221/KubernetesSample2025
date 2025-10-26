using Audit.API.Models;
using Marten;
using MassTransit;
using Shared.Contracts.Events;
using System.Text.Json;

namespace Audit.API.Consumers;

public class OrderCreatedConsumer : IConsumer<OrderCreated>
{
    private readonly IDocumentSession _session;
    private readonly ILogger<OrderCreatedConsumer> _logger;

    public OrderCreatedConsumer(IDocumentSession session, ILogger<OrderCreatedConsumer> logger)
    {
        _session = session;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<OrderCreated> context)
    {
        _logger.LogInformation("Processing OrderCreated event for OrderId: {OrderId}", context.Message.OrderId);

        // Store as event in event stream
        _session.Events.Append(context.Message.OrderId.ToString(), context.Message);

        // Store as audit document
        var auditDoc = new AuditDocument
        {
            Entity = "Order",
            Action = "Created",
            Timestamp = context.Message.CreatedAt,
            Payload = JsonSerializer.Serialize(context.Message),
            UserId = context.Message.CustomerId.ToString(),
            Metadata = new Dictionary<string, string>
            {
                { "OrderId", context.Message.OrderId.ToString() },
                { "TotalAmount", context.Message.TotalAmount.ToString("C") },
                { "ItemCount", context.Message.Items.Count.ToString() }
            }
        };

        _session.Store(auditDoc);
        await _session.SaveChangesAsync();

        _logger.LogInformation("OrderCreated event processed successfully for OrderId: {OrderId}", context.Message.OrderId);
    }
}

