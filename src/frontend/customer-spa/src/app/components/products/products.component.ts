import { Component, OnInit } from '@angular/core';
import { ApiService } from '../../services/api.service';

@Component({
  selector: 'app-products',
  template: `
    <div class="products">
      <h1>Products</h1>
      
      <div *ngIf="loading" class="loading"></div>
      
      <div *ngIf="!loading && products.length === 0" class="alert alert-info">
        No products available at the moment.
      </div>
      
      <div class="products-grid" *ngIf="!loading && products.length > 0">
        <div class="product-card" *ngFor="let product of products">
          <h3>{{ product.name }}</h3>
          <p class="sku">SKU: {{ product.sku }}</p>
          <p class="description">{{ product.description }}</p>
          <div class="product-footer">
            <span class="price">\${{ product.price.toFixed(2) }}</span>
            <span class="stock" [class.low-stock]="product.availableQuantity < 10">
              {{ product.availableQuantity }} in stock
            </span>
          </div>
          <button class="btn btn-primary" (click)="addToCart(product)" 
                  [disabled]="product.availableQuantity === 0">
            {{ product.availableQuantity === 0 ? 'Out of Stock' : 'Add to Cart' }}
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .products {
      padding: 20px 0;
    }
    
    h1 {
      margin-bottom: 30px;
    }
    
    .products-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 20px;
    }
    
    .product-card {
      background: white;
      border-radius: 8px;
      padding: 20px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      transition: transform 0.3s;
    }
    
    .product-card:hover {
      transform: translateY(-5px);
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    }
    
    .product-card h3 {
      margin-bottom: 10px;
      color: #333;
    }
    
    .sku {
      color: #666;
      font-size: 12px;
      margin-bottom: 10px;
    }
    
    .description {
      color: #666;
      margin-bottom: 15px;
      min-height: 40px;
    }
    
    .product-footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 15px;
      padding-top: 15px;
      border-top: 1px solid #eee;
    }
    
    .price {
      font-size: 24px;
      font-weight: bold;
      color: #007bff;
    }
    
    .stock {
      color: #28a745;
      font-size: 14px;
    }
    
    .stock.low-stock {
      color: #dc3545;
    }
    
    .btn {
      width: 100%;
    }
  `]
})
export class ProductsComponent implements OnInit {
  products: any[] = [];
  loading = true;

  constructor(private apiService: ApiService) {}

  ngOnInit() {
    this.loadProducts();
  }

  loadProducts() {
    this.apiService.getProducts().subscribe({
      next: (data) => {
        this.products = data;
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading products:', error);
        this.loading = false;
      }
    });
  }

  addToCart(product: any) {
    // In a real app, this would add to a cart service
    alert(`Added ${product.name} to cart!`);
  }
}

