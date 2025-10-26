import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuard } from './guards/auth.guard';
import { DashboardComponent } from './components/dashboard/dashboard.component';
import { OrderManagementComponent } from './components/order-management/order-management.component';
import { InventoryManagementComponent } from './components/inventory-management/inventory-management.component';
import { AuditLogsComponent } from './components/audit-logs/audit-logs.component';

const routes: Routes = [
  { path: '', redirectTo: '/dashboard', pathMatch: 'full' },
  { path: 'dashboard', component: DashboardComponent, canActivate: [AuthGuard] },
  { path: 'orders', component: OrderManagementComponent, canActivate: [AuthGuard] },
  { path: 'inventory', component: InventoryManagementComponent, canActivate: [AuthGuard] },
  { path: 'audit', component: AuditLogsComponent, canActivate: [AuthGuard] },
  { path: '**', redirectTo: '/dashboard' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }

