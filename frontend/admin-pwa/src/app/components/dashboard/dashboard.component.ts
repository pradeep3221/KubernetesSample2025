import { Component, OnInit } from '@angular/core';
import { AdminApiService } from '../../services/admin-api.service';

@Component({
  selector: 'app-dashboard',
  template: `
    <div class="dashboard">
      <h1>Dashboard</h1>
      
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-icon">📦</div>
          <div class="stat-content">
            <h3>Total Orders</h3>
            <p class="stat-value">{{ stats.totalOrders }}</p>
          </div>
        </div>
        
        <div class="stat-card">
          <div class="stat-icon">✅</div>
          <div class="stat-content">
            <h3>Confirmed Orders</h3>
            <p class="stat-value">{{ stats.confirmedOrders }}</p>
          </div>
        </div>
        
        <div class="stat-card">
          <div class="stat-icon">📋</div>
          <div class="stat-content">
            <h3>Products</h3>
            <p class="stat-value">{{ stats.totalProducts }}</p>
          </div>
        </div>
        
        <div class="stat-card">
          <div class="stat-icon">⚠️</div>
          <div class="stat-content">
            <h3>Low Stock Items</h3>
            <p class="stat-value">{{ stats.lowStockItems }}</p>
          </div>
        </div>
      </div>
      
      <div class="charts-grid">
        <div class="card">
          <h3>Recent Activity</h3>
          <div class="activity-list">
            <div class="activity-item" *ngFor="let activity of recentActivity">
              <span class="activity-icon">{{ activity.icon }}</span>
              <div class="activity-content">
                <p class="activity-title">{{ activity.title }}</p>
                <p class="activity-time">{{ activity.time }}</p>
              </div>
            </div>
          </div>
        </div>
        
        <div class="card">
          <h3>System Health</h3>
          <div class="health-list">
            <div class="health-item" *ngFor="let service of systemHealth">
              <span class="health-name">{{ service.name }}</span>
              <span class="health-status" [class.healthy]="service.healthy" [class.unhealthy]="!service.healthy">
                {{ service.healthy ? '✓ Healthy' : '✗ Down' }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .dashboard {
      padding: 20px;
    }
    
    h1 {
      margin-bottom: 30px;
    }
    
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 20px;
      margin-bottom: 30px;
    }
    
    .stat-card {
      background: white;
      border-radius: 8px;
      padding: 20px;
      display: flex;
      gap: 15px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    
    .stat-icon {
      font-size: 40px;
    }
    
    .stat-content h3 {
      margin: 0 0 10px 0;
      font-size: 14px;
      color: #666;
    }
    
    .stat-value {
      font-size: 32px;
      font-weight: bold;
      color: #1976d2;
      margin: 0;
    }
    
    .charts-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
      gap: 20px;
    }
    
    .card {
      background: white;
      border-radius: 8px;
      padding: 20px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    
    .card h3 {
      margin-top: 0;
      margin-bottom: 20px;
    }
    
    .activity-list {
      display: flex;
      flex-direction: column;
      gap: 15px;
    }
    
    .activity-item {
      display: flex;
      gap: 15px;
      padding: 10px;
      border-radius: 4px;
      background-color: #f8f9fa;
    }
    
    .activity-icon {
      font-size: 24px;
    }
    
    .activity-title {
      margin: 0 0 5px 0;
      font-weight: 500;
    }
    
    .activity-time {
      margin: 0;
      font-size: 12px;
      color: #666;
    }
    
    .health-list {
      display: flex;
      flex-direction: column;
      gap: 10px;
    }
    
    .health-item {
      display: flex;
      justify-content: space-between;
      padding: 10px;
      border-radius: 4px;
      background-color: #f8f9fa;
    }
    
    .health-status {
      font-weight: 500;
    }
    
    .health-status.healthy {
      color: #28a745;
    }
    
    .health-status.unhealthy {
      color: #dc3545;
    }
  `]
})
export class DashboardComponent implements OnInit {
  stats = {
    totalOrders: 0,
    confirmedOrders: 0,
    totalProducts: 0,
    lowStockItems: 0
  };

  recentActivity = [
    { icon: '📦', title: 'New order created', time: '2 minutes ago' },
    { icon: '✅', title: 'Order confirmed', time: '15 minutes ago' },
    { icon: '📋', title: 'Product added to inventory', time: '1 hour ago' },
    { icon: '⚠️', title: 'Low stock alert', time: '2 hours ago' }
  ];

  systemHealth = [
    { name: 'Orders API', healthy: true },
    { name: 'Inventory API', healthy: true },
    { name: 'Notifications API', healthy: true },
    { name: 'Audit API', healthy: true },
    { name: 'RabbitMQ', healthy: true },
    { name: 'PostgreSQL', healthy: true }
  ];

  constructor(private apiService: AdminApiService) {}

  ngOnInit() {
    this.loadStats();
  }

  loadStats() {
    // In a real app, load stats from API
    this.stats = {
      totalOrders: 156,
      confirmedOrders: 98,
      totalProducts: 45,
      lowStockItems: 7
    };
  }
}

