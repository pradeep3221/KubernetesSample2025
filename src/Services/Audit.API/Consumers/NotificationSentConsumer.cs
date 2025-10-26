using Audit.API.Models;
using Marten;
using MassTransit;
using Shared.Contracts.Events;
using System.Text.Json;

namespace Audit.API.Consumers;

public class NotificationSentConsumer : IConsumer<NotificationSent>
{
    private readonly IDocumentSession _session;
    private readonly ILogger<NotificationSentConsumer> _logger;

    public NotificationSentConsumer(IDocumentSession session, ILogger<NotificationSentConsumer> logger)
    {
        _session = session;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<NotificationSent> context)
    {
        _logger.LogInformation("Processing NotificationSent event for NotificationId: {NotificationId}", context.Message.NotificationId);

        _session.Events.Append($"notification-{context.Message.NotificationId}", context.Message);

        var auditDoc = new AuditDocument
        {
            Entity = "Notification",
            Action = "Sent",
            Timestamp = context.Message.SentAt,
            Payload = JsonSerializer.Serialize(context.Message),
            UserId = context.Message.UserId.ToString(),
            Metadata = new Dictionary<string, string>
            {
                { "NotificationId", context.Message.NotificationId.ToString() },
                { "Type", context.Message.Type.ToString() }
            }
        };

        _session.Store(auditDoc);
        await _session.SaveChangesAsync();

        _logger.LogInformation("NotificationSent event processed successfully");
    }
}

