# Spartan UI Component Patterns

Spartan UI is built on two layers:
- **Brain** (`@spartan-ng/brain/*`) — Unstyled, accessible primitives (headless)
- **Helm** (`@spartan-ng/helm/*`) — Styled directives using Tailwind CSS

Install components individually via: `ng g @spartan-ng/cli:ui <component-name>`

Icons use **ng-icons** with **Lucide** as the default icon set.

---

## Theming

Spartan uses **CSS custom properties** with **OKLCH** color format. Colors follow a `background` / `foreground` naming convention.

### Core CSS Variables

Define in `styles.css`:

```css
:root {
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);

  --primary: oklch(0.205 0 0);
  --primary-foreground: oklch(0.985 0 0);

  --secondary: oklch(0.97 0 0);
  --secondary-foreground: oklch(0.205 0 0);

  --destructive: oklch(0.577 0.245 27.325);
  --destructive-foreground: oklch(0.577 0.245 27.325);

  --muted: oklch(0.97 0 0);
  --muted-foreground: oklch(0.556 0 0);

  --accent: oklch(0.97 0 0);
  --accent-foreground: oklch(0.205 0 0);

  --card: oklch(1 0 0);
  --card-foreground: oklch(0.145 0 0);

  --popover: oklch(1 0 0);
  --popover-foreground: oklch(0.145 0 0);

  --border: oklch(0.922 0 0);
  --input: oklch(0.922 0 0);
  --ring: oklch(0.708 0 0);
  --radius: 0.625rem;

  --sidebar: oklch(0.985 0 0);
  --sidebar-foreground: oklch(0.145 0 0);
  --sidebar-primary: oklch(0.205 0 0);
  --sidebar-primary-foreground: oklch(0.985 0 0);
  --sidebar-accent: oklch(0.97 0 0);
  --sidebar-accent-foreground: oklch(0.205 0 0);
  --sidebar-border: oklch(0.922 0 0);
  --sidebar-ring: oklch(0.708 0 0);
}
```

### Preset Themes

Five base color schemes: **Neutral**, **Stone** (warm), **Zinc** (cool), **Gray**, **Slate** (blue-tinted).

### Custom Colors

```css
:root {
  --warning: oklch(0.84 0.16 84);
}
@theme inline {
  --color-warning: var(--warning);
}
```

Use via Tailwind: `class="bg-warning text-warning-foreground"`

---

## Dark Mode

Dark mode uses the `dark` CSS class on `<html>`. All Spartan components adapt automatically.

### CSS Variables for Dark Mode

```css
.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);

  --primary: oklch(0.985 0 0);
  --primary-foreground: oklch(0.205 0 0);

  --secondary: oklch(0.269 0 0);
  --secondary-foreground: oklch(0.985 0 0);

  --muted: oklch(0.269 0 0);
  --muted-foreground: oklch(0.708 0 0);

  --accent: oklch(0.269 0 0);
  --accent-foreground: oklch(0.985 0 0);

  --card: oklch(0.145 0 0);
  --card-foreground: oklch(0.985 0 0);

  --border: oklch(0.269 0 0);
  --input: oklch(0.269 0 0);
  --ring: oklch(0.439 0 0);
}
```

### Toggle Implementation

```typescript
// theme.service.ts
toggle(): void {
  const html = document.documentElement;
  const isDark = html.classList.toggle('dark');
  localStorage.setItem('theme', isDark ? 'dark' : 'light');
}

// On app init — respect OS preference
const stored = localStorage.getItem('theme');
if (stored === 'dark' || (!stored && matchMedia('(prefers-color-scheme: dark)').matches)) {
  document.documentElement.classList.add('dark');
}
```

No component changes needed — all Spartan primitives adapt via CSS variables.

---

## Typography

Install: `ng g @spartan-ng/cli:ui typography`

Import: `import { hlmH1, hlmH2, hlmH3, hlmH4, hlmP, hlmLead, hlmLarge, hlmSmall, hlmMuted, hlmUl, hlmBlockquote, hlmCode } from '@spartan-ng/helm/typography';`

