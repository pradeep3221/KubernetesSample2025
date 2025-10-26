import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { FormBuilder, FormGroup, FormArray, Validators } from '@angular/forms';
import { ApiService } from '../../services/api.service';

@Component({
  selector: 'app-create-order',
  template: `
    <div class="create-order">
      <h1>Create New Order</h1>
      
      <form [formGroup]="orderForm" (ngSubmit)="submitOrder()" class="card">
        <h3>Order Items</h3>
        
        <div formArrayName="items">
          <div *ngFor="let item of items.controls; let i = index" [formGroupName]="i" class="order-item">
            <div class="form-group">
              <label>Product Name</label>
              <input type="text" formControlName="productName" class="form-control">
            </div>
            
            <div class="form-group">
              <label>Quantity</label>
              <input type="number" formControlName="quantity" class="form-control" min="1">
            </div>
            
            <div class="form-group">
              <label>Unit Price</label>
              <input type="number" formControlName="unitPrice" class="form-control" min="0" step="0.01">
            </div>
            
            <button type="button" class="btn btn-danger btn-sm" (click)="removeItem(i)" *ngIf="items.length > 1">
              Remove
            </button>
          </div>
        </div>
        
        <button type="button" class="btn btn-secondary" (click)="addItem()">Add Item</button>
        
        <div class="total-section">
          <h3>Total: \${{ calculateTotal().toFixed(2) }}</h3>
        </div>
        
        <div class="form-actions">
          <button type="submit" class="btn btn-primary" [disabled]="!orderForm.valid || submitting">
            {{ submitting ? 'Creating...' : 'Create Order' }}
          </button>
          <button type="button" class="btn btn-secondary" routerLink="/orders">Cancel</button>
        </div>
      </form>
    </div>
  `,
  styles: [`
    .create-order {
      padding: 20px 0;
    }
    
    .order-item {
      display: grid;
      grid-template-columns: 2fr 1fr 1fr auto;
      gap: 15px;
      align-items: end;
      margin-bottom: 15px;
      padding: 15px;
      background-color: #f8f9fa;
      border-radius: 4px;
    }
    
    .total-section {
      margin: 30px 0;
      padding: 20px;
      background-color: #f8f9fa;
      border-radius: 4px;
      text-align: right;
    }
    
    .form-actions {
      display: flex;
      gap: 15px;
      justify-content: flex-end;
      margin-top: 20px;
    }
    
    .btn-sm {
      padding: 6px 12px;
      font-size: 12px;
    }
  `]
})
export class CreateOrderComponent implements OnInit {
  orderForm: FormGroup;
  submitting = false;

  constructor(
    private fb: FormBuilder,
    private apiService: ApiService,
    private router: Router
  ) {
    this.orderForm = this.fb.group({
      items: this.fb.array([this.createItem()])
    });
  }

  ngOnInit() {}

  get items(): FormArray {
    return this.orderForm.get('items') as FormArray;
  }

  createItem(): FormGroup {
    return this.fb.group({
      productId: ['00000000-0000-0000-0000-000000000000'],
      productName: ['', Validators.required],
      quantity: [1, [Validators.required, Validators.min(1)]],
      unitPrice: [0, [Validators.required, Validators.min(0)]]
    });
  }

  addItem() {
    this.items.push(this.createItem());
  }

  removeItem(index: number) {
    this.items.removeAt(index);
  }

  calculateTotal(): number {
    return this.items.controls.reduce((total, item) => {
      const quantity = item.get('quantity')?.value || 0;
      const unitPrice = item.get('unitPrice')?.value || 0;
      return total + (quantity * unitPrice);
    }, 0);
  }

  async submitOrder() {
    if (this.orderForm.valid) {
      this.submitting = true;
      
      const order = {
        customerId: '00000000-0000-0000-0000-000000000000', // This should come from the logged-in user
        items: this.items.value
      };

      try {
        const observable = await this.apiService.createOrder(order);
        observable.subscribe({
          next: (response) => {
            alert('Order created successfully!');
            this.router.navigate(['/orders', response.id]);
          },
          error: (error) => {
            console.error('Error creating order:', error);
            alert('Failed to create order');
            this.submitting = false;
          }
        });
      } catch (error) {
        console.error('Error:', error);
        alert('Failed to create order');
        this.submitting = false;
      }
    }
  }
}

