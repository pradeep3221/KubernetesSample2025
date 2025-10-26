import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private apiUrl = 'http://localhost:5000'; // API Gateway URL

  constructor(private http: HttpClient) {}

  // Products
  getProducts(): Observable<any[]> {
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

  // Orders
  getOrders(): Observable<any[]> {
    return this.http.get<any[]>(`${this.apiUrl}/orders`);
  }

  getOrder(id: string): Observable<any> {
    return this.http.get<any>(`${this.apiUrl}/orders/${id}`);
  }

  createOrder(order: any): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/orders`, order);
  }

  confirmOrder(id: string): Observable<any> {
    return this.http.post<any>(`${this.apiUrl}/orders/${id}/confirm`, {});
  }

  cancelOrder(id: string, reason: string): Observable<any> {
    return this.http.post<any>(
      `${this.apiUrl}/orders/${id}/cancel`,
      { reason }
    );
  }

  shipOrder(id: string, trackingNumber: string): Observable<any> {
    return this.http.post<any>(
      `${this.apiUrl}/orders/${id}/ship`,
      { trackingNumber }
    );
  }
}