### Classes

| Class | Use |
|-------|-----|
| `hlmH1` | Primary heading |
| `hlmH2` | Section heading |
| `hlmH3` | Sub-section heading |
| `hlmH4` | Minor heading |
| `hlmP` | Paragraph text |
| `hlmLead` | Intro/lead text |
| `hlmLarge` | Large body text |
| `hlmSmall` | Small text |
| `hlmMuted` | Secondary/muted text |
| `hlmUl` | Unordered list |
| `hlmBlockquote` | Block quotation |
| `hlmCode` | Inline code |

### Usage

```html
<!-- typography-example.component.html -->
<h1 [class]="hlmH1">Page Title</h1>
<p [class]="hlmLead">Introduction paragraph with emphasis.</p>
<p [class]="hlmP">Regular paragraph text.</p>
<p [class]="hlmMuted">Secondary information.</p>
<code [class]="hlmCode">inline code</code>
```

---

## Reactive Forms Integration

Spartan uses `HlmFieldImports` (`@spartan-ng/helm/field`) for form layout, validation, and error display with Angular Reactive Forms.

### Field System Components

| Directive/Component | Purpose |
|---------------------|---------|
| `hlm-field` | Single field container (wraps label + control + error) |
| `hlm-field-group` | Groups multiple fields vertically |
| `hlmFieldLabel` | Label directive |
| `hlm-field-description` | Hint/helper text |
| `hlm-field-error` | Validation error message |
| `hlm-field-content` | Content wrapper (used in horizontal layouts) |
| `hlmFieldSet` | Fieldset directive for grouping |
| `hlmFieldLegend` | Legend directive |
| `hlm-field-separator` | Visual divider between field groups |

**Orientation:** `hlm-field` accepts `orientation="horizontal"` or `orientation="responsive"` for side-by-side layouts.

### Anatomy

```html
<hlm-field>
  <label hlmFieldLabel for="name">Label</label>
  <input hlmInput id="name" formControlName="name" />
  <hlm-field-description>Helper text shown by default.</hlm-field-description>
  @if (form.controls.name.touched && form.controls.name.invalid) {
    <hlm-field-error>Error message when invalid.</hlm-field-error>
  }
</hlm-field>
```

### Error Display Pattern

Errors are shown conditionally using `@if` with `touched && invalid`:

```html
@if (form.controls.email.touched && form.controls.email.invalid) {
  <hlm-field-error>
    @if (form.controls.email.errors?.['required'] || form.controls.email.errors?.['minlength']) {
      Email must be at least 5 characters.
    }
    @if (form.controls.email.errors?.['maxlength']) {
      Email cannot exceed 100 characters.
    }
  </hlm-field-error>
}
```

### Complete Form Example — Input

```typescript
// bug-report.component.ts
import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { HlmButtonImports } from '@spartan-ng/helm/button';
import { HlmCardImports } from '@spartan-ng/helm/card';
import { HlmFieldImports } from '@spartan-ng/helm/field';
import { HlmInputImports } from '@spartan-ng/helm/input';
import { HlmInputGroupImports } from '@spartan-ng/helm/input-group';

@Component({
  selector: 'app-bug-report',
  imports: [ReactiveFormsModule, HlmCardImports, HlmFieldImports, HlmInputImports, HlmInputGroupImports, HlmButtonImports],
  templateUrl: './bug-report.component.html',
})
export class BugReportComponent {
  private readonly fb = inject(FormBuilder);

  form = this.fb.group({
    title: ['', [Validators.required, Validators.minLength(5), Validators.maxLength(32)]],
    description: ['', [Validators.required, Validators.minLength(20), Validators.maxLength(100)]],
  });

  submit() {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    console.log(this.form.value);
  }
}
```

