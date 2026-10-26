# 0015 — Pay an unpaid case through the invoice screen, looked up by case id

- **Status:** Accepted
- **Recorded:** 2026-10-19

## Context

ADR 0014 wired Paystack into the price screen shown right after filing a search,
but left the Cases "Pay now" on a coming-soon sheet: a case did not carry its
invoice id, and there was no way to reach the invoice from a case
(backlog, 7 Oct 2026). The price screen worked only because `POST /case`
returns the invoice id in hand.

The backend has now changed `GET /invoice/{id}` to accept a **case id** as well
as an invoice id — both resolve to the same invoice. Confirmed live
(19 Oct 2026): `GET /invoice/{caseId}` returned the invoice, whose own `id` is
then what `POST /invoice/settle/{invoiceId}` takes (the settle endpoint was not
changed and still wants the invoice's own id).

## Decision

- **Cases "Pay now" routes to the existing invoice screen**, opened by the
  **case id**. The invoice provider reads the invoice by whatever id it is given
  — invoice id (the search flow) or case id (from Cases) — since the endpoint
  resolves both.
- **Settling always uses the invoice's own id.** `PaymentNotifier` fetches the
  invoice first (it already did, to avoid paying a settled one), then settles
  with `invoice.id`, never the lookup key. This is the one correctness point: a
  case id cannot be settled.
- **The invoice screen serves both entry points.** From Cases it opens titled
  "Invoice" with no tracking card and no "Track this request" button — the user
  is already inside Cases. The filing flow keeps "Search submitted" and the
  tracking id. One screen, the copy parameterised on it.
- **Client only.** `canPayForCases` is a client concern; the pay route lives in
  the client cases branch alone, and staff never see "Pay now".
- **The case detail re-reads on payment.** `caseDetailProvider` watches
  `casesChangedProvider`, which a paid invoice bumps, so a case paid from its
  own detail updates its status and drops the Pay button on return. The list
  already watched it.
- **The coming-soon sheet is gone**, with it the last caller of
  `showPaymentComingSoonSheet`.

## Consequences

- The pay route (`/client/cases/:caseId/pay`) carries a case id in a screen
  param named `invoiceId`. Documented on the screen; the endpoint does not care
  which it is.
- An extra invoice read happens on opening the screen and again at the moment of
  paying (the authoritative re-read). Acceptable, and the same shape as the
  search flow.
- Abandoned transactions still pile up, one per Pay tap, unchanged by this;
  the backend does not plan to reuse them (26 Oct 2026).
- If the backend ever stops resolving a case id on `GET /invoice/{id}`, Cases
  "Pay now" breaks while the search flow keeps working; the invoice read would
  404 into the normal failure screen with a retry.
