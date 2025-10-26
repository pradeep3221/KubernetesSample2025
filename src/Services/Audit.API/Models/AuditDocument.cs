namespace Audit.API.Models;

public record AuditDocument
{
    public Guid Id { get; init; } = Guid.NewGuid();
    public string Entity { get; init; } = string.Empty;
    public string Action { get; init; } = string.Empty;
    public DateTime Timestamp { get; init; } = DateTime.UtcNow;
    public string Payload { get; init; } = string.Empty;
    public string UserId { get; init; } = string.Empty;
    public Dictionary<string, string> Metadata { get; init; } = new();
}

