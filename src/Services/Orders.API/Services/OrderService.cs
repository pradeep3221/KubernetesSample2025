using MassTransit;
using Microsoft.EntityFrameworkCore;
using Orders.API.Data;
using Orders.API.Models;
using Shared.Contracts.Events;

namespace Orders.API.Services;

public class OrderService : IOrderService
{
    private readonly OrdersDbContext _context;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly ILogger<OrderService> _logger;

    public OrderService(
        OrdersDbContext context,
        IPublishEndpoint publishEndpoint,
        ILogger<OrderService> logger)
    {
        _context = context;
        _publishEndpoint = publishEndpoint;
        _logger = logger;
    }

    public async Task<Order> CreateOrderAsync(CreateOrderRequest request)
    {
        var order = new Order
        {
            OrderNumber = $"ORD-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString()[..8].ToUpper()}",
            CustomerId = request.CustomerId,
            CreatedAt = DateTime.UtcNow,
            Status = OrderStatus.Pending,
            Items = request.Items.Select(i => new OrderItem
            {
                ProductId = i.ProductId,
                ProductName = i.ProductName,
                Quantity = i.Quantity,
                UnitPrice = i.UnitPrice
            }).ToList()
        };

        order.TotalAmount = order.Items.Sum(i => i.Quantity * i.UnitPrice);

        _context.Orders.Add(order);
        await _context.SaveChangesAsync();

        _logger.LogInformation("Order created: {OrderId} - {OrderNumber}", order.Id, order.OrderNumber);

        // Publish event
        await _publishEndpoint.Publish(new OrderCreated
        {
            OrderId = order.Id,
            CustomerId = order.CustomerId,
            CreatedAt = order.CreatedAt,
            TotalAmount = order.TotalAmount,
            Items = order.Items.Select(i => new Shared.Contracts.Events.OrderItem
            {
                ProductId = i.ProductId,
                ProductName = i.ProductName,
                Quantity = i.Quantity,
                UnitPrice = i.UnitPrice
            }).ToList()
        });

        return order;
    }

    public async Task<Order?> ConfirmOrderAsync(Guid orderId)
    {
        var order = await _context.Orders.FindAsync(orderId);
        if (order is null) return null;

        order.Status = OrderStatus.Confirmed;
        order.ConfirmedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        _logger.LogInformation("Order confirmed: {OrderId}", orderId);

        await _publishEndpoint.Publish(new OrderConfirmed
        {
            OrderId = order.Id,
            ConfirmedAt = order.ConfirmedAt.Value
        });

        return order;
    }

    public async Task<Order?> CancelOrderAsync(Guid orderId, string reason)
    {
        var order = await _context.Orders.FindAsync(orderId);
        if (order is null) return null;

        order.Status = OrderStatus.Cancelled;
        order.CancelledAt = DateTime.UtcNow;
        order.CancellationReason = reason;

        await _context.SaveChangesAsync();

        _logger.LogInformation("Order cancelled: {OrderId} - Reason: {Reason}", orderId, reason);

        await _publishEndpoint.Publish(new OrderCancelled
        {
            OrderId = order.Id,
            Reason = reason,
            CancelledAt = order.CancelledAt.Value
        });

        return order;
    }

    public async Task<Order?> ShipOrderAsync(Guid orderId, string trackingNumber)
    {
        var order = await _context.Orders.FindAsync(orderId);
        if (order is null) return null;

        order.Status = OrderStatus.Shipped;
        order.ShippedAt = DateTime.UtcNow;
        order.TrackingNumber = trackingNumber;

        await _context.SaveChangesAsync();

        _logger.LogInformation("Order shipped: {OrderId} - Tracking: {TrackingNumber}", orderId, trackingNumber);

        await _publishEndpoint.Publish(new OrderShipped
        {
            OrderId = order.Id,
            TrackingNumber = trackingNumber,
            ShippedAt = order.ShippedAt.Value
        });

        return order;
    }
}

