import { Component, OnInit } from '@angular/core';
import { AdminApiService } from '../../services/admin-api.service';

@Component({
  selector: 'app-audit-logs',
  template: `
    <div class="audit-logs">
      <h1>Audit Logs</h1>
      
      <div class="filters card">
        <select [(ngModel)]="entityFilter" (change)="applyFilters()">
          <option value="">All Entities</option>
          <option value="Order">Order</option>
          <option value="Inventory">Inventory</option>
          <option value="Notification">Notification</option>
        </select>
        
        <select [(ngModel)]="actionFilter" (change)="applyFilters()">
          <option value="">All Actions</option>
          <option value="Created">Created</option>
          <option value="Updated">Updated</option>
          <option value="Deleted">Deleted</option>
          <option value="Confirmed">Confirmed</option>
          <option value="Cancelled">Cancelled</option>
        </select>
        
        <input type="date" [(ngModel)]="dateFilter" (change)="applyFilters()">
      </div>
      
      <div *ngIf="loading" class="loading"></div>
      
      <div class="card" *ngIf="!loading">
        <table class="table">
          <thead>
            <tr>
              <th>Timestamp</th>
              <th>Entity</th>
              <th>Action</th>
              <th>User ID</th>
              <th>Details</th>
            </tr>
          </thead>
          <tbody>
            <tr *ngFor="let log of filteredLogs">
              <td>{{ log.timestamp | date:'short' }}</td>
              <td>
                <span class="entity-badge">{{ log.entity }}</span>
              </td>
              <td>
                <span class="action-badge" [class]="'action-' + log.action.toLowerCase()">
                  {{ log.action }}
                </span>
              </td>
              <td>{{ log.userId.substring(0, 8) }}...</td>
              <td>
                <button class="btn btn-sm btn-secondary" (click)="viewDetails(log)">
                  View
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      
      <!-- Details Modal -->
      <div class="modal" *ngIf="selectedLog">
        <div class="modal-content card">
          <h2>Audit Log Details</h2>
          <div class="detail-row">
            <span class="label">ID:</span>
            <span>{{ selectedLog.id }}</span>
          </div>
          <div class="detail-row">
            <span class="label">Timestamp:</span>
            <span>{{ selectedLog.timestamp | date:'full' }}</span>
          </div>
          <div class="detail-row">
            <span class="label">Entity:</span>
            <span>{{ selectedLog.entity }}</span>
          </div>
          <div class="detail-row">
            <span class="label">Action:</span>
            <span>{{ selectedLog.action }}</span>
          </div>
          <div class="detail-row">
            <span class="label">User ID:</span>
            <span>{{ selectedLog.userId }}</span>
          </div>
          <div class="detail-section">
            <h3>Payload</h3>
            <pre>{{ selectedLog.payload }}</pre>
          </div>
          <div class="detail-section" *ngIf="selectedLog.metadata">
            <h3>Metadata</h3>
            <pre>{{ selectedLog.metadata | json }}</pre>
          </div>
          <div class="modal-actions">
            <button class="btn btn-secondary" (click)="selectedLog = null">Close</button>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .audit-logs {
      padding: 20px;
    }
    
    .filters {
      display: flex;
      gap: 15px;
      margin-bottom: 20px;
      padding: 15px;
    }
    
    .filters select,
    .filters input {
      padding: 8px 12px;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-size: 14px;
    }
    
    .entity-badge {
      padding: 4px 12px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 500;
      background-color: #e3f2fd;
      color: #1976d2;
    }
    
    .action-badge {
      padding: 4px 12px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 500;
    }
    
    .action-created {
      background-color: #d4edda;
      color: #155724;
    }
    
    .action-updated {
      background-color: #d1ecf1;
      color: #0c5460;
    }
    
    .action-deleted,
    .action-cancelled {
      background-color: #f8d7da;
      color: #721c24;
    }
    
    .action-confirmed {
      background-color: #d4edda;
      color: #155724;
    }
    
    .btn-sm {
      padding: 4px 8px;
      font-size: 12px;
    }
    
    .modal {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background-color: rgba(0,0,0,0.5);
      display: flex;
      justify-content: center;
      align-items: center;
      z-index: 1000;
    }
    
    .modal-content {
      max-width: 600px;
      width: 100%;
      max-height: 90vh;
      overflow-y: auto;
    }
    
    .detail-row {
      display: flex;
      justify-content: space-between;
      padding: 10px 0;
      border-bottom: 1px solid #eee;
    }
    
    .label {
      font-weight: 600;
      color: #666;
    }
    
    .detail-section {
      margin-top: 20px;
    }
    
    .detail-section h3 {
      margin-bottom: 10px;
    }
    
    pre {
      background-color: #f8f9fa;
      padding: 15px;
      border-radius: 4px;
      overflow-x: auto;
    }
    
    .modal-actions {
      display: flex;
      justify-content: flex-end;
      margin-top: 20px;
    }
  `]
})
export class AuditLogsComponent implements OnInit {
  logs: any[] = [];
  filteredLogs: any[] = [];
  loading = true;
  entityFilter = '';
  actionFilter = '';
  dateFilter = '';
  selectedLog: any = null;

  constructor(private apiService: AdminApiService) {}

  async ngOnInit() {
    await this.loadLogs();
  }

  async loadLogs() {
    try {
      const observable = await this.apiService.getAuditLogs();
      observable.subscribe({
        next: (data) => {
          this.logs = data;
          this.filteredLogs = data;
          this.loading = false;
        },
        error: (error) => {
          console.error('Error loading audit logs:', error);
          this.loading = false;
        }
      });
    } catch (error) {
      console.error('Error:', error);
      this.loading = false;
    }
  }

  applyFilters() {
    this.filteredLogs = this.logs.filter(log => {
      const matchesEntity = !this.entityFilter || log.entity === this.entityFilter;
      const matchesAction = !this.actionFilter || log.action === this.actionFilter;
      const matchesDate = !this.dateFilter || 
        new Date(log.timestamp).toDateString() === new Date(this.dateFilter).toDateString();
      return matchesEntity && matchesAction && matchesDate;
    });
  }

  viewDetails(log: any) {
    this.selectedLog = log;
  }
}

