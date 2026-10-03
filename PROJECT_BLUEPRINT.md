# Grocery Delivery App — Project Blueprint

Inspired by: Jamil Sweets (Indolj platform) style food/grocery ordering app.
**Stack:** Flutter (Customer app + Delivery Boy app) + PHP REST API + MySQL (Hostinger) + PHP Web Admin Panel

---

## 1. System Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Customer App    │     │  Delivery Boy App │     │   Admin Panel    │
│  (Flutter)       │     │  (Flutter)        │     │  (PHP + HTML/JS) │
└────────┬─────────┘     └─────────┬─────────┘     └────────┬─────────┘
         │                          │                         │
         └──────────────┬───────────┴─────────────┬───────────┘
                         │  REST API (JSON, HTTPS) │
                         ▼                         ▼
                 ┌───────────────────────────────────┐
                 │        PHP Backend (Hostinger)      │
                 │   - api/ (REST endpoints)           │
                 │   - admin/ (web dashboard)          │
                 │   - uploads/ (product images)       │
                 └────────────────┬────────────────────┘
                                  ▼
                         ┌─────────────────┐
                         │  MySQL Database  │
                         │  (phpMyAdmin)    │
                         └─────────────────┘
```

**Why this structure:**
- One shared MySQL database + one PHP API layer serves all 3 apps.
- Customer & Delivery Boy = separate Flutter apps (separate APKs) — cleaner than one app with role-switching, and matches how real apps like this ship (2 apps on Play Store: customer app + rider app).
- Admin Panel = plain PHP + Bootstrap web dashboard (fastest to build on Hostinger, no separate hosting needed, works with phpMyAdmin directly).

---

## 2. Database Schema (MySQL)

### `users` (customers)
| Column | Type |
|---|---|
| id | INT PK AI |
| name | VARCHAR(100) |
| phone | VARCHAR(20) UNIQUE |
| email | VARCHAR(100) NULL |
| password | VARCHAR(255) (hashed) |
| otp | VARCHAR(6) NULL |
| otp_expires_at | DATETIME NULL |
| profile_image | VARCHAR(255) NULL |
| is_active | TINYINT(1) DEFAULT 1 |
| created_at | TIMESTAMP |

### `addresses`
| id | user_id (FK) | label (Home/Work) | address_line | area | city | latitude | longitude | is_default |

### `admins`
| id | name | email | password | role (super_admin/manager) | created_at |

### `delivery_boys`
| id | name | phone | password | cnic | vehicle_type | profile_image | is_online | is_active | current_lat | current_lng | created_at |

### `categories`
| id | name | image | sort_order | is_active |

### `products`
| id | category_id (FK) | name | description | image | price | discount_price | unit (kg/pcs/litre) | stock_qty | is_available | created_at |

### `banners` (home page promo sliders)
| id | image | link_product_id | sort_order | is_active |

### `coupons`
| id | code | discount_type (flat/percent) | value | min_order_amount | expiry_date | usage_limit | is_active |

### `orders`
| Column | Type |
|---|---|
| id | INT PK AI |
| order_number | VARCHAR(20) UNIQUE |
| user_id | FK → users |
| address_id | FK → addresses |
| delivery_boy_id | FK → delivery_boys, NULL |
| order_type | ENUM('delivery','pickup') |
| subtotal | DECIMAL(10,2) |
| delivery_fee | DECIMAL(10,2) |
| discount | DECIMAL(10,2) |
| total_amount | DECIMAL(10,2) |
| payment_method | ENUM('cod','card','wallet') |
| payment_status | ENUM('pending','paid','failed') |
| order_status | ENUM('placed','confirmed','preparing','ready','picked_up','on_the_way','delivered','cancelled') |
| coupon_code | VARCHAR(20) NULL |
| notes | TEXT NULL |
| created_at | TIMESTAMP |

### `order_items`
| id | order_id (FK) | product_id (FK) | quantity | price | subtotal |

### `order_status_history` (for tracking timeline)
| id | order_id | status | changed_at |

### `reviews`
| id | order_id | user_id | rating (1-5) | comment | created_at |

### `notifications`
| id | user_id / delivery_boy_id | title | message | is_read | created_at |

### `settings` (app-wide config)
| key | value  → e.g. delivery_fee_per_km, min_order_amount, app_version |

---

## 3. REST API Endpoints (PHP — `/api/`)

**Auth**
- `POST /auth/register` — customer signup
- `POST /auth/send-otp` / `POST /auth/verify-otp`
- `POST /auth/login` (customer, delivery boy, admin — separate endpoints)

**Customer app**
- `GET /categories`
- `GET /products?category_id=`
- `GET /products/{id}`
- `GET /banners`
- `POST /cart/checkout`
- `GET /orders` (user's order history)
- `GET /orders/{id}` (track single order)
- `POST /orders/{id}/cancel`
- `GET/POST/PUT/DELETE /addresses`
- `POST /coupons/apply`
- `POST /reviews`

**Delivery boy app**
- `GET /delivery/orders/available` (unassigned, nearby)
- `POST /delivery/orders/{id}/accept`
- `PUT /delivery/orders/{id}/status` (picked_up → on_the_way → delivered)
- `POST /delivery/location/update` (live lat/lng)
- `GET /delivery/earnings`
- `PUT /delivery/availability` (online/offline toggle)

**Admin panel (session-based, not token)**
- Manage categories/products (CRUD + image upload)
- Manage orders (assign delivery boy, change status)
- Manage delivery boys & customers
- Manage coupons & banners
- Dashboard: sales stats, order counts, top products

---

## 4. Flutter App 1 — Customer App (Screens)

1. Splash → Login/Signup (Phone + OTP)
2. Home (banners, categories, featured products, search)
3. Category → Product listing
4. Product detail (qty selector, add to cart)
5. Cart
6. Address selection / Add new address (map picker)
7. Delivery or Pickup toggle
8. Checkout (coupon, payment method, order summary)
9. Order placed confirmation
10. Order tracking (live status + map when out for delivery)
11. Order history
12. Profile / Edit profile
13. Notifications

## 5. Flutter App 2 — Delivery Boy App (Screens)

1. Login
2. Home — online/offline toggle + available orders list
3. Order detail (customer info, address, map navigation)
4. Accept / Reject order
5. Update status (Picked up → On the way → Delivered) with OTP/photo proof at delivery
6. Earnings / order history
7. Profile

## 6. Admin Panel (Web — PHP)

1. Login
2. Dashboard (today's orders, revenue, pending orders)
3. Categories management
4. Products management (with image upload, stock)
5. Orders management (list, filter by status, assign rider, view details)
6. Delivery boys management (add/block, view live location)
7. Customers management
8. Coupons & Banners
9. Reports (sales by date/category)
10. Settings (delivery fee, min order, etc.)

---

## 7. Folder Structure

**Backend (Hostinger — `public_html/`)**
```
public_html/
├── api/
│   ├── config/db.php
│   ├── auth/
│   ├── products/
│   ├── orders/
│   ├── delivery/
│   └── helpers/ (jwt.php, response.php, upload.php)
├── admin/
│   ├── login.php
│   ├── dashboard.php
│   ├── products.php
│   ├── orders.php
│   ├── assets/ (css, js, bootstrap)
│   └── includes/ (header.php, sidebar.php, db.php)
└── uploads/
    ├── products/
    └── profiles/
