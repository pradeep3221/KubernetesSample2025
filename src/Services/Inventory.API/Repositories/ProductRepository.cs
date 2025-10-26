using Dapper;
using Inventory.API.Models;
using MassTransit;
using Npgsql;
using Shared.Contracts.Events;

namespace Inventory.API.Repositories;

public class ProductRepository : IProductRepository
{
    private readonly string _connectionString;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly ILogger<ProductRepository> _logger;

    public ProductRepository(
        IConfiguration configuration,
        IPublishEndpoint publishEndpoint,
        ILogger<ProductRepository> logger)
    {
        _connectionString = configuration.GetConnectionString("InventoryDb")
            ?? "Host=localhost;Database=inventory_db;Username=postgres;Password=postgres";
        _publishEndpoint = publishEndpoint;
        _logger = logger;
    }

    private NpgsqlConnection GetConnection() => new(_connectionString);

    public async Task<IEnumerable<Product>> GetAllAsync()
    {
        using var connection = GetConnection();
        return await connection.QueryAsync<Product>("SELECT * FROM products ORDER BY \"Name\"");
    }

    public async Task<Product?> GetByIdAsync(Guid id)
    {
        using var connection = GetConnection();
        return await connection.QueryFirstOrDefaultAsync<Product>(
            "SELECT * FROM products WHERE id = @Id", new { Id = id });
    }

    public async Task<Product?> GetBySkuAsync(string sku)
    {
        using var connection = GetConnection();
        return await connection.QueryFirstOrDefaultAsync<Product>(
            "SELECT * FROM products WHERE sku = @Sku", new { Sku = sku });
    }

    public async Task<Product> CreateAsync(Product product)
    {
        using var connection = GetConnection();
        var sql = @"
            INSERT INTO products (id, sku, name, description, quantity, reserved_quantity, low_stock_threshold, price, created_at, updated_at)
            VALUES (@Id, @Sku, @Name, @Description, @Quantity, @ReservedQuantity, @LowStockThreshold, @Price, @CreatedAt, @UpdatedAt)
            RETURNING *";

        return await connection.QuerySingleAsync<Product>(sql, product);
    }

    public async Task<Product?> UpdateAsync(Product product)
    {
        using var connection = GetConnection();
        product.UpdatedAt = DateTime.UtcNow;

        var sql = @"
            UPDATE products 
            SET sku = @Sku, name = @Name, description = @Description, 
                quantity = @Quantity, reserved_quantity = @ReservedQuantity,
                low_stock_threshold = @LowStockThreshold, price = @Price, updated_at = @UpdatedAt
            WHERE id = @Id
            RETURNING *";

        return await connection.QueryFirstOrDefaultAsync<Product>(sql, product);
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        using var connection = GetConnection();
        var affected = await connection.ExecuteAsync("DELETE FROM products WHERE id = @Id", new { Id = id });
        return affected > 0;
    }

    public async Task<bool> AdjustQuantityAsync(Guid productId, int quantityChange, string reason)
    {
        using var connection = GetConnection();
        
        var product = await GetByIdAsync(productId);
        if (product is null) return false;

        var newQuantity = product.Quantity + quantityChange;
        if (newQuantity < 0) return false;

        var sql = @"
            UPDATE products 
            SET quantity = quantity + @QuantityChange, updated_at = @UpdatedAt
            WHERE id = @ProductId
            RETURNING *";

        var updatedProduct = await connection.QueryFirstOrDefaultAsync<Product>(sql, new
        {
            ProductId = productId,
            QuantityChange = quantityChange,
            UpdatedAt = DateTime.UtcNow
        });

        if (updatedProduct is not null)
        {
            _logger.LogInformation("Inventory adjusted for product {ProductId}: {QuantityChange}", productId, quantityChange);

            // Publish event
            await _publishEndpoint.Publish(new InventoryAdjusted
            {
                ProductId = updatedProduct.Id,
                ProductName = updatedProduct.Name,
                QuantityChange = quantityChange,
                NewQuantity = updatedProduct.Quantity,
                Reason = reason,
                AdjustedAt = DateTime.UtcNow
            });

            // Check for low stock
            if (updatedProduct.AvailableQuantity <= updatedProduct.LowStockThreshold)
            {
                await _publishEndpoint.Publish(new LowStockAlert
                {
                    ProductId = updatedProduct.Id,
                    ProductName = updatedProduct.Name,
                    CurrentQuantity = updatedProduct.AvailableQuantity,
                    ThresholdQuantity = updatedProduct.LowStockThreshold,
                    AlertedAt = DateTime.UtcNow
                });
            }

            return true;
        }

        return false;
    }

    public async Task<IEnumerable<Product>> GetLowStockProductsAsync()
    {
        using var connection = GetConnection();
        var sql = @"
            SELECT * FROM products 
            WHERE (quantity - reserved_quantity) <= low_stock_threshold
            ORDER BY (quantity - reserved_quantity)";

        return await connection.QueryAsync<Product>(sql);
    }
}

