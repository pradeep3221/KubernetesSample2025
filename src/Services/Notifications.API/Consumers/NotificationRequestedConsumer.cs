using MassTransit;
using Notifications.API.Services;
using Shared.Contracts.Events;

namespace Notifications.API.Consumers;

public class NotificationRequestedConsumer : IConsumer<NotificationRequested>
{
    private readonly INotificationService _notificationService;
    private readonly ILogger<NotificationRequestedConsumer> _logger;

    public NotificationRequestedConsumer(
        INotificationService notificationService,
        ILogger<NotificationRequestedConsumer> logger)
    {
        _notificationService = notificationService;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<NotificationRequested> context)
    {
        _logger.LogInformation("Processing NotificationRequested for user {UserId}", context.Message.UserId);

        await _notificationService.SendNotificationAsync(
            context.Message.UserId,
            context.Message.Type.ToString(),
            context.Message.Title,
            context.Message.Message,
            context.Message.Metadata);

        _logger.LogInformation("NotificationRequested processed successfully");
    }
}

