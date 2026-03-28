# Forms Patterns

## Signal Forms (Angular v21+ — Experimental, Recommended for New Code)

Signal Forms provide automatic two-way binding, schema-based validation, and reactive field state.

### Basic Setup

```typescript
import { Component, signal } from '@angular/core';
import { form, FormField, required, email } from '@angular/forms/signals';

interface LoginData {
  email: string;
  password: string;
}

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FormField],
  templateUrl: './login.component.html',
})
export class LoginComponent {
  loginModel = signal<LoginData>({
    email: '',
    password: '',
  });

  loginForm = form(this.loginModel, (schemaPath) => {
    required(schemaPath.email, { message: 'Email is required' });
    email(schemaPath.email, { message: 'Enter a valid email address' });
    required(schemaPath.password, { message: 'Password is required' });
  });

  onSubmit(event: Event) {
    event.preventDefault();
    if (this.loginForm().valid()) {
      const credentials = this.loginModel();
      console.log('Submitting:', credentials);
    }
  }
}
```

```html
<!-- login.component.html -->
<form (submit)="onSubmit($event)">
  <label>
    Email
    <input type="email" [formField]="loginForm.email" />
  </label>
  @if (loginForm.email().touched() && loginForm.email().invalid()) {
    <p class="error">{{ loginForm.email().errors()[0].message }}</p>
  }

  <label>
    Password
    <input type="password" [formField]="loginForm.password" />
  </label>
  @if (loginForm.password().touched() && loginForm.password().invalid()) {
    <p class="error">{{ loginForm.password().errors()[0].message }}</p>
  }

  <button type="submit" [disabled]="loginForm().invalid()">Login</button>
</form>
```

### Form Models

Form models are writable signals — the single source of truth:

```typescript
interface UserProfile {
  name: string;
  email: string;
  age: number | null;
  preferences: {
    newsletter: boolean;
    theme: 'light' | 'dark';
  };
}

const userModel = signal<UserProfile>({
  name: '',
  email: '',
  age: null,
  preferences: { newsletter: false, theme: 'light' },
});

const userForm = form(userModel);

// Access nested fields
userForm.name                    // FieldTree<string>
userForm.preferences.theme       // FieldTree<'light' | 'dark'>

// Read field value
const name = userForm.name().value();

// Update single field
userForm.name().value.set('Bob');
userForm.age().value.update(age => (age ?? 0) + 1);
```

### Field State

```typescript
const emailField = this.form.email();

// Validation
emailField.valid()      // true if passes all validation
emailField.invalid()    // true if has validation errors
emailField.errors()     // array of error objects
emailField.pending()    // true if async validation in progress

// Interaction
emailField.touched()    // true after focus + blur
emailField.dirty()      // true after user modification

// Availability
emailField.disabled()   // true if disabled
emailField.hidden()     // true if hidden
emailField.readonly()   // true if readonly

// Value
emailField.value()      // current field value (signal)
```

### Form-Level State

```typescript
this.form().valid()     // all interactive fields valid
this.form().touched()   // any field touched
this.form().dirty()     // any field modified
```

### Built-in Validators

```typescript
import {
  form, required, email, min, max,
  minLength, maxLength, pattern
} from '@angular/forms/signals';

const userForm = form(this.userModel, (schemaPath) => {
  required(schemaPath.name, { message: 'Name is required' });
  email(schemaPath.email, { message: 'Invalid email' });
  min(schemaPath.age, 18, { message: 'Must be 18+' });
  max(schemaPath.age, 120, { message: 'Invalid age' });
  minLength(schemaPath.password, 8, { message: 'Min 8 characters' });
  maxLength(schemaPath.bio, 500, { message: 'Max 500 characters' });
  pattern(schemaPath.phone, /^\d{3}-\d{3}-\d{4}$/, { message: 'Format: 555-123-4567' });
});
```

### Custom Validators

```typescript
import { validate } from '@angular/forms/signals';

const signupForm = form(this.signupModel, (schemaPath) => {
  validate(schemaPath.username, ({ value }) => {
    if (value().includes(' ')) {
      return { kind: 'noSpaces', message: 'Username cannot contain spaces' };
    }
    return null;
  });
});
```

### Cross-Field Validation

```typescript
const passwordForm = form(this.passwordModel, (schemaPath) => {
  required(schemaPath.password);
  required(schemaPath.confirmPassword);

  validate(schemaPath.confirmPassword, ({ value, valueOf }) => {
    if (value() !== valueOf(schemaPath.password)) {
      return { kind: 'mismatch', message: 'Passwords do not match' };
    }
    return null;
  });
});
```

### Conditional Validation

```typescript
const orderForm = form(this.orderModel, (schemaPath) => {
  required(schemaPath.promoCode, {
    message: 'Promo code required for discounts',
    when: ({ valueOf }) => valueOf(schemaPath.applyDiscount),
  });
});
```

### Async Validation

