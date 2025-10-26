import { Injectable } from '@angular/core';
import {
  HttpRequest,
  HttpHandler,
  HttpEvent,
  HttpInterceptor,
  HttpErrorResponse
} from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { KeycloakService } from 'keycloak-angular';

@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  constructor(private keycloak: KeycloakService) {}

  intercept(request: HttpRequest<unknown>, next: HttpHandler): Observable<HttpEvent<unknown>> {
    // Skip adding token for certain URLs
    if (this.shouldSkipToken(request.url)) {
      return next.handle(request);
    }

    // Add token to request
    if (this.keycloak.isLoggedIn()) {
      const token = this.keycloak.getToken();
      if (token) {
        request = request.clone({
          setHeaders: {
            Authorization: `Bearer ${token}`
          }
        });
      }
    }

    return next.handle(request).pipe(
      catchError((error: HttpErrorResponse) => {
        if (error.status === 401) {
          // Token might be expired, try to refresh
          this.keycloak.logout();
        }
        return throwError(() => error);
      })
    );
  }

  private shouldSkipToken(url: string): boolean {
    // Don't add token to Keycloak URLs
    if (url.includes('keycloak') || url.includes('auth')) {
      return true;
    }
    return false;
  }
}

