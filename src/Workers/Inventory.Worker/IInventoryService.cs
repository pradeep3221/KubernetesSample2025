namespace Inventory.Worker;

public interface IInventoryService
{
    Task<bool> ReserveInventoryAsync(Guid orderId, List<(Guid ProductId, int Quantity)> items);
    Task<bool> ReleaseInventoryAsync(Guid orderId);
}