```typescript
import { validateHttp } from '@angular/forms/signals';

const signupForm = form(this.signupModel, (schemaPath) => {
  validateHttp(schemaPath.username, {
    request: ({ value }) => `/api/check-username?u=${value()}`,
    onSuccess: (response: { taken: boolean }) => {
      if (response.taken) {
        return { kind: 'taken', message: 'Username already taken' };
      }
      return null;
    },
    onError: () => ({
      kind: 'networkError',
      message: 'Could not verify username',
    }),
  });
});
```

### Conditional Fields (Hidden, Disabled, Readonly)

```typescript
import { hidden, disabled, readonly } from '@angular/forms/signals';

const profileForm = form(this.profileModel, (schemaPath) => {
  hidden(schemaPath.publicUrl, ({ valueOf }) => !valueOf(schemaPath.isPublic));
  disabled(schemaPath.couponCode, ({ valueOf }) => valueOf(schemaPath.total) < 50);
  readonly(schemaPath.username);
});
```

```html
@if (!profileForm.publicUrl().hidden()) {
  <input [formField]="profileForm.publicUrl" />
}
```

### Form Submission

```typescript
import { submit } from '@angular/forms/signals';

onSubmit(event: Event) {
  event.preventDefault();
  // submit() marks all fields touched and runs callback if valid
  submit(this.form, async () => {
    await this.productService.create(this.model());
  });
}
```

### Arrays and Dynamic Fields

```typescript
interface Order {
  items: Array<{ product: string; quantity: number }>;
}

@Component({
  standalone: true,
  imports: [FormField],
  templateUrl: './order-form.component.html',
})
export class OrderFormComponent {
  orderModel = signal<Order>({
    items: [{ product: '', quantity: 1 }],
  });

  orderForm = form(this.orderModel, (schemaPath) => {
    applyEach(schemaPath.items, (item) => {
      required(item.product, { message: 'Product required' });
      min(item.quantity, 1, { message: 'Min quantity is 1' });
    });
  });

  addItem() {
    this.orderModel.update(m => ({
      ...m,
      items: [...m.items, { product: '', quantity: 1 }],
    }));
  }

  removeItem(index: number) {
    this.orderModel.update(m => ({
      ...m,
      items: m.items.filter((_, i) => i !== index),
    }));
  }
}
```

```html
<!-- order-form.component.html -->
@for (item of orderForm.items; track $index; let i = $index) {
  <div>
    <input [formField]="item.product" placeholder="Product" />
    <input [formField]="item.quantity" type="number" />
    <button type="button" (click)="removeItem(i)">Remove</button>
  </div>
}
<button type="button" (click)="addItem()">Add Item</button>
```

### FormValueControl — Custom Form Controls for Signal Forms

Implement `FormValueControl<T>` to create custom controls compatible with `[formField]`:

```typescript
import { form, FormField, FormValueControl, ValidationError, WithOptionalField } from '@angular/forms/signals';

@Component({
  selector: 'app-star-rating',
  standalone: true,
  templateUrl: './star-rating.component.html',
})
export class StarRatingComponent implements FormValueControl<number> {
  // Required: two-way bound value
  readonly value = model<number>(0);

  // Optional: state bindings from form
  readonly readonly = input<boolean>(false);
  readonly invalid = input<boolean>(false);
  readonly errors: InputSignal<readonly WithOptionalField<ValidationError>[]> = input<
    readonly WithOptionalField<ValidationError>[]
  >([]);

  readonly stars = [1, 2, 3, 4, 5];

  rate(index: number): void {
    if (!this.readonly()) {
      this.value.set(index);
    }
  }
}
```

```html
<!-- star-rating.component.html -->
<div class="star-rating">
  @for (star of stars; track $index) {
    <span
      (click)="rate(star)"
      [class.filled]="star <= value()"
      [class.readonly]="readonly()"
      [class.error]="invalid()"
    >
      {{ star <= value() ? '★' : '☆' }}
    </span>
  }
  @if (errors().at(0)?.message) {
    <p class="error">{{ errors().at(0)?.message }}</p>
  }
</div>
```

```typescript
// Usage with Signal Forms
@Component({
  standalone: true,
  imports: [FormField, StarRatingComponent],
  templateUrl: './review-form.component.html',
})
export class ReviewFormComponent {
  readonly reviewModel = signal<{ rating: number }>({ rating: 0 });
  readonly reviewForm = form(this.reviewModel);
}
```

```html
<!-- review-form.component.html -->
<form (submit)="submit($event)">
  <app-star-rating [formField]="reviewForm.rating" />
  {{ reviewForm.rating().value() }}
</form>
```

### Reset Form

```typescript
async onSubmit() {
  if (!this.form().valid()) return;

  await this.api.submit(this.model());
  this.form().reset();                              // Clear interaction state
  this.model.set({ email: '', password: '' });      // Clear values
}
```

---

## Reactive Forms (Production-Stable)

For features requiring proven stability, use Reactive Forms with `NonNullableFormBuilder`.

### Form Component with Typed FormGroup

