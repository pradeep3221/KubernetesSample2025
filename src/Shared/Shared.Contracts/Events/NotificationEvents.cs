namespace Shared.Contracts.Events;

public record NotificationRequested
{
    public Guid NotificationId { get; init; }
    public Guid UserId { get; init; }
    public NotificationType Type { get; init; }
    public string Title { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
    public Dictionary<string, string> Metadata { get; init; } = new();
    public DateTime RequestedAt { get; init; }
}

public record NotificationSent
{
    public Guid NotificationId { get; init; }
    public Guid UserId { get; init; }
    public NotificationType Type { get; init; }
    public DateTime SentAt { get; init; }
}

public enum NotificationType
{
    Email,
    Sms,
    Push,
    InApp
}

