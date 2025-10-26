import { Component, OnInit } from '@angular/core';
import { KeycloakService } from 'keycloak-angular';

@Component({
  selector: 'app-navbar',
  template: `
    <nav class="navbar">
      <div class="navbar-brand">
        <h1>🛡️ Admin Console</h1>
      </div>
      <div class="navbar-actions">
        <span class="user-info">
          <span class="user-name">{{ userName }}</span>
          <span class="user-role">{{ userRole }}</span>
        </span>
        <button class="btn btn-secondary" (click)="logout()">Logout</button>
      </div>
    </nav>
  `,
  styles: [`
    .navbar {
      background-color: #1976d2;
      color: white;
      padding: 15px 30px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    
    .navbar-brand h1 {
      margin: 0;
      font-size: 24px;
    }
    
    .navbar-actions {
      display: flex;
      gap: 20px;
      align-items: center;
    }
    
    .user-info {
      display: flex;
      flex-direction: column;
      align-items: flex-end;
    }
    
    .user-name {
      font-weight: 600;
    }
    
    .user-role {
      font-size: 12px;
      opacity: 0.8;
    }
    
    .btn {
      padding: 8px 16px;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      background-color: rgba(255,255,255,0.2);
      color: white;
      transition: background-color 0.3s;
    }
    
    .btn:hover {
      background-color: rgba(255,255,255,0.3);
    }
  `]
})
export class NavbarComponent implements OnInit {
  userName = '';
  userRole = '';

  constructor(private keycloak: KeycloakService) {}

  async ngOnInit() {
    const profile = await this.keycloak.loadUserProfile();
    this.userName = profile.firstName || profile.username || 'Admin';
    this.userRole = 'Administrator';
  }

  logout() {
    this.keycloak.logout(window.location.origin);
  }
}

