using Dapper;
using MassTransit;
using Npgsql;
using Shared.Contracts.Events;

namespace Inventory.Worker;

public class InventoryService : IInventoryService
{
    private readonly string _connectionString;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly ILogger<InventoryService> _logger;

    public InventoryService(
        string connectionString,
        IPublishEndpoint publishEndpoint,
        ILogger<InventoryService> logger)
    {
        _connectionString = connectionString;
        _publishEndpoint = publishEndpoint;
        _logger = logger;
    }

    private NpgsqlConnection GetConnection() => new(_connectionString);

    public async Task<bool> ReserveInventoryAsync(Guid orderId, List<(Guid ProductId, int Quantity)> items)
    {
        using var connection = GetConnection();
        await connection.OpenAsync();
        using var transaction = await connection.BeginTransactionAsync();

        try
        {
            foreach (var (productId, quantity) in items)
            {
                // Check if product exists and has enough stock
                var product = await connection.QueryFirstOrDefaultAsync<dynamic>(
                    "SELECT id, name, quantity, reserved_quantity FROM products WHERE id = @ProductId",
                    new { ProductId = productId },
                    transaction);

                if (product == null)
                {
                    _logger.LogWarning("Product {ProductId} not found for order {OrderId}", productId, orderId);
                    await transaction.RollbackAsync();
                    return false;
                }

                int availableQuantity = product.quantity - product.reserved_quantity;
                if (availableQuantity < quantity)
                {
                    _logger.LogWarning(
                        "Insufficient inventory for product {ProductId}. Available: {Available}, Requested: {Requested}",
                        productId, availableQuantity, quantity);
                    await transaction.RollbackAsync();
                    return false;
                }

                // Reserve inventory
                await connection.ExecuteAsync(
                    "UPDATE products SET reserved_quantity = reserved_quantity + @Quantity WHERE id = @ProductId",
                    new { ProductId = productId, Quantity = quantity },
                    transaction);

                // Create reservation record
                var reservationId = Guid.NewGuid();
                await connection.ExecuteAsync(@"
                    INSERT INTO reservations (id, product_id, order_id, quantity, reserved_at, status)
                    VALUES (@Id, @ProductId, @OrderId, @Quantity, @ReservedAt, 0)",
                    new
                    {
                        Id = reservationId,
                        ProductId = productId,
                        OrderId = orderId,
                        Quantity = quantity,
                        ReservedAt = DateTime.UtcNow
                    },
                    transaction);

                _logger.LogInformation(
                    "Reserved {Quantity} units of product {ProductId} for order {OrderId}",
                    quantity, productId, orderId);

                // Publish event
                await _publishEndpoint.Publish(new InventoryReserved
                {
                    ReservationId = reservationId,
                    OrderId = orderId,
                    ProductId = productId,
                    Quantity = quantity,
                    ReservedAt = DateTime.UtcNow
                });
            }

            await transaction.CommitAsync();
            _logger.LogInformation("Successfully reserved inventory for order {OrderId}", orderId);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error reserving inventory for order {OrderId}", orderId);
            await transaction.RollbackAsync();
            return false;
        }
    }

    public async Task<bool> ReleaseInventoryAsync(Guid orderId)
    {
        using var connection = GetConnection();
        await connection.OpenAsync();
        using var transaction = await connection.BeginTransactionAsync();

        try
        {
            // Get all active reservations for this order
            var reservations = await connection.QueryAsync<dynamic>(@"
                SELECT id, product_id, quantity 
                FROM reservations 
                WHERE order_id = @OrderId AND status = 0",
                new { OrderId = orderId },
                transaction);

            foreach (var reservation in reservations)
            {
                // Release reserved quantity
                await connection.ExecuteAsync(
                    "UPDATE products SET reserved_quantity = reserved_quantity - @Quantity WHERE id = @ProductId",
                    new { ProductId = (Guid)reservation.product_id, Quantity = (int)reservation.quantity },
                    transaction);

                // Mark reservation as released
                await connection.ExecuteAsync(@"
                    UPDATE reservations 
                    SET status = 1, released_at = @ReleasedAt 
                    WHERE id = @Id",
                    new { Id = (Guid)reservation.id, ReleasedAt = DateTime.UtcNow },
                    transaction);

                _logger.LogInformation(
                    "Released {Quantity} units of product {ProductId} for order {OrderId}",
                    reservation.quantity, reservation.product_id, orderId);

                // Publish event
                await _publishEndpoint.Publish(new InventoryReleased
                {
                    ReservationId = reservation.id,
                    ProductId = reservation.product_id,
                    Quantity = reservation.quantity,
                    ReleasedAt = DateTime.UtcNow
                });
            }

            await transaction.CommitAsync();
            _logger.LogInformation("Successfully released inventory for order {OrderId}", orderId);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error releasing inventory for order {OrderId}", orderId);
            await transaction.RollbackAsync();
            return false;
        }
    }
}

