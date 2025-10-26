import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { ApiService } from '../../services/api.service';

@Component({
  selector: 'app-order-detail',
  template: `
    <div class="order-detail">
      <button class="btn btn-secondary" routerLink="/orders">← Back to Orders</button>
      
      <div *ngIf="loading" class="loading"></div>
      
      <div *ngIf="!loading && order" class="card" style="margin-top: 20px;">
        <h2>Order Details</h2>
        
        <div class="order-info">
          <div class="info-row">
            <span class="label">Order ID:</span>
            <span>{{ order.id }}</span>
          </div>
          <div class="info-row">
            <span class="label">Status:</span>
            <span class="status-badge" [class]="'status-' + order.status.toLowerCase()">
              {{ order.status }}
            </span>
          </div>
          <div class="info-row">
            <span class="label">Created:</span>
            <span>{{ order.createdAt | date:'full' }}</span>
          </div>
          <div class="info-row">
            <span class="label">Total Amount:</span>
            <span class="total">\${{ order.totalAmount.toFixed(2) }}</span>
          </div>
        </div>
        
        <h3>Order Items</h3>
        <table class="table">
          <thead>
            <tr>
              <th>Product</th>
              <th>Quantity</th>
              <th>Unit Price</th>
              <th>Subtotal</th>
            </tr>
          </thead>
          <tbody>
            <tr *ngFor="let item of order.items">
              <td>{{ item.productName }}</td>
              <td>{{ item.quantity }}</td>
              <td>\${{ item.unitPrice.toFixed(2) }}</td>
              <td>\${{ (item.quantity * item.unitPrice).toFixed(2) }}</td>
            </tr>
          </tbody>
        </table>
        
        <div class="order-actions" *ngIf="order.status === 'Pending'">
          <button class="btn btn-danger" (click)="cancelOrder()">Cancel Order</button>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .order-detail {
      padding: 20px 0;
    }
    
    .order-info {
      margin: 20px 0;
    }
    
    .info-row {
      display: flex;
      justify-content: space-between;
      padding: 10px 0;
      border-bottom: 1px solid #eee;
    }
    
    .label {
      font-weight: 600;
      color: #666;
    }
    
    .total {
      font-size: 20px;
      font-weight: bold;
      color: #007bff;
    }
    
    .status-badge {
      padding: 4px 12px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 500;
    }
    
    .status-pending {
      background-color: #fff3cd;
      color: #856404;
    }
    
    .status-confirmed {
      background-color: #d1ecf1;
      color: #0c5460;
    }
    
    .status-shipped {
      background-color: #d4edda;
      color: #155724;
    }
    
    .status-cancelled {
      background-color: #f8d7da;
      color: #721c24;
    }
    
    h3 {
      margin-top: 30px;
      margin-bottom: 15px;
    }
    
    .order-actions {
      margin-top: 30px;
      padding-top: 20px;
      border-top: 1px solid #eee;
    }
  `]
})
export class OrderDetailComponent implements OnInit {
  order: any = null;
  loading = true;

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private apiService: ApiService
  ) {}

  async ngOnInit() {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      await this.loadOrder(id);
    }
  }

  async loadOrder(id: string) {
    try {
      const observable = await this.apiService.getOrder(id);
      observable.subscribe({
        next: (data) => {
          this.order = data;
          this.loading = false;
        },
        error: (error) => {
          console.error('Error loading order:', error);
          this.loading = false;
        }
      });
    } catch (error) {
      console.error('Error:', error);
      this.loading = false;
    }
  }

  async cancelOrder() {
    if (confirm('Are you sure you want to cancel this order?')) {
      try {
        const observable = await this.apiService.cancelOrder(this.order.id, 'Customer requested cancellation');
        observable.subscribe({
          next: () => {
            alert('Order cancelled successfully');
            this.router.navigate(['/orders']);
          },
          error: (error) => {
            console.error('Error cancelling order:', error);
            alert('Failed to cancel order');
          }
        });
      } catch (error) {
        console.error('Error:', error);
        alert('Failed to cancel order');
      }
    }
  }
}

