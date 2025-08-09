# 3PL ERP Billing System (Django Version)

## Overview

This is a comprehensive Enterprise Resource Planning (ERP) system specifically designed for third-party logistics (3PL) providers. The application manages the complete billing lifecycle including customer management, service tracking, rate management, invoice generation, and detailed product/inventory management. Built with Django and PostgreSQL, it provides a web-based interface for logistics companies to streamline their operations with comprehensive SKU tracking including unit/case/master/pallet packaging specifications with dimensions, weights, and volumes.

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Web Framework
- **Django 5.0**: Primary web framework chosen for its batteries-included approach, robust ORM, and built-in admin interface
- **Django ORM**: Provides powerful database abstraction with migration support, querysets, and model relationships
- **Django Forms**: Built-in form handling with validation, CSRF protection, and widget customization
- **Django Admin**: Automatic admin interface for data management and quick prototyping

### Database Architecture
- **PostgreSQL**: Production-ready database with full ACID compliance and advanced features
- **Django Models**: Six core models with proper foreign key relationships and model managers:
  - Customer: Stores client information and billing preferences
  - ServiceType: Defines available logistics services with units and categories
  - ServiceRate: Customer-specific pricing for each service type
  - ServiceRecord: Tracks actual service usage for billing
  - Invoice: Generated billing documents with line items
  - Product: Comprehensive SKU management with packaging hierarchy
  - InventoryRecord: Real-time inventory levels
  - InventoryTransaction: Complete audit trail of inventory movements
- **Database Migrations**: Version-controlled schema changes with Django's migration system
- **Model Signals**: Automatic inventory updates and audit logging

### Frontend Architecture
- **Django Templates**: Server-side rendering with template inheritance and custom tags
- **Bootstrap 5**: Responsive CSS framework for consistent UI components
- **Django Static Files**: Organized asset management with collectstatic for production
- **HTMX**: Progressive enhancement for dynamic interactions without full page reloads
- **Alpine.js**: Lightweight JavaScript for interactive components
- **Font Awesome Icons**: Consistent iconography throughout the interface

### Business Logic
- **Service-Based Billing**: Flexible billing system supporting multiple unit types (per pallet, per hour, per mile, etc.)
- **Customer Rate Management**: Individual pricing agreements per customer per service type
- **Invoice Generation**: Automatic calculation of line items based on service records and rates
- **Dashboard Analytics**: Real-time metrics and revenue tracking with monthly trends using Django ORM aggregations
- **Product/SKU Management**: Comprehensive inventory tracking with full packaging hierarchy:
  - Unit specifications: weight, dimensions, volume calculations
  - Case specifications: units per case, case dimensions and weight
  - Master carton: optional intermediate packaging level
  - Pallet configuration: cases/masters per pallet, TI x HI, total weight and height
- **Inventory Tracking**: Real-time inventory levels with transaction history (receipts, shipments, adjustments, transfers)
- **Storage Requirements**: Temperature control, shelf life, hazmat, fragile, and stackability tracking
- **Bulk Upload**: CSV import/export functionality with Django's CSV module

### Security & Session Management
- **Django Authentication**: Built-in user authentication system with groups and permissions
- **Django Sessions**: Secure session handling with configurable backends (database, cache, file)
- **CSRF Protection**: Automatic cross-site request forgery protection
- **Django Security Middleware**: XSS protection, clickjacking prevention, SSL redirect
- **Permission System**: Granular object-level permissions with django-guardian (optional)

## Django Project Structure

