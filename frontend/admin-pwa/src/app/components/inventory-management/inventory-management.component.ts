import { Component, OnInit } from '@angular/core';
import { AdminApiService } from '../../services/admin-api.service';

@Component({
  selector: 'app-inventory-management',
  template: `
    <div class="inventory-management">
      <div class="header">
        <h1>Inventory Management</h1>
        <button class="btn btn-primary" (click)="showAddProduct = true">Add Product</button>
      </div>
      
      <div *ngIf="loading" class="loading"></div>
      
      <div class="card" *ngIf="!loading">
        <table class="table">
          <thead>
            <tr>
              <th>SKU</th>
              <th>Name</th>
              <th>Quantity</th>
              <th>Reserved</th>
              <th>Available</th>
              <th>Price</th>
              <th>Low Stock Threshold</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr *ngFor="let product of products" [class.low-stock]="product.availableQuantity < product.lowStockThreshold">
              <td>{{ product.sku }}</td>
              <td>{{ product.name }}</td>
              <td>{{ product.quantity }}</td>
              <td>{{ product.reservedQuantity }}</td>
              <td>{{ product.availableQuantity }}</td>
              <td>\${{ product.price.toFixed(2) }}</td>
              <td>{{ product.lowStockThreshold }}</td>
              <td>
                <button class="btn btn-sm btn-primary" (click)="adjustStock(product)">
                  Adjust
                </button>
                <button class="btn btn-sm btn-secondary" (click)="editProduct(product)">
                  Edit
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      
      <!-- Add Product Modal (simplified) -->
      <div class="modal" *ngIf="showAddProduct">
        <div class="modal-content card">
          <h2>Add Product</h2>
          <div class="form-group">
            <label>SKU</label>
            <input type="text" [(ngModel)]="newProduct.sku">
          </div>
          <div class="form-group">
            <label>Name</label>
            <input type="text" [(ngModel)]="newProduct.name">
          </div>
          <div class="form-group">
            <label>Description</label>
            <textarea [(ngModel)]="newProduct.description"></textarea>
          </div>
          <div class="form-group">
            <label>Quantity</label>
            <input type="number" [(ngModel)]="newProduct.quantity">
          </div>
          <div class="form-group">
            <label>Price</label>
            <input type="number" step="0.01" [(ngModel)]="newProduct.price">
          </div>
          <div class="form-group">
            <label>Low Stock Threshold</label>
            <input type="number" [(ngModel)]="newProduct.lowStockThreshold">
          </div>
          <div class="modal-actions">
            <button class="btn btn-primary" (click)="addProduct()">Add</button>
            <button class="btn btn-secondary" (click)="showAddProduct = false">Cancel</button>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .inventory-management {
      padding: 20px;
    }
    
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
    }
    
    .low-stock {
      background-color: #fff3cd;
    }
    
    .btn-sm {
      padding: 4px 8px;
      font-size: 12px;
      margin-right: 5px;
    }
    
    .modal {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background-color: rgba(0,0,0,0.5);
      display: flex;
      justify-content: center;
      align-items: center;
      z-index: 1000;
    }
    
    .modal-content {
      max-width: 500px;
      width: 100%;
      max-height: 90vh;
      overflow-y: auto;
    }
    
    .form-group {
      margin-bottom: 15px;
    }
    
    .form-group label {
      display: block;
      margin-bottom: 5px;
      font-weight: 500;
    }
    
    .form-group input,
    .form-group textarea {
      width: 100%;
      padding: 8px 12px;
      border: 1px solid #ddd;
      border-radius: 4px;
    }
    
    .modal-actions {
      display: flex;
      gap: 10px;
      justify-content: flex-end;
      margin-top: 20px;
    }
  `]
})
export class InventoryManagementComponent implements OnInit {
  products: any[] = [];
  loading = true;
  showAddProduct = false;
  newProduct = {
    sku: '',
    name: '',
    description: '',
    quantity: 0,
    price: 0,
    lowStockThreshold: 10
  };

  constructor(private apiService: AdminApiService) {}

  ngOnInit() {
    this.loadProducts();
  }

  loadProducts() {
    this.apiService.getAllProducts().subscribe({
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

  async addProduct() {
    try {
      const observable = await this.apiService.createProduct(this.newProduct);
      observable.subscribe({
        next: () => {
          alert('Product added successfully');
          this.showAddProduct = false;
          this.loadProducts();
          this.resetNewProduct();
        },
        error: (error) => {
          console.error('Error:', error);
          alert('Failed to add product');
        }
      });
    } catch (error) {
      console.error('Error:', error);
    }
  }

  async adjustStock(product: any) {
    const change = prompt('Enter quantity change (positive or negative):');
    if (change) {
      const reason = prompt('Enter reason for adjustment:');
      if (reason) {
        try {
          const observable = await this.apiService.adjustInventory(
            product.id,
            parseInt(change),
            reason
          );
          observable.subscribe({
            next: () => {
              alert('Stock adjusted successfully');
              this.loadProducts();
            },
            error: (error) => {
              console.error('Error:', error);
              alert('Failed to adjust stock');
            }
          });
        } catch (error) {
          console.error('Error:', error);
        }
      }
    }
  }

  editProduct(product: any) {
    alert('Edit functionality would be implemented here');
  }

  resetNewProduct() {
    this.newProduct = {
      sku: '',
      name: '',
      description: '',
      quantity: 0,
      price: 0,
      lowStockThreshold: 10
    };
  }
}

