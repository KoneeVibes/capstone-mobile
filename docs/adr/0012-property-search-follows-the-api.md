# 0012 — Property search follows the API and the website, not the mockups

- **Status:** Accepted
- **Recorded:** 2026-10-06

## Context

The mockups draw "Search property" as four steps: applicant details, a "means
of identification" page with a price beside every title type, an itemised cost
page, then Paystack. The API (`POST /case`, public multipart) disagrees in
several places, checked live on 6 Oct 2026 with one throwaway case
(`PI-DU2964LK`):

- **Location is not free text.** Only the state / LGA / city combinations from
  `GET /misc/location` have a rate; any other location is refused with a 404.
- **Nothing is priced before the case exists.** The create returns only
  `{invoiceId, trackingId}`; `GET /invoice/{id}` then gives the itemised lines
  and `totalPayable`. There are no per-title prices to show up front.
- **Both a survey plan and a title document are required**, PDF/JPG/PNG only.
- **A case carries no invoice id.** Once the user leaves the price screen, the
  invoice — and so `POST /invoice/settle/{id}` — cannot be reached from the case.
- **A client sees only cases whose `applicantEmail` is theirs**, and the token
  does not carry the email.

The team's website already does this flow against the same API, so its form is
the reference for fields and wording.

## Decision

- **One form, the website's fields and copy**: applicant name, email, phone;
  State → Local govt. → City pickers fed by `/misc/location`; address; class of
  property (one); titles the seller claims (several, "Not sure" alone); purpose
  of inquiry (Due Diligence, Physical Inspection); survey plan and title
  documents. "See price" files the case with `source: mobile-app`.
- **The price screen comes after the case is filed**, and shows the invoice.
  It has no "Edit": the case exists, a client cannot change it, and
  re-submitting would file a duplicate. The form replaces itself with the
  price screen for the same reason.
- **"Pay now" opens a coming-soon sheet** on the price screen and on a client's
  `submitted` cases (list and detail) until Paystack is integrated.
- **The sign-in email is stored with the session** and locks a client's
  applicant email, so the case lands in their Cases. Staff file for someone
  else and type it.
- **Staff get the same flow** from their dashboard; the screens are shared and
  the router passes route names in.

## Consequences

- Paying from the Cases list needs the backend to expose `invoiceId` on the case
  (or an invoice-by-case lookup). Until then only the price screen holds it.
- The mockups' per-title prices, multi-step pager and receipt screen are not
  built. The receipt waits on Paystack.
- Pricing oddities seen live and left to the backend: two titles named, one
  billed; Physical Inspection raised the total (2.5× the rate against 1×) but
  has no line of its own, so the breakdown does not add up to what it explains.
- A filed case reaches Home's counts and the Cases list through
  `casesChangedProvider` (`core/session/`), since the feature that files it may
  not import the ones that list it.
- A client signed in before this change has an editable email field until they
  sign in again.
