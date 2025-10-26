import { Component } from '@angular/core';

@Component({
  selector: 'app-sidebar',
  template: `
    <aside class="sidebar">
      <nav class="sidebar-nav">
        <a routerLink="/dashboard" routerLinkActive="active" class="nav-item">
          <span class="icon">📊</span>
          <span>Dashboard</span>
        </a>
        <a routerLink="/orders" routerLinkActive="active" class="nav-item">
          <span class="icon">📦</span>
          <span>Orders</span>
        </a>
        <a routerLink="/inventory" routerLinkActive="active" class="nav-item">
          <span class="icon">📋</span>
          <span>Inventory</span>
        </a>
        <a routerLink="/audit" routerLinkActive="active" class="nav-item">
          <span class="icon">🔍</span>
          <span>Audit Logs</span>
        </a>
      </nav>
    </aside>
  `,
  styles: [`
    .sidebar {
      width: 250px;
      background-color: #2c3e50;
      color: white;
      padding: 20px 0;
    }
    
    .sidebar-nav {
      display: flex;
      flex-direction: column;
    }
    
    .nav-item {
      display: flex;
      align-items: center;
      gap: 15px;
      padding: 15px 25px;
      color: white;
      text-decoration: none;
      transition: background-color 0.3s;
    }
    
    .nav-item:hover {
      background-color: rgba(255,255,255,0.1);
    }
    
    .nav-item.active {
      background-color: #1976d2;
      border-left: 4px solid #fff;
    }
    
    .icon {
      font-size: 20px;
    }
  `]
})
export class SidebarComponent {}