```
erp_project/
├── erp_project/          # Project configuration
│   ├── __init__.py
│   ├── settings.py       # Django settings
│   ├── urls.py          # Root URL configuration
│   ├── wsgi.py          # WSGI application
│   └── asgi.py          # ASGI application
├── billing/             # Main application
│   ├── __init__.py
│   ├── admin.py         # Admin interface configuration
│   ├── apps.py          # App configuration
│   ├── models.py        # Database models
│   ├── views.py         # View functions/classes
│   ├── forms.py         # Django forms
│   ├── urls.py          # App URL patterns
│   ├── signals.py       # Model signals
│   ├── managers.py      # Custom model managers
│   ├── utils.py         # Helper functions
│   ├── migrations/      # Database migrations
│   ├── templates/       # HTML templates
│   │   ├── billing/
│   │   └── base.html
│   ├── static/          # Static files
│   │   ├── css/
│   │   ├── js/
│   │   └── images/
│   ├── management/      # Custom management commands
│   │   └── commands/
│   └── templatetags/    # Custom template tags
├── media/               # User-uploaded files
├── staticfiles/         # Collected static files (production)
├── requirements.txt     # Python dependencies
└── manage.py           # Django management script
```

## Key Django Models

```python
# billing/models.py

from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator
from decimal import Decimal

class Customer(models.Model):
    name = models.CharField(max_length=200)
    code = models.CharField(max_length=50, unique=True)
    email = models.EmailField()
    phone = models.CharField(max_length=20, blank=True)
    address = models.TextField()
    payment_terms = models.IntegerField(default=30)
    billing_cycle = models.CharField(max_length=20, choices=[
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('quarterly', 'Quarterly')
    ])
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['name']
        
    def __str__(self):
        return self.name

class Product(models.Model):
    customer = models.ForeignKey(Customer, on_delete=models.CASCADE, related_name='products')
    sku_code = models.CharField(max_length=100)
    description = models.TextField()
    category = models.CharField(max_length=100, default='General')
    
    # Unit specifications
    unit_weight = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    unit_length = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    unit_width = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    unit_height = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    unit_volume = models.DecimalField(max_digits=12, decimal_places=4, default=0)
    
    # Case specifications
    units_per_case = models.IntegerField(default=1)
    case_weight = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    case_length = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    case_width = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    case_height = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    case_volume = models.DecimalField(max_digits=12, decimal_places=4, default=0)
    
    # Master carton specifications (optional)
    has_master_carton = models.BooleanField(default=False)
    units_per_master = models.IntegerField(null=True, blank=True)
    master_weight = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    master_length = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    master_width = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    master_height = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    master_volume = models.DecimalField(max_digits=12, decimal_places=4, null=True, blank=True)
    
    # Pallet specifications
    cases_per_pallet = models.IntegerField(default=1)
    ti_cases_per_layer = models.IntegerField(default=1)
    hi_layers_per_pallet = models.IntegerField(default=1)
    pallet_weight = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    pallet_height = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    
    # Storage requirements
    temperature_controlled = models.BooleanField(default=False)
    min_temperature = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)
    max_temperature = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)
    shelf_life_days = models.IntegerField(null=True, blank=True)
    is_hazmat = models.BooleanField(default=False)
    is_fragile = models.BooleanField(default=True)
    is_stackable = models.BooleanField(default=True)
    storage_instructions = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['customer', 'sku_code']
        ordering = ['sku_code']
        
    def save(self, *args, **kwargs):
        # Calculate volumes
        self.unit_volume = self.unit_length * self.unit_width * self.unit_height
        self.case_volume = self.case_length * self.case_width * self.case_height
        if self.has_master_carton and all([self.master_length, self.master_width, self.master_height]):
            self.master_volume = self.master_length * self.master_width * self.master_height
        super().save(*args, **kwargs)
        
    def __str__(self):
        return f"{self.sku_code} - {self.description}"
```

## Key Django Views

