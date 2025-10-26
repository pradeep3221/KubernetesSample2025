import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { KeycloakService } from 'keycloak-angular';

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private apiUrl = 'http://localhost:5000; // API Gateway URL

  constructor(
    private http: HttpClient,
    private keycloak: KeycloakService
  ) {}

  private async getHeaders(): Promise<HttpHeaders> {
    const token = await this.keycloak.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    });
  }

  // Products
  getProducts(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/inventory/products`);
  }

  getProduct(id: string): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/inventory/products/${id}`);
  }

  // Orders
  async getOrders(): Promise<Observable<any[]>> {
    const headers = await this.getHeaders();
    return this.http.get<any[]>(`${this.apiUrl}/orders`, { headers });
  }

  async getOrder(id: string): Promise<Observable<any>> {
    const headers = await this.getHeaders();
    return this.http.get<any>(`${this.apiUrl}/orders/${id}`, { headers });
  }

  async createOrder(order: any): Promise<Observable<any>> {
    const headers = await this.getHeaders();
    return this.http.post<any>(`${this.apiUrl}/orders`, order, { headers });
  }

  async cancelOrder(id: string, reason: string): Promise<Observable<any>> {
    const headers = await this.getHeaders();
    return this.http.post<any>(
      `${this.apiUrl}/orders/${id}/cancel`,
      { reason },
      { headers }
    );
  }
}

