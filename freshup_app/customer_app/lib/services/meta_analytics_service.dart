import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

/// Centralized Meta (Facebook) App Events Tracking Service for EVERYFY
/// Directly integrates with Meta Ads & Meta Events Manager
class MetaAnalyticsService {
  static final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();
  static bool _initialized = false;

  /// Initialize Meta SDK and log App Activation (Install / Open)
  static Future<void> init() async {
    if (_initialized) return;
    try {
      await _facebookAppEvents.setAdvertiserIdCollectionEnabled(true);
      await _facebookAppEvents.setAutoLogAppEventsEnabled(true);
      _initialized = true;
      debugPrint('[Meta Analytics] Initialized successfully.');
    } catch (e) {
      debugPrint('[Meta Analytics] Initialization notice: $e');
    }
  }

  /// 1. App Install / Activation Event
  static Future<void> logActivateApp() async {
    try {
      await init();
      // Auto-logged by Meta SDK when setAutoLogAppEventsEnabled is true
      debugPrint('[Meta Analytics] Event: App Activated / Installed');
    } catch (e) {
      debugPrint('[Meta Analytics] Error logging App Activation: $e');
    }
  }

  /// 2. Complete Registration Event
  static Future<void> logCompleteRegistration({
    String registrationMethod = 'phone_otp',
    String? userId,
  }) async {
    try {
      if (userId != null && userId.isNotEmpty) {
        await _facebookAppEvents.setUserID(userId);
      }
      await _facebookAppEvents.logCompletedRegistration(
        registrationMethod: registrationMethod,
      );
      debugPrint('[Meta Analytics] Event: CompleteRegistration ($registrationMethod)');
    } catch (e) {
      debugPrint('[Meta Analytics] Error logging Registration: $e');
    }
  }

  /// 3. View Content Event (Product View)
  static Future<void> logViewContent({
    required String id,
    required String title,
    required double price,
    String type = 'product',
    String currency = 'PKR',
  }) async {
    try {
      await _facebookAppEvents.logViewContent(
        id: id,
        type: type,
        price: price,
        currency: currency,
      );
      debugPrint('[Meta Analytics] Event: ViewContent ($title - Rs $price)');
    } catch (e) {
      debugPrint('[Meta Analytics] Error logging ViewContent: $e');
    }
  }

  /// 4. Search Event
  static Future<void> logSearch({
    required String query,
    bool success = true,
  }) async {
    if (query.trim().isEmpty) return;
    try {
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_search',
        parameters: {
          'fb_search_string': query.trim(),
          'fb_success': success ? 1 : 0,
        },
      );
      debugPrint('[Meta Analytics] Event: Search ("$query")');
    } catch (e) {
      debugPrint('[Meta Analytics] Error logging Search: $e');
    }
  }

  /// 5. Add to Cart Event
  static Future<void> logAddToCart({
    required String id,
    required String title,
    required double price,
    int quantity = 1,
    String type = 'product',
    String currency = 'PKR',
  }) async {
    try {
      await _facebookAppEvents.logAddToCart(
        id: id,
        type: type,
        price: price * quantity,
        currency: currency,
      );
      debugPrint('[Meta Analytics] Event: AddToCart ($title x$quantity - Rs ${price * quantity})');
    } catch (e) {
      debugPrint('[Meta Analytics] Error logging AddToCart: $e');
    }
  }

  /// 6. Initiate Checkout Event
  static Future<void> logInitiateCheckout({
    required double totalPrice,
    required int numItems,
    String currency = 'PKR',
    String? contentId,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: 'fb_mobile_initiated_checkout',
        parameters: {
          'fb_content_id': contentId ?? 'cart_checkout',
          'fb_num_items': numItems,
          'fb_currency': currency,
          '_valueToSum': totalPrice,
        },
        valueToSum: totalPrice,
      );
      debugPrint('[Meta Analytics] Event: InitiateCheckout ($numItems items - Rs $totalPrice)');
    } catch (e) {
      debugPrint('[Meta Analytics] Error logging InitiateCheckout: $e');
    }
  }

  /// 7. Purchase Event (Successful Order Placed)
  static Future<void> logPurchase({
    required double amount,
    required String orderNumber,
    int numItems = 1,
    String currency = 'PKR',
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      final params = <String, dynamic>{
        'fb_order_id': orderNumber,
        'fb_num_items': numItems,
        if (additionalParams != null) ...additionalParams,
      };
      await _facebookAppEvents.logPurchase(
        amount: amount,
        currency: currency,
        parameters: params,
      );
      debugPrint('[Meta Analytics] Event: Purchase (Order: $orderNumber, Amount: PKR $amount)');
    } catch (e) {
      debugPrint('[Meta Analytics] Error logging Purchase: $e');
    }
  }

  /// Custom Event Logger
  static Future<void> logCustomEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    try {
      await _facebookAppEvents.logEvent(
        name: eventName,
        parameters: parameters,
      );
      debugPrint('[Meta Analytics] Custom Event: $eventName');
    } catch (e) {
      debugPrint('[Meta Analytics] Error logging custom event: $e');
    }
  }
}
