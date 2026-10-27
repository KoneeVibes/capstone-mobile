# 0017 — Case actions menu, the client case view, and disputes (mock)

- **Status:** Accepted; the action rules, accept, suspend and review superseded by [0019](0019-case-status-actions-and-reports.md) (disputes stay mock)
- **Recorded:** 2026-10-20

## Context

The team redesigned the Cases screens. List cards take the staff queue's look:
reference, status, property, applicant and one action button. The staff case
detail gains a ⋮ menu: Request information (Chat), Assign / Reassign to staff,
Review report, Accept assignment, Suspend case. It also gains an **Add Report**
button beside assign. The client gets a view of their own: no Assignment row, a
**Track Progress** button, a chat icon where staff have the ⋮, and a **Property
Update** section holding reports and disputes. Disputes have a form (title,
description, evidence) and a timeline that staff answer with *Accept* or
*Decline with Note*.

The only endpoint behind any of this is assignment (ADR 0013). Accept, suspend,
reports and disputes have no endpoints yet. The designs also show a due date
("Overdue · 1 day"), which the case does not carry.

## Decision

- **One place for the action rules.** `features/cases/domain/case_actions.dart`
  maps a case and the viewer (permissions plus their staff id) to the ⋮ items
  and the card button. Chat for every staff member. Assign and reassign as ADR
  0013. Review report and suspend for managers and above. Suspend only on a
  paid, running case. Accept only for the case's own assignee. A member sees no
  card button they could not use.
- **Accept and suspend are mock.** Each asks for confirmation (Confirm over
  Cancel, no reason), then raises a snackbar. Nothing is written, so ADR 0013
  stands: the app still only writes `assigned`.
- **Add Report shows for all staff**, greyed out like assign until the case
  is paid, and says "coming soon"; so does Review
  report. *Superseded by [0018](0018-add-report-sheet.md): Add Report opens
  a mock upload sheet.* The reports half of Property Update stays hidden. When it lands, a
  client sees a report only once it is approved.
- **Client view.** Cards and detail show **Pay now** while unpaid (ADR 0015),
  then **Track progress**. It opens `TrackingProgressScreen` on a route inside
  the Cases tab. The tracking banner is gone from that screen.
- **Disputes are mock, in memory, and part of the cases feature**, so case
  detail can show them without one feature importing another. A client may
  raise any number once the case is paid for. Title and description are
  required. Evidence is optional: PDF, JPG or PNG under 10 MB, up to five
  files, never uploaded. Staff take a dispute in, or decline it with a required
  note; a dispute is answered once. The provider deliberately does not watch
  the session, so a dispute raised as a client can be answered as staff on the
  same device.
- **Chat for both roles.** Clients get `/client/chat/:caseId` on the same mock
  screen; either side may open or close the conversation.
- **No due date** on case cards until the API sends one.
- `CaseSummaryCard` (the card) and `AppUploadField` (the upload box) move to
  `shared/`, as two features now use each.

## Consequences

- Mock disputes and chat vanish on restart. Each mock carries
  `TODO(backend)` where its endpoint will plug in.
- Accept and suspend leave the status unchanged, so a case keeps offering them
  after "success". This is acceptable while they are placeholders.
- The client and staff dispute routes share one screen, which reads the session
  to decide whether to offer a response.
