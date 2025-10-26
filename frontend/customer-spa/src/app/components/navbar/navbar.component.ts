import { Component, OnInit } from '@angular/core';
import { KeycloakService } from 'keycloak-angular';

@Component({
  selector: 'app-navbar',
  template: `
    <nav class="navbar">
      <div class="navbar-brand">
        <a routerLink="/">Customer Portal</a>
      </div>
      <div class="navbar-menu">
        <a routerLink="/" routerLinkActive="active" [routerLinkActiveOptions]="{exact: true}">Home</a>
        <a routerLink="/products" routerLinkActive="active">Products</a>
        <a *ngIf="isLoggedIn" routerLink="/orders" routerLinkActive="active">My Orders</a>
      </div>
      <div class="navbar-actions">
        <span *ngIf="isLoggedIn" class="user-name">{{ userName }}</span>
        <button *ngIf="!isLoggedIn" class="btn btn-primary" (click)="login()">Login</button>
        <button *ngIf="isLoggedIn" class="btn btn-secondary" (click)="logout()">Logout</button>
      </div>
    </nav>
  `,
  styles: [`
    .navbar {
      background-color: #007bff;
      color: white;
      padding: 15px 30px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    
    .navbar-brand a {
      color: white;
      text-decoration: none;
      font-size: 24px;
      font-weight: bold;
    }
    
    .navbar-menu {
      display: flex;
      gap: 20px;
    }
    
    .navbar-menu a {
      color: white;
      text-decoration: none;
      padding: 8px 16px;
      border-radius: 4px;
      transition: background-color 0.3s;
    }
    
    .navbar-menu a:hover,
    .navbar-menu a.active {
      background-color: rgba(255,255,255,0.2);
    }
    
    .navbar-actions {
      display: flex;
      gap: 15px;
      align-items: center;
    }
    
    .user-name {
      font-weight: 500;
    }
  `]
})
export class NavbarComponent implements OnInit {
  isLoggedIn = false;
  userName = '';

  constructor(private keycloak: KeycloakService) {}

  async ngOnInit() {
    this.isLoggedIn = await this.keycloak.isLoggedIn();
    if (this.isLoggedIn) {
      const profile = await this.keycloak.loadUserProfile();
      this.userName = profile.firstName || profile.username || 'User';
    }
  }

  login() {
    this.keycloak.login();
  }

  logout() {
    this.keycloak.logout(window.location.origin);
  }
}

