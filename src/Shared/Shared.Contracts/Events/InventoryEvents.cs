namespace Shared.Contracts.Events;

public record InventoryAdjusted
{
    public Guid ProductId { get; init; }
    public string ProductName { get; init; } = string.Empty;
    public int QuantityChange { get; init; }
    public int NewQuantity { get; init; }
    public string Reason { get; init; } = string.Empty;
    public DateTime AdjustedAt { get; init; }
}

public record InventoryReserved
{
    public Guid ReservationId { get; init; }
    public Guid OrderId { get; init; }
    public Guid ProductId { get; init; }
    public int Quantity { get; init; }
    public DateTime ReservedAt { get; init; }
}

public record InventoryReleased
{
    public Guid ReservationId { get; init; }
    public Guid ProductId { get; init; }
    public int Quantity { get; init; }
    public DateTime ReleasedAt { get; init; }
}

public record LowStockAlert
{
    public Guid ProductId { get; init; }
    public string ProductName { get; init; } = string.Empty;
    public int CurrentQuantity { get; init; }
    public int ThresholdQuantity { get; init; }
    public DateTime AlertedAt { get; init; }
}

