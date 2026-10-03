# Grocery Customer App (Flutter)

This is the **Customer app** for the grocery delivery project. It currently runs
on **dummy/local data** (see `lib/data/dummy_data.dart`) so you can see and test
the full UI before the PHP backend is ready.

## Features included (MVP)
- Splash screen
- Phone + OTP login flow (mocked)
- Home: banners, categories, product grid, search bar (UI only)
- Category → product listing
- Product detail page with quantity stepper
- Cart with quantity controls and price summary
- Address selection (dummy addresses)
- Checkout: delivery/pickup toggle, payment method, coupon code
- Order success + order tracking (status timeline)
- Order history
- Profile screen with logout

## How to run in VS Code

1. Install Flutter SDK: https://docs.flutter.dev/get-started/install
2. Install the **Flutter** and **Dart** extensions in VS Code.
3. Open this folder (`customer_app`) in VS Code.
4. In the terminal, run:
   ```
   flutter pub get
   ```
5. Connect a device/emulator (or press F5 to launch), then run:
   ```
   flutter run
   ```

## Next step: connecting to the real PHP backend

Every place that needs real data has a `// TODO:` comment, mainly in:
- `lib/providers/auth_provider.dart` (OTP send/verify)
- `lib/providers/order_provider.dart` (place order)
- `lib/screens/checkout/checkout_screen.dart` (coupon apply)
- `lib/data/dummy_data.dart` (categories/products — will be replaced by API calls)

When the backend is ready, we'll add a `lib/services/api_service.dart` file that
wraps `http` package calls to your Hostinger PHP API (e.g.
`https://yourdomain.com/api/...`), and swap the dummy data calls for real
network calls + loading/error states.

## Notes
- Colors/branding: edit `lib/utils/app_colors.dart` to match your store's logo/colors.
- Product images currently use Unsplash placeholder URLs — replace with your
  real product photos once the backend serves them.
- Google Maps for live address picking / delivery tracking is not wired in yet
  (marked with TODOs) — we'll add `google_maps_flutter` when we get to that stage.