```

**Flutter (each app)**
```
lib/
├── main.dart
├── models/
├── services/ (api_service.dart)
├── screens/
├── widgets/
├── providers/ (state management — Provider or Riverpod)
└── utils/
```

---

## 8. Development Roadmap (suggested order)

1. **Database** — create all tables in phpMyAdmin
2. **Backend API core** — DB connection, auth (OTP/login), JWT for Flutter apps
3. **Admin Panel** — categories & products CRUD first (so we have data to show)
4. **Customer App** — home, browse, cart, checkout, orders
5. **Delivery Boy App** — order list, accept, status updates
6. **Order flow integration** — admin assigns rider → rider updates status → customer sees live tracking
7. **Payments** (COD first, online payment gateway later — e.g. JazzCash/Easypaisa for Pakistan)
8. **Push notifications** (Firebase Cloud Messaging)
9. **Testing & polish**
10. **Play Store deployment**

---

## Notes
- Authentication for Flutter apps: use **JWT tokens** (PHP `firebase/php-jwt` package) since Flutter apps are stateless clients — session cookies (used for admin panel) don't work well for mobile apps.
- Use `PDO` with prepared statements in PHP (never raw string concatenation in SQL) to avoid SQL injection.
- Store passwords with `password_hash()` / `password_verify()`.
- For live delivery boy tracking, poll location every 10-15 seconds or use Firebase Realtime Database for smoother live updates.
