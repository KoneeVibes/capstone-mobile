import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/link_opener.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../domain/checkout_navigation.dart';
import '../../domain/entities/payment_session.dart';

/// Paystack's hosted checkout for [session], full screen.
///
/// Pops with [CheckoutNavigation.completed] or [CheckoutNavigation.cancelled].
/// Neither proves anything; the caller reads the invoice either way.
class PaystackCheckoutScreen extends ConsumerStatefulWidget {
  const PaystackCheckoutScreen({required this.session, super.key});

  final PaymentSession session;

  @override
  ConsumerState<PaystackCheckoutScreen> createState() =>
      _PaystackCheckoutScreenState();
}

class _PaystackCheckoutScreenState
    extends ConsumerState<PaystackCheckoutScreen> {
  late final WebViewController _controller;

  /// Page load, 0 to 1.
  var _progress = 0.0;
  var _closed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.surface)
      ..addJavaScriptChannel(_channel, onMessageReceived: _onPageMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            // The plugin reports a percentage.
            if (mounted) setState(() => _progress = progress / 100);
          },
          onNavigationRequest: (request) => _decide(request.url),
          // Some redirects never pass through onNavigationRequest on Android.
          onPageStarted: _observe,
          onPageFinished: (_) => _controller.runJavaScript(_relayScript),
          onUrlChange: (change) => _observe(change.url),
        ),
      )
      ..loadRequest(
        Uri.parse(ApiEndpoints.paystackCheckout(widget.session.accessCode)),
      );
  }

  static const _channel = 'PaystackCheckout';

  /// Paystack's Cancel posts `close` to its own window (for a parent frame it
  /// does not have here) and calls `history.back()`; neither leaves a WebView.
  /// This relays the page's messages, and `window.close()`, to [_channel].
  static const _relayScript =
      '''
if (!window.__piRelay) {
  window.__piRelay = true;
  window.addEventListener('message', function (e) {
    try { $_channel.postMessage(JSON.stringify(e.data)); } catch (_) {}
  });
  window.close = function () { $_channel.postMessage('"close"'); };
}''';

  void _onPageMessage(JavaScriptMessage message) {
    Object? data;
    try {
      data = jsonDecode(message.message);
    } on FormatException {
      return;
    }
    final outcome = CheckoutNavigation.ofPageMessage(data);
    if (outcome != null) _close(outcome);
  }

  CheckoutNavigation? _classify(String? url) {
    final uri = url == null ? null : Uri.tryParse(url);
    return uri == null
        ? null
        : CheckoutNavigation.of(uri, reference: widget.session.reference);
  }

  NavigationDecision _decide(String url) {
    switch (_classify(url)) {
      case CheckoutNavigation.proceed:
        return NavigationDecision.navigate;
      case CheckoutNavigation.external:
        unawaited(_openExternally(url));
        return NavigationDecision.prevent;
      case final CheckoutNavigation outcome:
        _close(outcome);
        return NavigationDecision.prevent;
      case null:
        return NavigationDecision.prevent;
    }
  }

  void _observe(String? url) {
    final outcome = _classify(url);
    if (outcome == CheckoutNavigation.completed ||
        outcome == CheckoutNavigation.cancelled) {
      _close(outcome!);
    }
  }

  Future<void> _openExternally(String url) async {
    final result = await ref.read(linkOpenerProvider).open(url);
    if (!mounted) return;
    if (result case Err(:final failure)) context.showFailure(failure);
  }

  void _close(CheckoutNavigation outcome) {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop(outcome);
  }

  Future<void> _confirmLeave() async {
    final leave = await showAppConfirmDialog(
      context: context,
      title: 'Leave payment?',
      message:
          "If you've already paid, it will still reach your case. Otherwise "
          'you can pay later.',
      confirmLabel: 'Leave',
      cancelLabel: 'Stay',
      icon: null,
      isDestructive: false,
    );
    if (leave) _close(CheckoutNavigation.cancelled);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmLeave());
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('Secure payment'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Leave payment',
            onPressed: _confirmLeave,
          ),
          bottom: _progress < 1
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(
                    AppSizing.progressBarHeight,
                  ),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: AppSizing.progressBarHeight,
                  ),
                )
              : null,
        ),
        body: SafeArea(child: WebViewWidget(controller: _controller)),
      ),
    );
  }
}
