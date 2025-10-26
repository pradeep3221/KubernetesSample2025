import { Component } from '@angular/core';

@Component({
  selector: 'app-home',
  template: `
    <div class="home">
      <div class="hero">
        <h1>Welcome to Customer Portal</h1>
        <p>Browse products and manage your orders</p>
        <div class="hero-actions">
          <button class="btn btn-primary" routerLink="/products">Browse Products</button>
          <button class="btn btn-secondary" routerLink="/orders">My Orders</button>
        </div>
      </div>
      
      <div class="features">
        <div class="feature-card">
          <h3>🛍️ Shop Products</h3>
          <p>Browse our wide selection of products</p>
        </div>
        <div class="feature-card">
          <h3>📦 Track Orders</h3>
          <p>Monitor your order status in real-time</p>
        </div>
        <div class="feature-card">
          <h3>🔒 Secure Checkout</h3>
          <p>Safe and secure payment processing</p>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .home {
      padding: 40px 0;
    }
    
    .hero {
      text-align: center;
      padding: 60px 20px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      border-radius: 12px;
      margin-bottom: 40px;
    }
    
    .hero h1 {
      font-size: 48px;
      margin-bottom: 20px;
    }
    
    .hero p {
      font-size: 20px;
      margin-bottom: 30px;
    }
    
    .hero-actions {
      display: flex;
      gap: 15px;
      justify-content: center;
    }
    
    .features {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 30px;
    }
    
    .feature-card {
      background: white;
      padding: 30px;
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      text-align: center;
    }
    
    .feature-card h3 {
      font-size: 24px;
      margin-bottom: 15px;
    }
    
    .feature-card p {
      color: #666;
    }
  `]
})
export class HomeComponent {}