```html
<!-- bug-report.component.html -->
<hlm-card>
  <hlm-card-header>
    <h3 hlmCardTitle>Bug Report</h3>
    <p hlmCardDescription>Help us improve by reporting bugs.</p>
  </hlm-card-header>
  <div hlmCardContent>
    <form id="form-bug-report" [formGroup]="form" (ngSubmit)="submit()">
      <hlm-field-group>
        <hlm-field>
          <label hlmFieldLabel for="title">Bug Title</label>
          <input hlmInput id="title" placeholder="Login button not working" formControlName="title" />
          @if (form.controls.title.touched && form.controls.title.invalid) {
            <hlm-field-error>
              @if (form.controls.title.errors?.['required'] || form.controls.title.errors?.['minlength']) {
                Title must be at least 5 characters.
              }
              @if (form.controls.title.errors?.['maxlength']) {
                Title cannot exceed 32 characters.
              }
            </hlm-field-error>
          }
        </hlm-field>
        <hlm-field>
          <label hlmFieldLabel for="description">Description</label>
          <hlm-input-group>
            <textarea hlmInputGroupTextarea id="description" class="min-h-24" rows="6" formControlName="description"></textarea>
            <hlm-input-group-addon align="block-end">
              <span hlmInputGroupText>{{ form.controls.description.value?.length || 0 }}/100 characters</span>
            </hlm-input-group-addon>
          </hlm-input-group>
          <hlm-field-description>Include steps to reproduce and expected behavior.</hlm-field-description>
          @if (form.controls.description.touched && form.controls.description.invalid) {
            <hlm-field-error>
              @if (form.controls.description.errors?.['required'] || form.controls.description.errors?.['minlength']) {
                Description must be at least 20 characters.
              }
              @if (form.controls.description.errors?.['maxlength']) {
                Description cannot exceed 100 characters.
              }
            </hlm-field-error>
          }
        </hlm-field>
      </hlm-field-group>
    </form>
  </div>
  <hlm-card-footer>
    <hlm-field orientation="horizontal">
      <button hlmBtn variant="outline" type="button" (click)="form.reset()">Reset</button>
      <button hlmBtn type="submit" form="form-bug-report">Submit</button>
    </hlm-field>
  </hlm-card-footer>
</hlm-card>
```

### Textarea

```typescript
// Uses HlmTextareaImports instead of HlmInputImports
import { HlmTextareaImports } from '@spartan-ng/helm/textarea';
```

```html
<hlm-field>
  <label hlmFieldLabel for="about">About</label>
  <textarea hlmTextarea id="about" class="min-h-[120px]" formControlName="about"></textarea>
  <hlm-field-description>Tell us about yourself.</hlm-field-description>
  @if (form.controls.about.touched && form.controls.about.invalid) {
    <hlm-field-error>Please provide at least 10 characters.</hlm-field-error>
  }
</hlm-field>
```

### Select

```typescript
import { HlmSelectImports } from '@spartan-ng/helm/select';
```

```html
<hlm-field orientation="responsive">
  <hlm-field-content>
    <label hlmFieldLabel for="language">Language</label>
    <hlm-field-description>Select your preferred language.</hlm-field-description>
    @if (form.controls.language.touched && form.controls.language.invalid) {
      <hlm-field-error>Please select a language.</hlm-field-error>
    }
  </hlm-field-content>
  <hlm-select formControlName="language" [itemToString]="itemToString">
    <hlm-select-trigger buttonId="language">
      <hlm-select-value placeholder="Select" />
    </hlm-select-trigger>
    <hlm-select-content *hlmSelectPortal>
      <hlm-select-group>
        @for (lang of languages; track lang.value) {
          <hlm-select-item [value]="lang.value">{{ lang.label }}</hlm-select-item>
        }
      </hlm-select-group>
    </hlm-select-content>
  </hlm-select>
</hlm-field>
```

Note: `[itemToString]` is needed on `hlm-select` to map the value to a display string for the trigger.

### Checkbox (single + group with FormArray)

```typescript
import { HlmCheckboxImports } from '@spartan-ng/helm/checkbox';

// Single boolean checkbox
form = this.fb.group({
  responses: [{ value: true, disabled: true }],
});

// Checkbox group with FormArray
form = this.fb.group({
  tasks: this.fb.array([], Validators.required),
});

handleChange(checked: boolean, id: string) {
  const tasks = this.form.controls.tasks;
  if (checked) {
    tasks.push(this.fb.control(id));
  } else {
    const index = tasks.controls.findIndex((x) => x.value === id);
    tasks.removeAt(index);
  }
  tasks.markAsTouched();
}
```

