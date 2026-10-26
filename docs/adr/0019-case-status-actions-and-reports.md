# 0019 — Case status actions and reports write for real

- **Status:** Accepted; suspend and lifting it superseded by [0021](0021-suspend-through-delete.md), file tiles by [0022](0022-case-files-open-in-the-app.md)
- **Recorded:** 2026-10-24

## Context

The team's *Case Status Matrix* and a call with the backend lead (24 Oct 2026)
settled who may move a case, and from which status. The API added the writes:

- `PATCH /case/{id}` takes `status` (`assigned | accepted | closed |
  disputed`) and/or `assigneeId`, now as multipart.
- `PUT /case/{id}` (new) takes 1–5 `inquiryReport` files from the assignee and
  moves the case to `under-review`.
- Cases carry `inquiryReport` (file URLs) and a ninth status, `disputed`.

Until now accept, suspend and the report were mock (ADRs 0017, 0018), the staff
home queue was a fixed list (ADR 0016), and every status but `submitted` could
be re-assigned (ADR 0013). Disputes are still out of scope.

## Decision

- **The call is the source of truth.** The backend lead checked his code during
  it, so where the call and the swagger disagree the call wins, and a write the
  wire refuses is a backend bug to report, not a rule to change.
- **One rule set, in `case_actions.dart`.** `CaseViewer` answers each action;
  the ⋮ menu, the card button and the detail footer all ask it. The matrix, as
  agreed on the call:

  | Action | Who | Statuses |
  |---|---|---|
  | Request information (chat) | assignee, or a manager | accepted, pending-information, disputed |
  | Assign | super-admin, admin, manager | payment-validated |
  | Reassign | super-admin, admin, manager; a suspended case super-admin only | assigned, accepted, suspended |
  | Review report → Accept closes | super-admin | under-review |
  | Accept assignment | the assignee | assigned |
  | Suspend | super-admin | payment-validated, assigned, accepted, pending-information, under-review |
  | Add Report | the assignee | accepted, under-review, disputed |

- **"The assignee's manager" is any manager.** Neither the case nor the staff
  record names someone's manager, so Request information goes to the assignee
  and to every `manager`; the backend decides.
- **Every write is real.** Accept, suspend and close are `PATCH {status}`;
  assignment still sends `status: assigned` only from `payment-validated`.
  All `PATCH /case` bodies go as multipart, matching the spec. A refused
  write shows the server's message; nothing changes on screen.
- **Review report is one scrolling view, Accept and Exit, never Reject.**
  As the design shows, every report file is drawn inline — PDFs page by page
  through `pdfx` (the platform's own renderer, behind
  `core/utils/document_preview.dart`), images as they are — so the reviewer
  reads them in place. Accept report asks "Accept Case" first, then closes the
  case. The API has no reject; Exit (the design's "close case", renamed so it
  cannot read as closing the case) only closes the view, and the assignee is
  told outside the app. A file that will not load says so and does not block
  Accept. Files are fetched without the session token: they live on Cloudinary.
- **Add Report uploads up to five files** (`CaseReportSheet.maxFiles`, the
  API's limit; ADR 0018 chose three) and shows only to the assignee.
- **Reports show under Property Update.** Staff see them whenever they exist;
  a client only once the case is `closed`.
- **The client's chat icon greys out** outside accepted, pending-information
  and disputed.
- **"My queue" is the cases list.** `CaseQueueSection` lives in the cases
  feature, reads `casesListProvider` (no request of its own) and shows the five
  most recently changed cases with the same cards and buttons as the Cases tab.
  The router hands it to `StaffHomeScreen` as a widget, so dashboard imports no
  feature. The overview counts stay mock until the stats endpoint lands.
- **`disputed` gets a Cases tab** (ten tabs) and counts as in progress on the
  client home and the tracking timeline.

## Consequences

- Live testing on 24 Oct 2026 found backend gaps the app cannot work around:
  `PATCH {status: suspended}` is refused (400 "Invalid status"); a client
  cannot see their own case once it is assigned (`GET /case` omits it,
  `GET /case/{id}` 404s); Cloudinary answers PDF links with 401 ("deny or ACL
  failure"), so neither reports nor case documents open; and `POST /case`
  fails (500 with files, 400 without). Each is with the backend.
- A super-admin can only re-assign a suspended case once suspend works.
- Disputes remain mock (ADR 0017) and the dispute rules were not changed here.
- `pdfx` is a new dependency. `pdfrx` was passed over because it needs a
  newer Flutter than the project's 3.38.
