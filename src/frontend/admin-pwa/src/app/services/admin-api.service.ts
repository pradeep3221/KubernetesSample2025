import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AdminApiService {
  private apiUrl = 'http://localhost:5000'; // API Gateway URL

  constructor(private http: HttpClient) {}

  // Orders
  getAllOrders(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/orders`);
  }

  getOrder(id: string): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/orders/${id}`);
  }

  confirmOrder(id: string): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/orders/${id}/confirm`, {});
  }

  shipOrder(id: string, trackingNumber: string): Observable<any> {
    return this.http.post<any>(
      `${this.apiUrl}/orders/${id}/ship`,
      { trackingNumber }
    );
  }

  cancelOrder(id: string, reason: string): Observable<any> {
    return this.http.post<any>(
      `${this.apiUrl}/orders/${id}/cancel`,
      { reason }
    );
  }

  // Inventory
  getAllProducts(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/inventory/products`);
  }

  getProduct(id: string): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/inventory/products/${id}`);
  }

  createProduct(product: any): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/inventory/products`, product);
  }

  updateProduct(id: string, product: any): Observable<any> {
    return this.http.put<any>(`${this.apiUrl}/inventory/products/${id}`, product);
  }

  deleteProduct(id: string): Observable<any> {
    return this.http.delete<any>(`${this.apiUrl}/inventory/products/${id}`);
  }

  adjustInventory(id: string, quantityChange: number, reason: string): Observable<any> {
    return this.http.post<any>(
      `${this.apiUrl}/inventory/products/${id}/adjust`,
      { quantityChange, reason }
    );
  }

  // Audit
  getAuditLogs(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/audit/documents`);
  }

  getAuditLogsByEntity(entity: string): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/audit/documents/${entity}`);
  }

  getEventStream(streamId: string): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/audit/events/${streamId}`);
  }

  // Notifications
  getNotifications(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/notifications`);
  }

  sendNotification(notification: any): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/notifications`, notification);
  }
}

