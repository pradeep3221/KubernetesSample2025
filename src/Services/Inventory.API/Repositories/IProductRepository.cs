using Inventory.API.Models;

namespace Inventory.API.Repositories;

public interface IProductRepository
{
    Task<IEnumerable<Product>> GetAllAsync();
    Task<Product?> GetByIdAsync(Guid id);
    Task<Product?> GetBySkuAsync(string sku);
    Task<Product> CreateAsync(Product product);
    Task<Product?> UpdateAsync(Product product);
    Task<bool> DeleteAsync(Guid id);
    Task<bool> AdjustQuantityAsync(Guid productId, int quantityChange, string reason);
    Task<IEnumerable<Product>> GetLowStockProductsAsync();
}

