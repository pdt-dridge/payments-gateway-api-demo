# Payments Gateway API - Endpoints Documentation

## Base URLs

- **Production:** `https://api.payments.example.com/v1`
- **Staging:** `https://api-staging.payments.example.com/v1`
- **Development:** `http://localhost:8080/v1`

## Authentication

All API requests require authentication using an API key.

```http
Authorization: Bearer YOUR_API_KEY
```

## Common Headers

```http
Content-Type: application/json
X-Request-ID: unique-request-id
X-Idempotency-Key: unique-idempotency-key (for POST/PUT requests)
```

## Endpoints

### Health Check

#### GET /health
Check API health status

**Response:**
```json
{
  "status": "healthy",
  "version": "v1.2.3",
  "timestamp": "2026-03-19T10:30:00Z",
  "checks": {
    "database": "healthy",
    "cache": "healthy",
    "stripe": "healthy",
    "paypal": "healthy"
  }
}
```

### Payments

#### POST /payments
Create a new payment

**Request:**
```json
{
  "amount": 10000,
  "currency": "USD",
  "payment_method": "card",
  "payment_method_id": "pm_1234567890",
  "customer_id": "cus_1234567890",
  "description": "Order #12345",
  "metadata": {
    "order_id": "12345",
    "customer_email": "customer@example.com"
  }
}
```

**Response (Success):**
```json
{
  "id": "pay_1234567890",
  "status": "succeeded",
  "amount": 10000,
  "currency": "USD",
  "created_at": "2026-03-19T10:30:00Z",
  "payment_method": "card",
  "customer_id": "cus_1234567890"
}
```

**Response (Failure):**
```json
{
  "error": {
    "code": "payment_failed",
    "message": "Your card was declined",
    "type": "card_error",
    "param": "payment_method_id"
  }
}
```

#### GET /payments/:id
Retrieve payment details

**Response:**
```json
{
  "id": "pay_1234567890",
  "status": "succeeded",
  "amount": 10000,
  "currency": "USD",
  "created_at": "2026-03-19T10:30:00Z",
  "updated_at": "2026-03-19T10:30:05Z",
  "payment_method": "card",
  "customer_id": "cus_1234567890",
  "description": "Order #12345",
  "metadata": {
    "order_id": "12345"
  }
}
```

#### GET /payments
List payments

**Query Parameters:**
- `customer_id` (optional): Filter by customer
- `status` (optional): Filter by status (succeeded, failed, pending)
- `limit` (optional): Number of results (default: 10, max: 100)
- `starting_after` (optional): Cursor for pagination

**Response:**
```json
{
  "data": [
    {
      "id": "pay_1234567890",
      "status": "succeeded",
      "amount": 10000,
      "currency": "USD",
      "created_at": "2026-03-19T10:30:00Z"
    }
  ],
  "has_more": true,
  "next_cursor": "pay_0987654321"
}
```

#### POST /payments/:id/refund
Refund a payment

**Request:**
```json
{
  "amount": 5000,
  "reason": "customer_request"
}
```

**Response:**
```json
{
  "id": "ref_1234567890",
  "payment_id": "pay_1234567890",
  "amount": 5000,
  "status": "succeeded",
  "created_at": "2026-03-19T11:00:00Z"
}
```

### Customers

#### POST /customers
Create a new customer

**Request:**
```json
{
  "email": "customer@example.com",
  "name": "John Doe",
  "phone": "+1234567890",
  "metadata": {
    "user_id": "12345"
  }
}
```

**Response:**
```json
{
  "id": "cus_1234567890",
  "email": "customer@example.com",
  "name": "John Doe",
  "created_at": "2026-03-19T10:00:00Z"
}
```

#### GET /customers/:id
Retrieve customer details

#### PUT /customers/:id
Update customer information

#### DELETE /customers/:id
Delete a customer

### Payment Methods

#### POST /payment-methods
Add a payment method

**Request:**
```json
{
  "type": "card",
  "customer_id": "cus_1234567890",
  "card": {
    "number": "4242424242424242",
    "exp_month": 12,
    "exp_year": 2027,
    "cvc": "123"
  }
}
```

**Response:**
```json
{
  "id": "pm_1234567890",
  "type": "card",
  "customer_id": "cus_1234567890",
  "card": {
    "brand": "visa",
    "last4": "4242",
    "exp_month": 12,
    "exp_year": 2027
  },
  "created_at": "2026-03-19T10:00:00Z"
}
```

#### GET /payment-methods/:id
Retrieve payment method details

#### DELETE /payment-methods/:id
Delete a payment method

### Webhooks

#### POST /webhooks/stripe
Stripe webhook endpoint (internal use)

#### POST /webhooks/paypal
PayPal webhook endpoint (internal use)

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `invalid_request` | 400 | Invalid request parameters |
| `authentication_failed` | 401 | Invalid API key |
| `not_found` | 404 | Resource not found |
| `rate_limit_exceeded` | 429 | Too many requests |
| `payment_failed` | 402 | Payment processing failed |
| `insufficient_funds` | 402 | Insufficient funds |
| `card_declined` | 402 | Card was declined |
| `internal_error` | 500 | Internal server error |
| `service_unavailable` | 503 | Service temporarily unavailable |

## Rate Limiting

- **Limit:** 1000 requests per minute per API key
- **Burst:** 2000 requests

**Headers:**
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 950
X-RateLimit-Reset: 1710842400
```

## Idempotency

Use the `X-Idempotency-Key` header for POST requests to ensure idempotent operations.

```http
X-Idempotency-Key: unique-key-12345
```

## Pagination

List endpoints support cursor-based pagination.

**Request:**
```http
GET /payments?limit=10&starting_after=pay_1234567890
```

**Response:**
```json
{
  "data": [...],
  "has_more": true,
  "next_cursor": "pay_0987654321"
}
```

## Versioning

The API uses URL versioning. Current version: `v1`

## Testing

### Test API Keys
- **Staging:** `sk_test_1234567890`

### Test Cards
- **Success:** `4242424242424242`
- **Decline:** `4000000000000002`
- **Insufficient Funds:** `4000000000009995`

## SDKs

- **Python:** `pip install payments-gateway-sdk`
- **Node.js:** `npm install payments-gateway-sdk`
- **Go:** `go get github.com/example/payments-gateway-sdk`
