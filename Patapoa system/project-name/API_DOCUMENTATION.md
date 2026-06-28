# Patapoa API Documentation

## Base URL
```
http://localhost:8000/api/v1
```

## Authentication
Most endpoints require authentication using Laravel Sanctum. Include the token in the Authorization header:
```
Authorization: Bearer {token}
```

---

## Authentication Endpoints

### Register
```http
POST /api/v1/auth/register
```

**Request Body:**
```json
{
  "name": "John Doe",
  "phone": "+255700000000",
  "email": "john@example.com",
  "password": "password123",
  "user_type": "customer"
}
```

**Response:**
```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "phone": "+255700000000",
    "email": "john@example.com",
    "user_type": "customer"
  },
  "token": "access_token_here"
}
```

### Login
```http
POST /api/v1/auth/login
```

**Request Body:**
```json
{
  "phone": "+255700000000",
  "password": "password123"
}
```

### Send OTP
```http
POST /api/v1/auth/otp/send
```

**Request Body:**
```json
{
  "phone": "+255700000000"
}
```

### Verify OTP
```http
POST /api/v1/auth/otp/verify
```

**Request Body:**
```json
{
  "phone": "+255700000000",
  "otp": "123456"
}
```

### Logout
```http
POST /api/v1/auth/logout
```
**Requires Authentication**

### Get Current User
```http
GET /api/v1/auth/me
```
**Requires Authentication**

---

## User Management

### Update User
```http
PUT /api/v1/users/{id}
```
**Requires Authentication**

### Update Location
```http
PUT /api/v1/users/{id}/location
```
**Requires Authentication**

**Request Body:**
```json
{
  "latitude": -6.8235,
  "longitude": 39.2695
}
```

### Update FCM Token
```http
PUT /api/v1/users/{id}/fcm-token
```
**Requires Authentication**

**Request Body:**
```json
{
  "fcm_token": "device_fcm_token"
}
```

---

## Addresses

### List Addresses
```http
GET /api/v1/addresses
```
**Requires Authentication**

### Create Address
```http
POST /api/v1/addresses
```
**Requires Authentication**

**Request Body:**
```json
{
  "label": "Home",
  "recipient_name": "John Doe",
  "phone": "+255700000000",
  "address_line_1": "123 Main Street",
  "address_line_2": "Apartment 4B",
  "city": "Dar es Salaam",
  "region": "Dar es Salaam",
  "latitude": -6.8235,
  "longitude": 39.2695
}
```

### Update Address
```http
PUT /api/v1/addresses/{id}
```
**Requires Authentication**

### Delete Address
```http
DELETE /api/v1/addresses/{id}
```
**Requires Authentication**

### Set Default Address
```http
PUT /api/v1/addresses/{id}/default
```
**Requires Authentication**

---

## Categories (Public)

### List Categories
```http
GET /api/v1/categories
```

### Get Category
```http
GET /api/v1/categories/{id}
```

---

## Products

### List Products (Public)
```http
GET /api/v1/products
```

**Query Parameters:**
- `category_id` - Filter by category
- `merchant_id` - Filter by merchant
- `q` - Search query
- `featured` - Show featured products only (true/false)

### Get Product (Public)
```http
GET /api/v1/products/{id}
```

### Create Product (Merchant Only)
```http
POST /api/v1/merchant/products
```
**Requires Authentication (Merchant)**

**Request Body:**
```json
{
  "category_id": 1,
  "name": "Product Name",
  "description": "Product description",
  "images": ["image1.jpg", "image2.jpg"],
  "price": 15000,
  "compare_price": 20000,
  "stock_count": 50,
  "is_available": true,
  "is_featured": false,
  "attributes": {}
}
```

### Update Product (Merchant Only)
```http
PUT /api/v1/merchant/products/{id}
```
**Requires Authentication (Merchant)**

### Delete Product (Merchant Only)
```http
DELETE /api/v1/merchant/products/{id}
```
**Requires Authentication (Merchant)**

### List Merchant Products (Merchant Only)
```http
GET /api/v1/merchant/products
```
**Requires Authentication (Merchant)**

---

## Orders

### Create Order (Customer Only)
```http
POST /api/v1/customer/orders
```
**Requires Authentication (Customer)**

**Request Body:**
```json
{
  "address_id": 1,
  "items": [
    {
      "product_id": 1,
      "quantity": 2
    }
  ],
  "customer_notes": "Please call before delivery",
  "payment_method": "mpesa"
}
```

### List Customer Orders (Customer Only)
```http
GET /api/v1/customer/orders
```
**Requires Authentication (Customer)**

### Get Order (Customer Only)
```http
GET /api/v1/customer/orders/{id}
```
**Requires Authentication (Customer)**

### Get Order Tracking
```http
GET /api/v1/orders/{id}/tracking
```
**Requires Authentication**

### Cancel Order
```http
PUT /api/v1/orders/{id}/cancel
```
**Requires Authentication**

---

## Merchant Endpoints

