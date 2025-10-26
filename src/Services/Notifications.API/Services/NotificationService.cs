using MassTransit;
using Notifications.API.Models;
using Shared.Contracts.Events;
using StackExchange.Redis;
using System.Text.Json;

namespace Notifications.API.Services;

public class NotificationService : INotificationService
{
    private readonly IConnectionMultiplexer _redis;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly ILogger<NotificationService> _logger;

    public NotificationService(
        IConnectionMultiplexer redis,
        IPublishEndpoint publishEndpoint,
        ILogger<NotificationService> logger)
    {
        _redis = redis;
        _publishEndpoint = publishEndpoint;
        _logger = logger;
    }

    public async Task<Notification> SendNotificationAsync(Guid userId, string type, string title, string message, Dictionary<string, string>? metadata = null)
    {
        var notification = new Notification
        {
            UserId = userId,
            Type = type,
            Title = title,
            Message = message,
            Metadata = metadata ?? new Dictionary<string, string>()
        };

        var db = _redis.GetDatabase();
        
        // Store notification
        var key = $"notification:{notification.Id}";
        await db.StringSetAsync(key, JsonSerializer.Serialize(notification), TimeSpan.FromDays(30));

        // Add to user's notification list
        var userKey = $"user:{userId}:notifications";
        await db.ListLeftPushAsync(userKey, notification.Id.ToString());
        await db.KeyExpireAsync(userKey, TimeSpan.FromDays(30));

        _logger.LogInformation("Notification sent to user {UserId}: {Title}", userId, title);

        // Publish event
        var notificationType = Enum.TryParse<NotificationType>(type, true, out var parsedType) 
            ? parsedType 
            : NotificationType.InApp;

        await _publishEndpoint.Publish(new NotificationSent
        {
            NotificationId = notification.Id,
            UserId = userId,
            Type = notificationType,
            SentAt = notification.CreatedAt
        });

        return notification;
    }

    public async Task<Notification?> GetNotificationAsync(Guid id)
    {
        var db = _redis.GetDatabase();
        var key = $"notification:{id}";
        var value = await db.StringGetAsync(key);

        if (value.IsNullOrEmpty) return null;

        return JsonSerializer.Deserialize<Notification>(value!);
    }

    public async Task<IEnumerable<Notification>> GetUserNotificationsAsync(Guid userId, int limit = 50)
    {
        var db = _redis.GetDatabase();
        var userKey = $"user:{userId}:notifications";
        var notificationIds = await db.ListRangeAsync(userKey, 0, limit - 1);

        var notifications = new List<Notification>();
        foreach (var id in notificationIds)
        {
            var notification = await GetNotificationAsync(Guid.Parse(id!));
            if (notification is not null)
            {
                notifications.Add(notification);
            }
        }

        return notifications;
    }

    public async Task<bool> MarkAsReadAsync(Guid id)
    {
        var notification = await GetNotificationAsync(id);
        if (notification is null) return false;

        notification.ReadAt = DateTime.UtcNow;

        var db = _redis.GetDatabase();
        var key = $"notification:{id}";
        await db.StringSetAsync(key, JsonSerializer.Serialize(notification), TimeSpan.FromDays(30));

        _logger.LogInformation("Notification marked as read: {NotificationId}", id);

        return true;
    }
}

