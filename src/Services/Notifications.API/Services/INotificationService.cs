using Notifications.API.Models;

namespace Notifications.API.Services;

public interface INotificationService
{
    Task<Notification> SendNotificationAsync(Guid userId, string type, string title, string message, Dictionary<string, string>? metadata = null);
    Task<Notification?> GetNotificationAsync(Guid id);
    Task<IEnumerable<Notification>> GetUserNotificationsAsync(Guid userId, int limit = 50);
    Task<bool> MarkAsReadAsync(Guid id);
}

