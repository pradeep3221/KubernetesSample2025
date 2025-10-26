namespace Shared.Contracts.Events;

public record OrderCreated
{
    public Guid OrderId { get; init; }
    public Guid CustomerId { get; init; }
    public DateTime CreatedAt { get; init; }
    public decimal TotalAmount { get; init; }
    public List<OrderItem> Items { get; init; } = new();
}

public record OrderItem
{
    public Guid ProductId { get; init; }
    public string ProductName { get; init; } = string.Empty;
    public int Quantity { get; init; }
    public decimal UnitPrice { get; init; }
}

public record OrderConfirmed
{
    public Guid OrderId { get; init; }
    public DateTime ConfirmedAt { get; init; }
}

public record OrderCancelled
{
    public Guid OrderId { get; init; }
    public string Reason { get; init; } = string.Empty;
    public DateTime CancelledAt { get; init; }
}

public record OrderShipped
{
    public Guid OrderId { get; init; }
    public string TrackingNumber { get; init; } = string.Empty;
    public DateTime ShippedAt { get; init; }
}