```html
<!-- Single checkbox with formControlName -->
<hlm-field orientation="horizontal">
  <hlm-checkbox id="responses" formControlName="responses" />
  <label hlmFieldLabel class="font-normal" for="responses">Push notifications</label>
</hlm-field>

<!-- Checkbox group with manual binding -->
@for (task of tasks; track task.id) {
  <hlm-field orientation="horizontal">
    <hlm-checkbox
      [id]="'task-' + task.id"
      [checked]="form.controls.tasks.value.includes(task.id)"
      (checkedChange)="handleChange($event, task.id)"
    />
    <label hlmFieldLabel class="font-normal" [for]="'task-' + task.id">{{ task.label }}</label>
  </hlm-field>
}
@if (form.controls.tasks.invalid && form.controls.tasks.touched) {
  <hlm-field-error>Please select at least one option.</hlm-field-error>
}
```

### Radio Group

```typescript
import { HlmRadioGroupImports } from '@spartan-ng/helm/radio-group';
```

```html
<fieldset hlmFieldSet>
  <legend hlmFieldLegend>Plan</legend>
  <hlm-field-description>Choose your subscription plan.</hlm-field-description>
  <hlm-radio-group formControlName="plan">
    @for (plan of plans; track plan.id) {
      <label hlmFieldLabel [for]="'plan-' + plan.id">
        <hlm-field orientation="horizontal">
          <hlm-field-content>
            <hlm-field-title>{{ plan.title }}</hlm-field-title>
            <hlm-field-description>{{ plan.description }}</hlm-field-description>
          </hlm-field-content>
          <hlm-radio [value]="plan.id" [id]="'plan-' + plan.id">
            <hlm-radio-indicator indicator />
          </hlm-radio>
        </hlm-field>
      </label>
    }
  </hlm-radio-group>
  @if (form.controls.plan.invalid && form.controls.plan.touched) {
    <hlm-field-error>Please select a plan.</hlm-field-error>
  }
</fieldset>
```

### Switch

```typescript
import { HlmSwitchImports } from '@spartan-ng/helm/switch';

form = this.fb.group({
  twoFactor: [false, Validators.requiredTrue],
});
```

```html
<hlm-field orientation="horizontal">
  <hlm-field-content>
    <label hlmFieldLabel for="two-factor">Multi-factor authentication</label>
    <hlm-field-description>Enable MFA to secure your account.</hlm-field-description>
    @if (form.controls.twoFactor.invalid && form.controls.twoFactor.touched) {
      <hlm-field-error>MFA is required.</hlm-field-error>
    }
  </hlm-field-content>
  <hlm-switch id="two-factor" formControlName="twoFactor" />
</hlm-field>
```

### Form Submission Pattern

```typescript
submit() {
  if (this.form.invalid) {
    this.form.markAllAsTouched(); // shows all errors
    return;
  }
  // form.value for enabled fields, form.getRawValue() to include disabled fields
  console.log(this.form.value);
}
```

### Reset Pattern

```html
<!-- Simple reset -->
<button hlmBtn variant="outline" type="button" (click)="form.reset()">Reset</button>

<!-- Reset with specific values -->
<button hlmBtn variant="outline" type="button" (click)="form.reset({ twoFactor: false })">Reset</button>
```

### Footer with Action Buttons

```html
<hlm-card-footer>
  <hlm-field orientation="horizontal">
    <button hlmBtn variant="outline" type="button" (click)="form.reset()">Reset</button>
    <button hlmBtn type="submit" form="my-form-id">Submit</button>
  </hlm-field>
</hlm-card-footer>
```

Note: Use `form="form-id"` attribute on the submit button when it's outside the `<form>` element (e.g., in the card footer).

---

## Setup — Icons (CRITICAL)

