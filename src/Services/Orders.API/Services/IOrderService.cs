using Orders.API.Models;

namespace Orders.API.Services;

public interface IOrderService
{
    Task<Order> CreateOrderAsync(CreateOrderRequest request);
    Task<Order?> ConfirmOrderAsync(Guid orderId);
    Task<Order?> CancelOrderAsync(Guid orderId, string reason);
    Task<Order?> ShipOrderAsync(Guid orderId, string trackingNumber);
}

public record CreateOrderRequest(
    Guid CustomerId,
    List<CreateOrderItemRequest> Items
);

public record CreateOrderItemRequest(
    Guid ProductId,
    string ProductName,
    int Quantity,
    decimal UnitPrice
);

