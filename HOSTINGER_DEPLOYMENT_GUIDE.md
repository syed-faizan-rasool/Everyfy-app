# 🚀 Everyfy (everyfy.net) — Hostinger Backend & Database Complete Guide

Assalam-o-Alaikum! Mubarak ho, aapka Hostinger server purchase ho chuka hai aur domain **everyfy.net** ke liye **complete PHP REST API backend, MySQL database schema, Web Admin Panel aur Flutter integration** ready kar di gayi hai.

Aapke project root folder mein **`everyfy_backend.zip`** ready hai jo aap direct Hostinger par upload kar sakte hain.

---

## 📸 Step 1: Hostinger par Backend Upload Karna (From your Screenshot)

Hostinger ki jo screen aapne share ki hai:
> **"How do you want to set up your website?"**
> 1. Select **"Upload website files (.zip)"**
> 2. Browse karke apne computer se yeh file select karein:
>    📁 `d:\freshUp\everyfy_backend.zip`
> 3. Click **"Next"**

Hostinger khud hi is zip file ko aapke domain ke `public_html/` folder mein extract kar dega!

*(Agar aap File Manager use karna chahein to: Hostinger hPanel ➔ File Manager ➔ `public_html` ➔ Upload `everyfy_backend.zip` ➔ Extract).*

---

## 🗄️ Step 2: Hostinger par MySQL Database Create Karna

1. Hostinger **hPanel** open karein.
2. Left menu se **Databases** ➔ **MySQL Databases** par click karein.
3. Naya Database create karein:
   - **MySQL Database Name:** e.g. `u123456789_everyfy`
   - **MySQL Username:** e.g. `u123456789_admin`
   - **Password:** Koi bhi strong password rakhein (isko copy kar lein)
4. Click **Create**.

---

## ⚡ Step 3: 1-Click Auto Setup Wizard Chalana (Sab se Aasan!)

Aapko phpMyAdmin mein manual SQL run karne ki bhi zaroorat nahi hai! Humne ek automated web installer banaya hai:

1. Browser mein yeh URL open karein:
   👉 **`https://everyfy.net/setup.php`**
2. Screen par Hostinger ka Database Name, Username aur Password enter karein.
3. Click **"Test Connection & Save Settings"**.
4. Jab green signal aa jaye, click **"Import Tables & Seed Data Now"**!
5. **Dhamaka!** Saray tables (Users, Products, Categories, Orders, Riders, Coupons, Settings) automatically create ho jayenge aur ready-to-use demo data load ho jayega!

*(Agar aap phpMyAdmin se direct import karna chahein to file `backend/database/everyfy_db.sql` ko phpMyAdmin mein Import tab se upload kar sakte hain).*

---

## 👑 Step 4: Web Admin Panel Access Karna

Aapka full-featured modern store dashboard online ready hai:

👉 **URL:** `https://everyfy.net/admin/login.php`

### 🔑 Default Credentials:
- **Email:** `admin@everyfy.net`
- **Password:** `admin123456`

### Admin Panel mein aap kya kya kar sakte hain:
- 📊 **Dashboard:** Real-time revenue, today orders count, active riders, low-stock alerts.
- 📦 **Products Catalog:** Naye products add karna, pictures upload karna, prices aur discounts set karna, stock manage karna.
- 🗂️ **Categories:** Categories create karna (Fruits, Veggies, Dairy, Bakery, etc.).
- 🛵 **Riders Fleet:** Delivery boys create karna, unki ratings aur live status dekhna.
- 🧾 **Orders Management:** Placed orders dekhna, rider ko assign karna, status change karna (Preparing ➔ On the Way ➔ Delivered).
- 🏷️ **Coupons:** Discount promo codes create karna (e.g. `FRESH20`).

---

## 📡 Step 5: REST APIs Test Karna

Mobile apps (Customer & Delivery Boy) ke liye saari APIs ready hain:

👉 **API Explorer URL:** `https://everyfy.net/api/index.php`

### Main Endpoints Summary:
| Category | Method & Endpoint | Description |
|---|---|---|
| **Auth** | `POST /api/auth/send_otp.php` | Customer phone number par OTP bhejna |
| **Auth** | `POST /api/auth/verify_otp.php` | OTP verify karke JWT Token lena (Use `1234` for testing) |
| **Auth** | `POST /api/auth/login.php` | Phone/Password se login |
| **Products** | `GET /api/products/index.php` | Grocery products list (filter by category, search) |
| **Categories** | `GET /api/categories/index.php` | All grocery departments |
| **Banners** | `GET /api/banners/index.php` | Home page promo sliders |
| **Coupons** | `POST /api/coupons/apply.php` | Promo code test & discount calculation |
| **Addresses** | `GET/POST /api/addresses/index.php` | Customer delivery addresses |
| **Orders** | `POST /api/orders/checkout.php` | Naya grocery order place karna |
| **Orders** | `GET /api/orders/index.php` | Customer order history |
| **Orders** | `GET /api/orders/detail.php` | Live order tracking & rider details |
| **Rider** | `POST /api/delivery/login.php` | Delivery Boy app login |
| **Rider** | `GET /api/delivery/orders/available.php` | Unassigned orders list |
| **Rider** | `POST /api/delivery/orders/accept.php` | Rider order accept kare |
| **Rider** | `POST /api/delivery/orders/status.php` | Picked Up ➔ On the Way ➔ Delivered |
| **Admin** | `GET /api/admin/stats.php` | Realtime analytics & counter data |

---

## 📱 Step 6: Flutter Customer App Integration

Flutter customer app mein `lib/services/api_service.dart` bana kar base URL **`https://everyfy.net/api`** set kar diya gaya hai.

### Test Logins for Apps:
- **Customer App:** Kisi bhi phone number se Login karein ➔ OTP screen par `1234` enter karein.
- **Delivery Boy App:** Phone: `03019876543` ➔ Password: `1234`.
- **Admin:** Email: `admin@everyfy.net` ➔ Password: `admin123456`.
- **Promo Coupon:** `FRESH20` (Flat Rs 50 OFF).