Icons use `@ng-icons/core` + `@ng-icons/lucide`. Register icons via `provideIcons()` in the component.

```typescript
import { NgIcon, provideIcons } from '@ng-icons/core';
import { lucideSun, lucideMoon, lucideMenu } from '@ng-icons/lucide';

@Component({
  imports: [NgIcon, HlmIconImports],
  providers: [provideIcons({ lucideSun, lucideMoon, lucideMenu })],
  templateUrl: './my.component.html',
})
```

```html
<!-- my.component.html -->
<ng-icon hlm size="base" name="lucideSun" />
```

### Icon Sizes

| Size | Pixels |
|------|--------|
| `xs` | 12px |
| `sm` | 16px |
| `base` | 24px (default) |
| `lg` | 32px |
| `xl` | 48px |

---

## Setup — Toasts (App Root)

Add `<hlm-toaster />` to your root component template:

```typescript
import { HlmToasterImports } from '@spartan-ng/helm/sonner';

// In app root template:
// <router-outlet />
// <hlm-toaster />
```

Show toasts anywhere:
```typescript
import { toast } from '@spartan-ng/brain/sonner';

toast.success('Saved successfully');
toast.error('Something went wrong');
toast.warning('Check your input');
toast.info('New update available');
```

---

## Component Catalog

### Layout & Navigation

| Component | Import | Use When |
|-----------|--------|----------|
| Card | `HlmCardImports` | Content containers with header/body/footer |
| Sidebar | `HlmSidebarImports` | App-level sidebar navigation |
| Navigation Menu | `HlmNavigationMenuImports` | Top-level nav with dropdowns |
| Tabs | `HlmTabsImports` | Switching between views in the same context |
| Separator | `HlmSeparatorImports` | Visual dividers between sections |
| Sheet | `HlmSheetImports` | Slide-out panels (mobile menu, detail views) |
| Breadcrumb | `HlmBreadcrumbImports` | Hierarchical page location |

### Actions & Inputs

| Component | Import | Use When |
|-----------|--------|----------|
| Button | `HlmButtonImports` | All clickable actions |
| Input | `HlmInputImports` | Text fields |
| Select | `HlmSelectImports` | Dropdown single-select |
| Checkbox | `HlmCheckboxImports` | Boolean toggles in forms |
| Switch | `HlmSwitch` | On/off toggle with visual feedback |
| Textarea | `HlmTextareaImports` | Multi-line text input |
| Radio Group | `HlmRadioGroupImports` | Single choice from a list |
| Slider | `HlmSliderImports` | Numeric range selection |
| Toggle | `HlmToggleImports` | Pressed/unpressed state button |

### Forms & Validation

| Component | Import | Use When |
|-----------|--------|----------|
| Form Field | `HlmFormFieldImports` | Wrapping inputs with error/hint messages |
| Label | `HlmLabelImports` | Accessible input labels |

### Feedback & Status

| Component | Import | Use When |
|-----------|--------|----------|
| Alert | `HlmAlertImports` | Inline status messages |
| Badge | `HlmBadgeImports` | Status labels, counts, tags |
| Progress | `HlmProgressImports` | Determinate/indeterminate progress bars |
| Skeleton | `HlmSkeletonImports` | Loading placeholders |
| Spinner | `HlmSpinnerImports` | Loading indicator |
| Sonner (Toast) | `toast` from brain | Transient notifications |

### Overlays & Popups

| Component | Import | Use When |
|-----------|--------|----------|
| Dialog | `HlmDialogImports` | Modal confirmations, forms |
| Alert Dialog | `HlmAlertDialogImports` | Destructive action confirmations |
| Dropdown Menu | `HlmDropdownMenuImports` | Context actions on a trigger |
| Popover | `HlmPopoverImports` | Rich content on hover/click |
| Tooltip | `HlmTooltipImports` | Brief text hints on hover |
| Context Menu | `HlmContextMenuImports` | Right-click menus |
| Hover Card | `HlmHoverCardImports` | Preview cards on hover |

### Data Display

