# 0014 — Pay through Paystack's hosted checkout in a WebView; the invoice is the proof

- **Status:** Accepted
- **Recorded:** 2026-10-07

## Context

The backend initialises Paystack transactions: `POST /invoice/settle/{id}`
returns `{accessCode, reference}` and stores both on the invoice. The app never
holds a Paystack key. Paystack offers two ways to take that access code on a
phone:

- **`paystack_flutter_sdk`**, the official plugin — still `0.0.1-alpha.2` and
  untouched for 19 months on 7 Oct 2026. It needs the public key in the app
  and `MainActivity` changed to `FlutterFragmentActivity`.
- **The hosted checkout** at `checkout.paystack.com/{accessCode}`, loaded in a
  WebView, which Paystack documents for mobile apps.

What a checkout page reports is not proof of payment: a redirect can be faked,
and a successful charge can arrive with the page already closed.

## Decision

- **Hosted checkout in `webview_flutter`**, pushed full screen over the shell.
- **Checkout's own signals are relayed, not assumed.** Verified on device,
  7 Oct 2026: with no callback URL set, Paystack never redirects. On success
  it posts `{event: "success"}` to its own window; its Cancel button posts
  `"close"` and calls `history.back()` — all meant for a parent frame, so
  none of them leaves a WebView. An injected script forwards the page's
  messages (and `window.close()`) over a JavaScript channel.
- **A pure classifier (`CheckoutNavigation`) reads those messages and every
  page checkout opens.** `success` means completed, `close` cancelled; our
  reference in the query on a non-Paystack host also means completed, so a
  callback URL added later still works; `standard.paystack.co/close` means
  cancelled; non-web schemes (bank apps, the dialler) go to `LinkOpener`.
- **Only the invoice says "paid".** Whenever checkout closes, the app re-reads
  `GET /invoice/{id}`. After a completed checkout it keeps reading for a short
  while (`AppConstants.paymentConfirm*`) for the webhook to land, then shows
  "Confirming your payment" with no Pay button, so nobody pays twice.
- **The invoice is re-read before settling**, and a paid one is never settled
  again. A paid invoice bumps `casesChangedProvider`.
- **Invoices live in `features/payment/`.** property_search files the case and
  routes to the invoice screen; it no longer reads invoices.

## Consequences

- The WebView itself is a widget, not a platform call, so it is not wrapped as
  ADR 0009 asks of plugins. The logic that matters is the classifier, which is
  pure and unit tested; the screen around it is thin.
- Cases "Pay now" now routes to this screen too: `GET /invoice/{id}` accepts a
  case id, so the invoice is reached without the case carrying its invoice id
  (ADR 0015). Settling still uses the invoice's own id.
- Confirmation depends on the backend's Paystack webhook. It exists: on device
  the invoice read `paid` about two seconds after checkout, and the case
  moved to `payment-validated`. If it ever lags past the retries, the screen
  sits on "Confirming your payment" with "Check again".
- The relay depends on Paystack's page messages, which are not a documented
  API. If Paystack changes them, Cancel stops closing checkout (the app's own
  close button still works) and success falls back to the user closing it —
  the invoice read still decides.
- Paystack's checkout look is Paystack's, not the app's.