```python
# billing/views.py

from django.shortcuts import render, redirect, get_object_or_404
from django.contrib import messages
from django.views.generic import ListView, CreateView, UpdateView, DetailView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.db.models import Sum, Count, Avg, Q
from django.http import HttpResponse, JsonResponse
import csv
from .models import Customer, Product, Invoice, ServiceRecord
from .forms import CustomerForm, ProductForm, BulkUploadForm

class DashboardView(LoginRequiredMixin, TemplateView):
    template_name = 'billing/dashboard.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['total_customers'] = Customer.objects.count()
        context['total_invoices'] = Invoice.objects.count()
        context['pending_invoices'] = Invoice.objects.filter(status='sent').count()
        context['total_revenue'] = Invoice.objects.filter(
            status='paid'
        ).aggregate(Sum('total_amount'))['total_amount__sum'] or 0
        context['recent_invoices'] = Invoice.objects.select_related(
            'customer'
        ).order_by('-created_at')[:5]
        return context

class ProductListView(LoginRequiredMixin, ListView):
    model = Product
    template_name = 'billing/product_list.html'
    context_object_name = 'products'
    paginate_by = 20
    
    def get_queryset(self):
        queryset = super().get_queryset()
        customer_id = self.request.GET.get('customer')
        if customer_id:
            queryset = queryset.filter(customer_id=customer_id)
        search = self.request.GET.get('search')
        if search:
            queryset = queryset.filter(
                Q(sku_code__icontains=search) |
                Q(description__icontains=search)
            )
        return queryset.select_related('customer').prefetch_related('inventory_records')

def bulk_upload_products(request):
    if request.method == 'POST':
        form = BulkUploadForm(request.POST, request.FILES)
        if form.is_valid():
            csv_file = request.FILES['file']
            customer = form.cleaned_data['customer']
            
            decoded_file = csv_file.read().decode('utf-8').splitlines()
            reader = csv.DictReader(decoded_file)
            
            products_created = 0
            for row in reader:
                try:
                    product = Product(
                        customer=customer,
                        sku_code=row['SKU Code'],
                        description=row['Description'],
                        # ... map all fields from CSV
                    )
                    product.full_clean()
                    product.save()
                    products_created += 1
                except Exception as e:
                    messages.warning(request, f"Error in row {row.get('SKU Code')}: {str(e)}")
            
            messages.success(request, f"Successfully created {products_created} products")
            return redirect('product_list')
    else:
        form = BulkUploadForm()
    
    return render(request, 'billing/bulk_upload.html', {'form': form})

def download_product_template(request):
    response = HttpResponse(content_type='text/csv')
    response['Content-Disposition'] = 'attachment; filename="product_template.csv"'
    
    writer = csv.writer(response)
    writer.writerow([
        'SKU Code', 'Description', 'Category',
        'Unit Weight (lbs)', 'Unit Length (in)', 'Unit Width (in)', 'Unit Height (in)',
        'Units per Case', 'Case Weight (lbs)', 'Case Length (in)', 'Case Width (in)', 'Case Height (in)',
        'Has Master Carton', 'Units per Master', 'Master Weight (lbs)', 
        'Master Length (in)', 'Master Width (in)', 'Master Height (in)',
        'Cases per Pallet', 'TI (Cases per Layer)', 'HI (Layers per Pallet)', 
        'Pallet Weight (lbs)', 'Pallet Height (in)',
        'Temperature Control', 'Min Temperature (F)', 'Max Temperature (F)',
        'Shelf Life (days)', 'Hazmat', 'Fragile', 'Stackable', 'Storage Instructions'
    ])
    
    # Add sample row
    writer.writerow([
        'SKU001', 'Sample Product', 'Electronics',
        '1.5', '6', '4', '2',
        '12', '20', '12', '10', '8',
        'No', '', '', '', '', '',
        '100', '10', '10', '2200', '48',
        'Yes', '35', '75', '365', 'No', 'Yes', 'Yes', 'Keep in dry area'
    ])
    
    return response
```

## Django URLs Configuration