| Component | Import | Use When |
|-----------|--------|----------|
| Table | `HlmTableImports` | Simple data tables |
| Data Table | TanStack Table integration | Complex sortable/filterable tables |
| Avatar | `HlmAvatarImports` | User profile images with fallback |
| Accordion | `HlmAccordionImports` | Expandable content sections |
| Carousel | `HlmCarouselImports` | Sliding content panels |

---

## Button

**Directive:** `hlmBtn` on `<button>` or `<a>` elements.

### Variants
`default` | `outline` | `secondary` | `ghost` | `destructive` | `link`

### Sizes
`default` (h-9) | `xs` (h-6) | `sm` (h-8) | `lg` (h-10) | `icon` (square) | `icon-xs` | `icon-sm` | `icon-lg`

```html
<!-- button.component.html -->
<button hlmBtn variant="default">Save</button>
<button hlmBtn variant="outline" size="sm">Cancel</button>
<button hlmBtn variant="ghost" size="icon">
  <ng-icon hlm name="lucideX" size="sm" />
</button>
<a hlmBtn variant="link" routerLink="/settings">Settings</a>
```

---

## Card

**Directives:** `hlmCard`, `hlmCardHeader`, `hlmCardTitle`, `hlmCardDescription`, `hlmCardContent`, `hlmCardFooter`

```html
<!-- feature-card.component.html -->
<section hlmCard>
  <div hlmCardHeader>
    <h3 hlmCardTitle>Card Title</h3>
    <p hlmCardDescription>Supporting description text</p>
  </div>
  <p hlmCardContent>Main content area</p>
  <div hlmCardFooter>
    <button hlmBtn variant="outline">Cancel</button>
    <button hlmBtn>Save</button>
  </div>
</section>
```

---

## Dialog

**Components:** `hlm-dialog`, `hlm-dialog-content`, `hlm-dialog-header`, `hlm-dialog-footer`
**Directives:** `hlmDialogTrigger`, `hlmDialogClose`, `*hlmDialogPortal`, `hlmDialogTitle`, `hlmDialogDescription`

```html
<!-- confirm-dialog.component.html -->
<hlm-dialog>
  <button hlmDialogTrigger hlmBtn>Open Dialog</button>
  <hlm-dialog-content *hlmDialogPortal="let ctx">
    <hlm-dialog-header>
      <h3 hlmDialogTitle>Confirm Action</h3>
      <p hlmDialogDescription>This action cannot be undone.</p>
    </hlm-dialog-header>
    <hlm-dialog-footer>
      <button hlmBtn variant="outline" hlmDialogClose>Cancel</button>
      <button hlmBtn variant="destructive" (click)="confirm()">Delete</button>
    </hlm-dialog-footer>
  </hlm-dialog-content>
</hlm-dialog>
```

### Programmatic Dialog

```typescript
import { HlmDialogService } from '@spartan-ng/helm/dialog';

private dialogService = inject(HlmDialogService);

openDialog() {
  this.dialogService.open(MyDialogComponent, { contentClass: 'sm:max-w-lg' });
}
```

---

## Sheet (Slide-out Panel)

**Components:** `hlm-sheet`, `hlm-sheet-content`, `hlm-sheet-header`, `hlm-sheet-footer`
**Directives:** `hlmSheetTrigger`, `hlmSheetClose`, `*hlmSheetPortal`, `hlmSheetTitle`, `hlmSheetDescription`

**Sides:** `left` | `right` (default) | `top` | `bottom`

```html
<!-- mobile-menu.component.html -->
<hlm-sheet side="left">
  <button hlmSheetTrigger hlmBtn variant="ghost" size="icon">
    <ng-icon hlm name="lucideMenu" size="sm" />
  </button>
  <hlm-sheet-content *hlmSheetPortal="let ctx">
    <hlm-sheet-header>
      <h3 hlmSheetTitle>Menu</h3>
    </hlm-sheet-header>
    <nav class="flex flex-col gap-2 p-4">
      <a routerLink="/" hlmSheetClose>Home</a>
      <a routerLink="/sites" hlmSheetClose>Sites</a>
    </nav>
  </hlm-sheet-content>
</hlm-sheet>
```

