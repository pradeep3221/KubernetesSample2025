import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { KeycloakService } from 'keycloak-angular';

@Injectable({
  providedIn: 'root'
})
export class AdminApiService {
  private apiUrl = 'http://localhost:5000'; // API Gateway URL

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

  // Orders
  async getAllOrders(): Promise<Observable<any[]>> {
    const headers = await this.getHeaders();
    return this.http.get<any[]>(`${this.apiUrl}/orders`, { headers });
  }

  async getOrder(id: string): Promise<Observable<any>> {
    const headers = await this.getHeaders();
    return this.http.get<any>(`${this.apiUrl}/orders/${id}`, { headers });
  }

  async confirmOrder(id: string): Promise<Observable<any>> {
    const headers = await this.getHeaders();
    return this.http.post<any>(`${this.apiUrl}/orders/${id}/confirm`, {}, { headers });
  }

  async shipOrder(id: string, trackingNumber: string): Promise<Observable<any>> {
    const headers = await this.getHeaders();
    return this.http.post<any>(
      `${this.apiUrl}/orders/${id}/ship`,
      { trackingNumber },
      { headers }
    );
  }

  async cancelOrder(id: string, reason: string): Promise<Observable<any>> {
    const headers = await this.getHeaders();
    return this.http.post<any>(
      `${this.apiUrl}/orders/${id}/cancel`,
      { reason },
      { headers }
    );
  }

  // Inventory
  getAllProducts(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/inventory/products`);
  }

  async getProduct(id: string): Promise<Observable<any>> {
    const headers = await this.getHeaders();
    return this.http.get<any>(`${this.apiUrl}/inventory/products/${id}`, { headers });
  }

  async createProduct(product: any): Promise<Observable<any>> {
    const headers = await this.getHeaders();
    return this.http.post<any>(`${this.apiUrl}/inventory/products`, product, { headers });
  }

  async updateProduct(id: string, product: any): Promise<Observable<any>> {
    const headers = await this.getHeaders();
    return this.http.put<any>(`${this.apiUrl}/inventory/products/${id}`, product, { headers });
  }

  async adjustInventory(id: string, quantityChange: number, reason: string): Promise<Observable<any>> {
    const headers = await this.getHeaders();
    return this.http.post<any>(
      `${this.apiUrl}/inventory/products/${id}/adjust`,
      { quantityChange, reason },
      { headers }
    );
  }

  // Audit
  async getAuditLogs(): Promise<Observable<any[]>> {
    const headers = await this.getHeaders();
    return this.http.get<any[]>(`${this.apiUrl}/audit/documents`, { headers });
  }

  async getAuditLogsByEntity(entity: string): Promise<Observable<any[]>> {
    const headers = await this.getHeaders();
    return this.http.get<any[]>(`${this.apiUrl}/audit/documents/${entity}`, { headers });
  }

  async getEventStream(streamId: string): Promise<Observable<any[]>> {
    const headers = await this.getHeaders();
    return this.http.get<any[]>(`${this.apiUrl}/audit/events/${streamId}`, { headers });
  }
}

