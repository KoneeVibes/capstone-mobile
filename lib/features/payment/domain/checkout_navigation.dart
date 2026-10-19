/// How the checkout should treat a page Paystack's checkout navigates to.
enum CheckoutNavigation {
  /// Part of checkout (Paystack, a bank's 3-D Secure page): let it load.
  proceed,

  /// Paystack sent the user to the callback URL: the attempt finished. Only
  /// the invoice says whether it was paid.
  completed,

  /// The user closed checkout.
  cancelled,

  /// Not a web page (a bank app, a phone dialler): hand it to the device.
  external;

  /// Paystack's page for a closed checkout.
  static const String closeUrl = 'https://standard.paystack.co/close';

  /// Reads a message the checkout page posts to its own window — what it
  /// sends a parent frame, e.g. `"close"` or `{"event": "close"}` on Cancel.
  /// Null for anything that does not end checkout.
  static CheckoutNavigation? ofPageMessage(Object? data) {
    final event = switch (data) {
      final String name => name,
      {'event': final String name} => name,
      _ => null,
    };
    return switch (event) {
      'close' || 'cancel' => cancelled,
      'success' => completed,
      _ => null,
    };
  }

  /// Classifies [uri] for the attempt identified by [reference].
  ///
  /// Completion is recognised by our reference in the query (`reference` or
  /// `trxref`) on a page outside Paystack, so it holds whatever callback URL
  /// the backend configures.
  static CheckoutNavigation of(Uri uri, {required String reference}) {
    if (uri.scheme != 'https' && uri.scheme != 'http') return external;
    if (uri.toString().startsWith(closeUrl)) return cancelled;

    final query = uri.queryParameters;
    final carriesReference =
        query['reference'] == reference || query['trxref'] == reference;
    final onPaystack =
        uri.host == 'paystack.com' || uri.host.endsWith('.paystack.com');
    return carriesReference && !onPaystack ? completed : proceed;
  }
}