---

## Dropdown Menu

**Directives:** `[hlmDropdownMenuTrigger]`, `hlmDropdownMenuItem`, `hlmDropdownMenuLabel`, `hlmDropdownMenuSeparator`

```html
<!-- user-menu.component.html -->
<button hlmBtn variant="ghost" size="icon" [hlmDropdownMenuTrigger]="userMenu">
  <ng-icon hlm name="lucideUser" size="sm" />
</button>

<ng-template #userMenu>
  <hlm-dropdown-menu class="w-48">
    <hlm-dropdown-menu-label>My Account</hlm-dropdown-menu-label>
    <hlm-dropdown-menu-separator />
    <button hlmDropdownMenuItem>Profile</button>
    <button hlmDropdownMenuItem>Settings</button>
    <hlm-dropdown-menu-separator />
    <button hlmDropdownMenuItem variant="destructive">Log out</button>
  </hlm-dropdown-menu>
</ng-template>
```

---

## Table

**Directives:** `hlmTableContainer`, `hlmTable`, `hlmTHead`, `hlmTBody`, `hlmTFoot`, `hlmTr`, `hlmTh`, `hlmTd`, `hlmCaption`

```html
<!-- data-table.component.html -->
<div hlmTableContainer>
  <table hlmTable>
    <thead hlmTHead>
      <tr hlmTr>
        <th hlmTh>Name</th>
        <th hlmTh>Status</th>
        <th hlmTh class="text-right">Amount</th>
      </tr>
    </thead>
    <tbody hlmTBody>
      @for (item of items(); track item.id) {
        <tr hlmTr>
          <td hlmTd class="font-medium">{{ item.name }}</td>
          <td hlmTd>
            <span hlmBadge variant="outline">{{ item.status }}</span>
          </td>
          <td hlmTd class="text-right">{{ item.amount | currency }}</td>
        </tr>
      }
    </tbody>
  </table>
</div>
```

---

## Tabs

**Components:** `hlm-tabs`
**Directives:** `hlmTabsList`, `hlmTabsTrigger`, `hlmTabsContent`

```html
<!-- settings-tabs.component.html -->
<hlm-tabs tab="general" class="w-full">
  <hlm-tabs-list aria-label="Settings">
    <button hlmTabsTrigger="general">General</button>
    <button hlmTabsTrigger="security">Security</button>
  </hlm-tabs-list>
  <div hlmTabsContent="general">General settings content</div>
  <div hlmTabsContent="security">Security settings content</div>
</hlm-tabs>
```

---

## Form Field + Input + Label

```html
<!-- edit-form.component.html -->
<hlm-form-field>
  <label hlmLabel for="name">Name</label>
  <input hlmInput id="name" formControlName="name" />
  <hlm-hint>Enter your full name</hlm-hint>
  <hlm-error>Name is required</hlm-error>
</hlm-form-field>
```

Error messages show automatically when the form control is invalid and touched.

---

## Select

```html
<!-- category-select.component.html -->
<hlm-select [(value)]="selectedCategory">
  <hlm-select-trigger class="w-56">
    <hlm-select-value placeholder="Choose category" />
  </hlm-select-trigger>
  <hlm-select-content *hlmSelectPortal>
    @for (cat of categories(); track cat.value) {
      <hlm-select-item [value]="cat.value">{{ cat.label }}</hlm-select-item>
    }
  </hlm-select-content>
</hlm-select>
```

---

## Alert

**Variants:** `default` | `destructive`

```html
<!-- notification.component.html -->
<hlm-alert variant="default">
  <ng-icon hlm name="lucideCircleCheck" size="sm" />
  <h4 hlmAlertTitle>Success</h4>
  <p hlmAlertDescription>Your changes have been saved.</p>
</hlm-alert>
```

---

## Badge

**Variants:** `default` | `secondary` | `destructive` | `outline`

```html
<span hlmBadge variant="default">Active</span>
<span hlmBadge variant="destructive">Expired</span>
<span hlmBadge variant="outline">Draft</span>
```

