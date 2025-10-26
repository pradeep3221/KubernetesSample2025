import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { ApiService } from '../../services/api.service';

@Component({
  selector: 'app-orders',
  template: `
    <div class="orders">
      <div class="orders-header">
        <h1>My Orders</h1>
        <button class="btn btn-primary" routerLink="/orders/create">Create New Order</button>
      </div>
      
      <div *ngIf="loading" class="loading"></div>
      
      <div *ngIf="!loading && orders.length === 0" class="alert alert-info">
        You don't have any orders yet. <a routerLink="/orders/create">Create your first order</a>
      </div>
      
      <div class="card" *ngIf="!loading && orders.length > 0">
        <table class="table">
          <thead>
            <tr>
              <th>Order ID</th>
              <th>Date</th>
              <th>Status</th>
              <th>Total</th>
              <th>Items</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr *ngFor="let order of orders" (click)="viewOrder(order.id)" style="cursor: pointer;">
              <td>{{ order.id.substring(0, 8) }}...</td>
              <td>{{ order.createdAt | date:'short' }}</td>
              <td>
                <span class="status-badge" [class]="'status-' + order.status.toLowerCase()">
                  {{ order.status }}
                </span>
              </td>
              <td>\${{ order.totalAmount.toFixed(2) }}</td>
              <td>{{ order.items.length }}</td>
              <td>
                <button class="btn btn-secondary btn-sm" (click)="viewOrder(order.id); $event.stopPropagation()">
                  View
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  `,
  styles: [`
    .orders {
      padding: 20px 0;
    }
    
    .orders-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 30px;
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
    
    .btn-sm {
      padding: 6px 12px;
      font-size: 12px;
    }
  `]
})
export class OrdersComponent implements OnInit {
  orders: any[] = [];
  loading = true;

  constructor(
    private apiService: ApiService,
    private router: Router
  ) {}

  async ngOnInit() {
    await this.loadOrders();
  }

  async loadOrders() {
    try {
      const observable = await this.apiService.getOrders();
      observable.subscribe({
        next: (data) => {
          this.orders = data;
          this.loading = false;
        },
        error: (error) => {
          console.error('Error loading orders:', error);
          this.loading = false;
        }
      });
    } catch (error) {
      console.error('Error:', error);
      this.loading = false;
    }
  }

  viewOrder(id: string) {
    this.router.navigate(['/orders', id]);
  }
}