```python
# erp_project/urls.py
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('billing.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)

# billing/urls.py
from django.urls import path
from . import views

app_name = 'billing'

urlpatterns = [
    path('', views.DashboardView.as_view(), name='dashboard'),
    path('customers/', views.CustomerListView.as_view(), name='customer_list'),
    path('customers/new/', views.CustomerCreateView.as_view(), name='customer_create'),
    path('customers/<int:pk>/', views.CustomerDetailView.as_view(), name='customer_detail'),
    path('customers/<int:pk>/edit/', views.CustomerUpdateView.as_view(), name='customer_update'),
    
    path('products/', views.ProductListView.as_view(), name='product_list'),
    path('products/new/', views.ProductCreateView.as_view(), name='product_create'),
    path('products/<int:pk>/', views.ProductDetailView.as_view(), name='product_detail'),
    path('products/bulk-upload/', views.bulk_upload_products, name='bulk_upload'),
    path('products/template/', views.download_product_template, name='download_template'),
    
    path('invoices/', views.InvoiceListView.as_view(), name='invoice_list'),
    path('invoices/new/', views.InvoiceCreateView.as_view(), name='invoice_create'),
    path('invoices/<int:pk>/', views.InvoiceDetailView.as_view(), name='invoice_detail'),
    path('invoices/<int:pk>/pdf/', views.generate_invoice_pdf, name='invoice_pdf'),
    
    path('inventory/transactions/', views.InventoryTransactionListView.as_view(), name='transaction_list'),
    path('inventory/transactions/new/', views.create_inventory_transaction, name='transaction_create'),
    
    path('reports/', views.ReportsView.as_view(), name='reports'),
    path('api/chart-data/', views.chart_data_api, name='chart_data'),
]
```

## Django Settings Configuration

```python
# erp_project/settings.py

import os
from pathlib import Path
import environ

# Initialize environment variables
env = environ.Env()
environ.Env.read_env()

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = env('SECRET_KEY', default='your-secret-key-here')

DEBUG = env.bool('DEBUG', default=True)

ALLOWED_HOSTS = env.list('ALLOWED_HOSTS', default=['localhost', '127.0.0.1', '.replit.app'])

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.humanize',
    
    # Third-party apps
    'crispy_forms',
    'crispy_bootstrap5',
    'django_filters',
    'rest_framework',
    'corsheaders',
    
    # Local apps
    'billing',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',  # For static files
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'erp_project.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

# Database - PostgreSQL for Replit
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': env('PGDATABASE'),
        'USER': env('PGUSER'),
        'PASSWORD': env('PGPASSWORD'),
        'HOST': env('PGHOST'),
        'PORT': env('PGPORT'),
    }
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static']

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Crispy Forms
CRISPY_ALLOWED_TEMPLATE_PACKS = "bootstrap5"
CRISPY_TEMPLATE_PACK = "bootstrap5"

# Email configuration (for SendGrid)
EMAIL_BACKEND = 'sendgrid_backend.SendgridBackend'
SENDGRID_API_KEY = env('SENDGRID_API_KEY', default='')
DEFAULT_FROM_EMAIL = 'noreply@3plerp.com'

# Session settings
SESSION_ENGINE = 'django.contrib.sessions.backends.db'
SESSION_COOKIE_AGE = 1209600  # 2 weeks

# Security settings for production
if not DEBUG:
    SECURE_SSL_REDIRECT = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = 'DENY'
```

## Django Forms