---

## Avatar

```html
<hlm-avatar>
  <img hlmAvatarImage [src]="user().avatarUrl" [alt]="user().name" />
  <span hlmAvatarFallback>{{ user().initials }}</span>
</hlm-avatar>
```

**Sizes:** `sm` | `default` | `lg`

---

## Loading States

### Skeleton (content placeholder)
```html
<hlm-skeleton class="h-4 w-[200px]" />
<hlm-skeleton class="h-4 w-[160px]" />
```

### Spinner (activity indicator)
```html
<hlm-spinner />
```

### Progress (determinate)
```html
<hlm-progress [value]="uploadProgress()">
  <hlm-progress-indicator />
</hlm-progress>
```

---

## Sidebar

```typescript
// Provide config in app.config.ts or component providers
provideHlmSidebarConfig({
  sidebarWidth: '16rem',
  sidebarWidthIcon: '3rem',
  mobileBreakpoint: '768px',
})
```

```html
<!-- layout.component.html -->
<div hlmSidebarWrapper>
  <hlm-sidebar>
    <div hlmSidebarHeader>
      <span class="font-semibold">Web Configurator</span>
    </div>
    <div hlmSidebarContent>
      <div hlmSidebarGroup>
        <div hlmSidebarGroupLabel>Navigation</div>
        <ul hlmSidebarMenu>
          <li hlmSidebarMenuItem>
            <a hlmSidebarMenuButton routerLink="/sites">
              <ng-icon hlm name="lucideGlobe" size="sm" />
              Sites
            </a>
          </li>
        </ul>
      </div>
    </div>
  </hlm-sidebar>
  <main hlmSidebarInset>
    <router-outlet />
  </main>
</div>
```

---

## Tooltip

```html
<button hlmTooltip="Save changes" hlmBtn variant="outline" size="icon">
  <ng-icon hlm name="lucideSave" size="sm" />
</button>
```

---

## Navigation Menu

```html
<!-- top-nav.component.html -->
<nav hlmNavigationMenu>
  <ul hlmNavigationMenuList>
    <li hlmNavigationMenuItem>
      <a hlmNavigationMenuLink routerLink="/dashboard">Dashboard</a>
    </li>
    <li hlmNavigationMenuItem>
      <button hlmNavigationMenuTrigger>
        Settings
        <ng-icon hlm name="lucideChevronDown" size="xs" />
      </button>
      <hlm-navigation-menu-content *hlmNavigationMenuPortal>
        <ul class="grid gap-1 p-2 w-48">
          <li><a hlmNavigationMenuLink routerLink="/settings/general">General</a></li>
          <li><a hlmNavigationMenuLink routerLink="/settings/security">Security</a></li>
        </ul>
      </hlm-navigation-menu-content>
    </li>
  </ul>
</nav>
```

---

## Quick Reference — When to Use What

| Need | Component |
|------|-----------|
| Page layout with sidebar | Sidebar |
| Top navigation bar | Navigation Menu |
| Mobile menu | Sheet (side="left") |
| Content container | Card |
| Modal / confirmation | Dialog / Alert Dialog |
| User actions dropdown | Dropdown Menu |
| Form text input | Input + Form Field + Label |
| Form selection | Select / Checkbox / Switch / Radio Group |
| Status indicator | Badge |
| Inline message | Alert |
| Loading placeholder | Skeleton |
| Loading spinner | Spinner |
| Toast notification | Sonner (toast) |
| Brief text hint | Tooltip |
| Tab navigation | Tabs |
| Data listing | Table |
| Complex data grid | Data Table (TanStack) |

## Import Pattern

Always import from `@spartan-ng/helm/<component>`:

```typescript
import { HlmButtonImports } from '@spartan-ng/helm/button';
import { HlmCardImports } from '@spartan-ng/helm/card';
import { HlmDialogImports } from '@spartan-ng/helm/dialog';
// etc.
```

All `HlmXxxImports` are arrays — spread them in the component `imports` array or add them directly.