### Merchant Dashboard
```http
GET /api/v1/merchant/dashboard
```
**Requires Authentication (Merchant)**

### List Merchant Orders
```http
GET /api/v1/merchant/orders
```
**Requires Authentication (Merchant)**

### Update Order Status (Merchant Only)
```http
PUT /api/v1/merchant/orders/{id}/status
```
**Requires Authentication (Merchant)**

**Request Body:**
```json
{
  "status": "confirmed"
}
```

**Valid Statuses:** `confirmed`, `preparing`, `ready_for_pickup`

---

## Rider Endpoints

### Update Location
```http
POST /api/v1/rider/location
```
**Requires Authentication (Rider)**

**Request Body:**
```json
{
  "latitude": -6.8235,
  "longitude": 39.2695
}
```

### Go Online
```http
POST /api/v1/rider/online
```
**Requires Authentication (Rider)**

### Go Offline
```http
POST /api/v1/rider/offline
```
**Requires Authentication (Rider)**

### Get Available Orders
```http
GET /api/v1/rider/available-orders
```
**Requires Authentication (Rider)**

### Accept Order
```http
POST /api/v1/rider/orders/{id}/accept
```
**Requires Authentication (Rider)**

### Update Order Status (Rider Only)
```http
PUT /api/v1/rider/orders/{id}/status
```
**Requires Authentication (Rider)**

**Request Body:**
```json
{
  "status": "picked_up",
  "latitude": -6.8235,
  "longitude": 39.2695
}
```

**Valid Statuses:** `rider_heading_to_pickup`, `at_pickup`, `picked_up`, `heading_to_customer`, `at_dropoff`, `delivered`

### Get Earnings
```http
GET /api/v1/rider/earnings
```
**Requires Authentication (Rider)**

### Request Payout
```http
POST /api/v1/rider/payout/request
```
**Requires Authentication (Rider)**

**Request Body:**
```json
{
  "amount": 5000,
  "payout_method": "mpesa"
}
```

---

## Wallet & Payments

### Get Wallet
```http
GET /api/v1/wallet
```
**Requires Authentication**

### List Transactions
```http
GET /api/v1/transactions
```
**Requires Authentication**

### Initiate Payment
```http
POST /api/v1/payments/initiate
```
**Requires Authentication**

**Request Body:**
```json
{
  "order_id": 1,
  "payment_method": "mpesa"
}
```

**Payment Methods:** `mpesa`, `tigo_pesa`, `wallet`, `cash`

### Payment Callback
```http
POST /api/v1/payments/callback
```
**Webhook endpoint for M-Pesa/Tigo Pesa callbacks**

---

## Notifications

### List Notifications
```http
GET /api/v1/notifications
```
**Requires Authentication**

### Mark as Read
```http
PUT /api/v1/notifications/{id}/read
```
**Requires Authentication**

### Mark All as Read
```http
POST /api/v1/notifications/read-all
```
**Requires Authentication**

---

## Admin Endpoints

### Admin Dashboard
```http
GET /api/v1/admin/dashboard
```
**Requires Authentication (Admin)**

### List All Orders
```http
GET /api/v1/admin/orders
```
**Requires Authentication (Admin)**

### List All Merchants
```http
GET /api/v1/admin/merchants
```
**Requires Authentication (Admin)**

### List All Riders
```http
GET /api/v1/admin/riders
```
**Requires Authentication (Admin)**

### List All Transactions
```http
GET /api/v1/admin/transactions
```
**Requires Authentication (Admin)**

### Verify Merchant
```http
POST /api/v1/admin/merchants/{id}/verify
```
**Requires Authentication (Admin)**

### Verify Rider
```http
POST /api/v1/admin/riders/{id}/verify
```
**Requires Authentication (Admin)**

---

## Order Status Flow

```
cart → placed → confirmed → preparing → ready_for_pickup → rider_assigned
→ rider_heading_to_pickup → at_pickup → picked_up → heading_to_customer
→ at_dropoff → delivered → completed
```

**Additional statuses:** `cancelled`, `refunded`

---

## Error Responses

All errors return JSON in the following format:

```json
{
  "message": "Error message",
  "errors": {
    "field": ["Error details"]
  }
}
```

**HTTP Status Codes:**
- `200` - Success
- `201` - Created
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `422` - Validation Error
- `500` - Server Error

---

## Notes

1. **Currency:** All amounts are in TZS (Tanzanian Shilling)
2. **Pagination:** Most list endpoints support pagination with `page` parameter
3. **Rate Limiting:** Implement rate limiting for production
4. **M-Pesa Integration:** STK Push integration needs to be completed with actual M-Pesa API
5. **Push Notifications:** FCM integration needs to be implemented
6. **Real-time Updates:** Consider implementing WebSocket for real-time order tracking

---

## Test Credentials

**Admin:**
- Phone: +255700000000
- Password: admin123

**Categories Seeded:**
1. Electronics
2. Groceries
3. Fashion
4. Home & Living
5. Health & Beauty
6. Sports & Outdoors
7. Books & Stationery
8. Hardware