```python
# billing/forms.py

from django import forms
from django.core.exceptions import ValidationError
from crispy_forms.helper import FormHelper
from crispy_forms.layout import Layout, Submit, Row, Column, Fieldset
from .models import Customer, Product, Invoice, ServiceRecord

class ProductForm(forms.ModelForm):
    class Meta:
        model = Product
        fields = '__all__'
        widgets = {
            'description': forms.Textarea(attrs={'rows': 3}),
            'storage_instructions': forms.Textarea(attrs={'rows': 3}),
            'unit_weight': forms.NumberInput(attrs={'step': '0.01'}),
            'unit_length': forms.NumberInput(attrs={'step': '0.01'}),
            'unit_width': forms.NumberInput(attrs={'step': '0.01'}),
            'unit_height': forms.NumberInput(attrs={'step': '0.01'}),
            'case_weight': forms.NumberInput(attrs={'step': '0.01'}),
            'case_length': forms.NumberInput(attrs={'step': '0.01'}),
            'case_width': forms.NumberInput(attrs={'step': '0.01'}),
            'case_height': forms.NumberInput(attrs={'step': '0.01'}),
            'pallet_weight': forms.NumberInput(attrs={'step': '0.01'}),
            'pallet_height': forms.NumberInput(attrs={'step': '0.01'}),
            'min_temperature': forms.NumberInput(attrs={'step': '0.1'}),
            'max_temperature': forms.NumberInput(attrs={'step': '0.1'}),
        }
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.helper = FormHelper()
        self.helper.layout = Layout(
            Fieldset(
                'Basic Information',
                Row(
                    Column('customer', css_class='form-group col-md-6'),
                    Column('sku_code', css_class='form-group col-md-6'),
                ),
                'description',
                'category',
            ),
            Fieldset(
                'Unit Specifications',
                Row(
                    Column('unit_weight', css_class='form-group col-md-3'),
                    Column('unit_length', css_class='form-group col-md-3'),
                    Column('unit_width', css_class='form-group col-md-3'),
                    Column('unit_height', css_class='form-group col-md-3'),
                ),
            ),
            Fieldset(
                'Case Specifications',
                Row(
                    Column('units_per_case', css_class='form-group col-md-3'),
                    Column('case_weight', css_class='form-group col-md-3'),
                    Column('case_length', css_class='form-group col-md-2'),
                    Column('case_width', css_class='form-group col-md-2'),
                    Column('case_height', css_class='form-group col-md-2'),
                ),
            ),
            Fieldset(
                'Master Carton (Optional)',
                'has_master_carton',
                Row(
                    Column('units_per_master', css_class='form-group col-md-3'),
                    Column('master_weight', css_class='form-group col-md-3'),
                    Column('master_length', css_class='form-group col-md-2'),
                    Column('master_width', css_class='form-group col-md-2'),
                    Column('master_height', css_class='form-group col-md-2'),
                ),
            ),
            Fieldset(
                'Pallet Specifications',
                Row(
                    Column('cases_per_pallet', css_class='form-group col-md-3'),
                    Column('ti_cases_per_layer', css_class='form-group col-md-3'),
                    Column('hi_layers_per_pallet', css_class='form-group col-md-3'),
                    Column('pallet_weight', css_class='form-group col-md-3'),
                ),
                'pallet_height',
            ),
            Fieldset(
                'Storage Requirements',
                Row(
                    Column('temperature_controlled', css_class='form-group col-md-3'),
                    Column('min_temperature', css_class='form-group col-md-3'),
                    Column('max_temperature', css_class='form-group col-md-3'),
                    Column('shelf_life_days', css_class='form-group col-md-3'),
                ),
                Row(
                    Column('is_hazmat', css_class='form-group col-md-3'),
                    Column('is_fragile', css_class='form-group col-md-3'),
                    Column('is_stackable', css_class='form-group col-md-3'),
                ),
                'storage_instructions',
            ),
            Submit('submit', 'Save Product', css_class='btn btn-primary')
        )

class BulkUploadForm(forms.Form):
    customer = forms.ModelChoiceField(
        queryset=Customer.objects.all(),
        empty_label="Select a customer",
        widget=forms.Select(attrs={'class': 'form-control'})
    )
    file = forms.FileField(
        validators=[],
        widget=forms.FileInput(attrs={'accept': '.csv'})
    )
    
    def clean_file(self):
        file = self.cleaned_data['file']
        if not file.name.endswith('.csv'):
            raise ValidationError('File must be CSV format')
        return file
```

## Django Admin Configuration

