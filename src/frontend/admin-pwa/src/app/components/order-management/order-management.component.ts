import { Component, OnInit } from '@angular/core';
import { AdminApiService } from '../../services/admin-api.service';

@Component({
  selector: 'app-order-management',
  template: `
    <div class="order-management">
      <h1>Order Management</h1>
      
      <div class="filters card">
        <select [(ngModel)]="statusFilter" (change)="applyFilters()">
          <option value="">All Statuses</option>
          <option value="Pending">Pending</option>
          <option value="Confirmed">Confirmed</option>
          <option value="Shipped">Shipped</option>
          <option value="Cancelled">Cancelled</option>
        </select>
        
        <input type="text" [(ngModel)]="searchTerm" (input)="applyFilters()" placeholder="Search orders...">
      </div>
      
      <div *ngIf="loading" class="loading"></div>
      
      <div class="card" *ngIf="!loading">
        <table class="table">
          <thead>
            <tr>
              <th>Order ID</th>
              <th>Customer ID</th>
              <th>Date</th>
              <th>Status</th>
              <th>Total</th>
              <th>Items</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr *ngFor="let order of filteredOrders">
              <td>{{ order.id.substring(0, 8) }}...</td>
              <td>{{ order.customerId.substring(0, 8) }}...</td>
              <td>{{ order.createdAt | date:'short' }}</td>
              <td>
                <span class="status-badge" [class]="'status-' + order.status.toLowerCase()">
                  {{ order.status }}
                </span>
              </td>
              <td>\${{ order.totalAmount.toFixed(2) }}</td>
              <td>{{ order.items.length }}</td>
              <td>
                <button class="btn btn-sm btn-primary" (click)="confirmOrder(order.id)" 
                        *ngIf="order.status === 'Pending'">
                  Confirm
                </button>
                <button class="btn btn-sm btn-secondary" (click)="shipOrder(order.id)" 
                        *ngIf="order.status === 'Confirmed'">
                  Ship
                </button>
                <button class="btn btn-sm btn-danger" (click)="cancelOrder(order.id)" 
                        *ngIf="order.status === 'Pending' || order.status === 'Confirmed'">
                  Cancel
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  `,
  styles: [`
    .order-management {
      padding: 20px;
    }
    
    .filters {
      display: flex;
      gap: 15px;
      margin-bottom: 20px;
      padding: 15px;
    }
    
    .filters select,
    .filters input {
      padding: 8px 12px;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-size: 14px;
    }
    
    .filters input {
      flex: 1;
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
      padding: 4px 8px;
      font-size: 12px;
      margin-right: 5px;
    }
  `]
})
export class OrderManagementComponent implements OnInit {
  orders: any[] = [];
  filteredOrders: any[] = [];
  loading = true;
  statusFilter = '';
  searchTerm = '';

  constructor(private apiService: AdminApiService) {}

  async ngOnInit() {
    await this.loadOrders();
  }

  async loadOrders() {
    try {
      const observable = await this.apiService.getAllOrders();
      observable.subscribe({
        next: (data) => {
          this.orders = data;
          this.filteredOrders = data;
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

  applyFilters() {
    this.filteredOrders = this.orders.filter(order => {
      const matchesStatus = !this.statusFilter || order.status === this.statusFilter;
      const matchesSearch = !this.searchTerm || 
        order.id.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
        order.customerId.toLowerCase().includes(this.searchTerm.toLowerCase());
      return matchesStatus && matchesSearch;
    });
  }

  async confirmOrder(id: string) {
    if (confirm('Confirm this order?')) {
      try {
        const observable = await this.apiService.confirmOrder(id);
        observable.subscribe({
          next: () => {
            alert('Order confirmed');
            this.loadOrders();
          },
          error: (error) => {
            console.error('Error:', error);
            alert('Failed to confirm order');
          }
        });
      } catch (error) {
        console.error('Error:', error);
      }
    }
  }

  async shipOrder(id: string) {
    const trackingNumber = prompt('Enter tracking number:');
    if (trackingNumber) {
      try {
        const observable = await this.apiService.shipOrder(id, trackingNumber);
        observable.subscribe({
          next: () => {
            alert('Order shipped');
            this.loadOrders();
          },
          error: (error) => {
            console.error('Error:', error);
            alert('Failed to ship order');
          }
        });
      } catch (error) {
        console.error('Error:', error);
      }
    }
  }

  async cancelOrder(id: string) {
    const reason = prompt('Enter cancellation reason:');
    if (reason) {
      try {
        const observable = await this.apiService.cancelOrder(id, reason);
        observable.subscribe({
          next: () => {
            alert('Order cancelled');
            this.loadOrders();
          },
          error: (error) => {
            console.error('Error:', error);
            alert('Failed to cancel order');
          }
        });
      } catch (error) {
        console.error('Error:', error);
      }
    }
  }
}