```typescript
import { Component, inject, output } from '@angular/core';
import { NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';

@Component({
  selector: 'app-product-form',
  standalone: true,
  imports: [
    ReactiveFormsModule,
  ],
  templateUrl: './product-form.component.html',
  styleUrl: './product-form.component.scss',
})
export class ProductFormComponent {
  private readonly fb = inject(NonNullableFormBuilder);

  readonly submitted = output<Product>();

  readonly form = this.fb.group({
    name: ['', [Validators.required, Validators.minLength(3)]],
    description: ['', [Validators.required, Validators.maxLength(500)]],
    price: [0, [Validators.required, Validators.min(0.01)]],
    category: ['', [Validators.required]],
  });

  onSubmit() {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.submitted.emit(this.form.getRawValue() as Product);
  }
}
```

### Template with Reactive Forms

```html
<form [formGroup]="form" (ngSubmit)="onSubmit()">
  <label>
    Product Name
    <input formControlName="name" />
  </label>

  <label>
    Description
    <textarea formControlName="description"></textarea>
  </label>

  <label>
    Price
    <input formControlName="price" type="number" />
  </label>

  <button type="submit">Save Product</button>
</form>
```

### Custom Validators

```typescript
import { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';

export function minPrice(min: number): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const value = control.value;
    if (value !== null && value !== undefined && value < min) {
      return { minPrice: { requiredMin: min, actual: value } };
    }
    return null;
  };
}

export function noWhitespace(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    if (typeof control.value === 'string' && control.value.trim().length === 0) {
      return { whitespace: true };
    }
    return null;
  };
}

export function matchField(fieldName: string): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const parent = control.parent;
    if (!parent) return null;
    const matchControl = parent.get(fieldName);
    if (!matchControl) return null;
    if (control.value !== matchControl.value) {
      return { matchField: { field: fieldName } };
    }
    return null;
  };
}
```

### Nested Form Groups

```typescript
readonly form = this.fb.group({
  name: ['', Validators.required],
  address: this.fb.group({
    street: ['', Validators.required],
    city: ['', Validators.required],
    zipCode: ['', [Validators.required, Validators.pattern(/^\d{4}\s?[A-Z]{2}$/)]],
  }),
});
```

### Dynamic Forms with FormArray

```typescript
@Component({
  standalone: true,
  imports: [ReactiveFormsModule],
  templateUrl: './order-form.component.html',
})
export class OrderFormComponent {
  private readonly fb = inject(NonNullableFormBuilder);

  readonly form = this.fb.group({
    items: this.fb.array([this.createItem()]),
  });

  get items() {
    return this.form.controls.items;
  }

  createItem() {
    return this.fb.group({
      product: ['', Validators.required],
      quantity: [1, [Validators.required, Validators.min(1)]],
    });
  }

  addItem() {
    this.items.push(this.createItem());
  }

  removeItem(index: number) {
    this.items.removeAt(index);
  }
}
```

```html
<!-- order-form.component.html (Reactive Forms variant) -->
<form [formGroup]="form">
  <div formArrayName="items">
    @for (item of items.controls; track $index; let i = $index) {
      <div [formGroupName]="i">
        <input formControlName="product" placeholder="Product" />
        <input formControlName="quantity" type="number" />
        <button type="button" (click)="removeItem(i)">Remove</button>
      </div>
    }
  </div>
  <button type="button" (click)="addItem()">Add Item</button>
</form>
```

## When to Use What

| Scenario | Solution |
| -------- | -------- |
| New features, simple forms | Signal Forms |
| Complex forms needing proven stability | Reactive Forms |
| Custom form controls for Signal Forms | `FormValueControl<T>` |
| Dynamic arrays | Signal Forms `applyEach` or Reactive Forms `FormArray` |
| Cross-field validation | Both support it — use what the form already uses |
| Async server-side validation | Signal Forms `validateHttp` or Reactive Forms `AsyncValidatorFn` |

## Quick Reference — Signal Forms

| API | Purpose |
| --- | ------- |
| `form(model, schema?)` | Create a signal form from a model signal |
| `required(field, opts?)` | Field must have a value |
| `email(field, opts?)` | Email format validation |
| `min(field, n, opts?)` / `max(field, n, opts?)` | Numeric range |
| `minLength(field, n, opts?)` / `maxLength(field, n, opts?)` | String length |
| `pattern(field, regex, opts?)` | Regex validation |
| `validate(field, fn)` | Custom validator function |
| `validateHttp(field, opts)` | Async HTTP validation |
| `hidden(field, fn)` / `disabled(field, fn)` / `readonly(field)` | Field availability |
| `submit(form, callback)` | Mark all touched, run callback if valid |
| `applyEach(arrayPath, fn)` | Validate items in an array |
| `FormValueControl<T>` | Interface for custom form controls |

## Quick Reference — Reactive Forms

| Pattern | When to Use |
| ------- | ----------- |
| `NonNullableFormBuilder` | Always — ensures typed, non-nullable controls |
| `fb.group({...})` | Create a typed form group |
| `fb.array([...])` | Dynamic list of form controls |
| Custom `ValidatorFn` | Domain-specific validation rules |
| `form.markAllAsTouched()` | Show all validation errors on submit |
| `form.getRawValue()` | Get typed form value including disabled fields |
| `form.controls.x.errors` | Access validation errors for display |