```python
# billing/admin.py

from django.contrib import admin
from django.utils.html import format_html
from .models import Customer, Product, Invoice, ServiceType, ServiceRate, ServiceRecord, InventoryRecord, InventoryTransaction

@admin.register(Customer)
class CustomerAdmin(admin.ModelAdmin):
    list_display = ['name', 'code', 'email', 'payment_terms', 'billing_cycle', 'is_active']
    list_filter = ['is_active', 'billing_cycle', 'created_at']
    search_fields = ['name', 'code', 'email']
    readonly_fields = ['created_at', 'updated_at']

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ['sku_code', 'description', 'customer', 'units_per_case', 'cases_per_pallet', 'temperature_controlled']
    list_filter = ['customer', 'category', 'temperature_controlled', 'is_hazmat', 'is_fragile']
    search_fields = ['sku_code', 'description']
    readonly_fields = ['unit_volume', 'case_volume', 'master_volume', 'created_at', 'updated_at']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('customer', 'sku_code', 'description', 'category')
        }),
        ('Unit Specifications', {
            'fields': ('unit_weight', 'unit_length', 'unit_width', 'unit_height', 'unit_volume')
        }),
        ('Case Specifications', {
            'fields': ('units_per_case', 'case_weight', 'case_length', 'case_width', 'case_height', 'case_volume')
        }),
        ('Master Carton', {
            'fields': ('has_master_carton', 'units_per_master', 'master_weight', 
                      'master_length', 'master_width', 'master_height', 'master_volume'),
            'classes': ('collapse',)
        }),
        ('Pallet Specifications', {
            'fields': ('cases_per_pallet', 'ti_cases_per_layer', 'hi_layers_per_pallet', 
                      'pallet_weight', 'pallet_height')
        }),
        ('Storage Requirements', {
            'fields': ('temperature_controlled', 'min_temperature', 'max_temperature', 
                      'shelf_life_days', 'is_hazmat', 'is_fragile', 'is_stackable', 
                      'storage_instructions')
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )

@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    list_display = ['invoice_number', 'customer', 'issue_date', 'due_date', 'total_amount', 'status_badge']
    list_filter = ['status', 'issue_date', 'due_date']
    search_fields = ['invoice_number', 'customer__name']
    readonly_fields = ['invoice_number', 'total_amount', 'created_at', 'updated_at']
    
    def status_badge(self, obj):
        colors = {
            'draft': 'secondary',
            'sent': 'warning',
            'paid': 'success',
            'overdue': 'danger',
            'cancelled': 'dark'
        }
        return format_html(
            '<span class="badge bg-{}">{}</span>',
            colors.get(obj.status, 'primary'),
            obj.get_status_display()
        )
    status_badge.short_description = 'Status'

@admin.register(InventoryRecord)
class InventoryRecordAdmin(admin.ModelAdmin):
    list_display = ['product', 'units_on_hand', 'cases_on_hand', 'pallets_on_hand', 'last_receipt_date', 'last_ship_date']
    list_filter = ['last_receipt_date', 'last_ship_date']
    search_fields = ['product__sku_code', 'product__description']
    readonly_fields = ['created_at', 'updated_at']

@admin.register(InventoryTransaction)
class InventoryTransactionAdmin(admin.ModelAdmin):
    list_display = ['transaction_date', 'product', 'transaction_type', 'units_quantity', 'cases_quantity', 'pallets_quantity', 'performed_by']
    list_filter = ['transaction_type', 'transaction_date']
    search_fields = ['product__sku_code', 'reference_number']
    readonly_fields = ['transaction_date']
    date_hierarchy = 'transaction_date'
```

## Django Management Commands

```python
# billing/management/commands/initialize_data.py

from django.core.management.base import BaseCommand
from billing.models import ServiceType, Customer

class Command(BaseCommand):
    help = 'Initialize default data for the ERP system'
    
    def handle(self, *args, **options):
        # Create default service types
        service_types = [
            {'name': 'SKU Picking', 'unit': 'per_sku', 'category': 'pick_pack_ship', 'base_rate': 0.50},
            {'name': 'Unit Picking', 'unit': 'per_unit', 'category': 'pick_pack_ship', 'base_rate': 0.75},
            {'name': 'Case Picking', 'unit': 'per_case', 'category': 'pick_pack_ship', 'base_rate': 2.00},
            {'name': 'Pallet Picking', 'unit': 'per_pallet', 'category': 'pick_pack_ship', 'base_rate': 15.00},
            {'name': 'Standard Packing', 'unit': 'per_unit', 'category': 'pick_pack_ship', 'base_rate': 1.00},
            {'name': 'Gift Wrapping', 'unit': 'per_unit', 'category': 'pick_pack_ship', 'base_rate': 3.00},
            {'name': 'Shipping Processing', 'unit': 'per_shipment', 'category': 'pick_pack_ship', 'base_rate': 2.50},
            {'name': 'Standard Postage', 'unit': 'per_shipment', 'category': 'freight', 'base_rate': 5.00},
            {'name': 'Express Courier', 'unit': 'per_shipment', 'category': 'freight', 'base_rate': 15.00},
            {'name': 'LTL Freight', 'unit': 'per_pallet', 'category': 'freight', 'base_rate': 75.00},
            {'name': 'FTL Freight', 'unit': 'per_truck', 'category': 'freight', 'base_rate': 1500.00},
            {'name': 'Custom Kitting', 'unit': 'per_project', 'category': 'special_projects', 'is_custom_pricing': True},
            {'name': 'Product Assembly', 'unit': 'per_unit', 'category': 'special_projects', 'base_rate': 5.00},
            {'name': 'Relabeling', 'unit': 'per_unit', 'category': 'special_projects', 'base_rate': 0.25},
            {'name': 'Packaging Materials', 'unit': 'per_unit', 'category': 'materials', 'base_rate': 1.50},
            {'name': 'Pallet Storage', 'unit': 'per_pallet', 'category': 'materials', 'base_rate': 25.00},
        ]
        
        for service_data in service_types:
            ServiceType.objects.get_or_create(
                name=service_data['name'],
                defaults=service_data
            )
        
        self.stdout.write(self.style.SUCCESS('Successfully initialized default data'))
```

## External Dependencies

### Python Packages (requirements.txt)
```
Django==5.0.1
psycopg2-binary==2.9.9
django-environ==0.11.2
django-crispy-forms==2.1
crispy-bootstrap5==2023.10
django-filter==23.5
djangorestframework==3.14.0
django-cors-headers==4.3.1
Pillow==10.2.0
reportlab==4.0.8
pandas==2.1.4
openpyxl==3.1.2
sendgrid==6.11.0
django-sendgrid-v5==1.2.3
whitenoise==6.6.0
gunicorn==21.2.0
celery==5.3.4
redis==5.0.1
django-celery-beat==2.5.0
django-storages==1.14.2
boto3==1.34.14
matplotlib==3.8.2
django-extensions==3.2.3
django-debug-toolbar==4.2.0
```

### Frontend Libraries
- **Bootstrap 5.3.0**: UI framework loaded via CDN for responsive design
- **HTMX 1.9.10**: For dynamic server interactions without full page reloads
- **Alpine.js 3.13.3**: Lightweight JavaScript framework for reactive components
- **Font Awesome 6.4.0**: Icon library for consistent visual elements
- **Chart.js 4.4.1**: For dashboard charts and analytics
- **DataTables 1.13.7**: Enhanced table functionality with sorting and filtering

### Development Tools
- **Django Debug Toolbar**: Development debugging and profiling
- **Django Extensions**: Additional management commands and model utilities
- **Black**: Python code formatter
- **isort**: Import statement organizer
- **pytest-django**: Testing framework

## Deployment Configuration (Replit)

```python
# .replit
entrypoint = "manage.py"
run = "python manage.py runserver 0.0.0.0:8000"

[env]
DJANGO_SETTINGS_MODULE = "erp_project.settings"

[packager]
language = "python3"

[packager.features]
enabledForHosting = false
packageSearch = true
guessImports = true

[[ports]]
localPort = 8000
externalPort = 80
```

```python
# replit.nix
{ pkgs }: {
  deps = [
    pkgs.python311
    pkgs.postgresql_15
    pkgs.nodejs_20
  ];
}
```

## Future Integration Possibilities
- **Django REST Framework**: Full API for mobile apps and third-party integrations
- **Celery**: Asynchronous task processing for email delivery and report generation
- **Django Channels**: WebSocket support for real-time inventory updates
- **Django-Q**: Lightweight task queue for background jobs
- **Stripe/PayPal Integration**: Online payment processing
- **AWS S3**: Document and invoice storage
- **Elasticsearch**: Advanced search capabilities
- **Grafana/Prometheus**: Advanced monitoring and analytics
- **Multi-tenancy**: Support for multiple 3PL companies in one instance
- **Barcode/QR Code Generation**: For product labels and tracking
- **Mobile App**: React Native or Flutter app using Django REST API
- **Webhook System**: For real-time integration with external systems
