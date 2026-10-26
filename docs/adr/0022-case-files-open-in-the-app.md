# 0022 — Every case file opens in the app

- **Status:** Accepted
- **Recorded:** 2026-10-26
- **Supersedes:** file tiles opening outside the app ([0019](0019-case-status-actions-and-reports.md))

## Context

ADR 0019 drew report files inline in the review view (PDFs page by page through
`DocumentPreview`), but every file *tile* handed its URL to the browser through
`LinkOpener`. That covered the Property Documents on the request card (survey
plans and title documents) and the report tiles under Property Update. Cloudinary
refused every PDF until 26 Oct 2026. Now that PDFs load, the user asked for the
review view's renderer to open every file in the app.

## Decision

- **A tile opens the file in a dialog, in the same frame as the review.**
  `showCaseDocumentView` shows the format and the tile's label, every page in
  one scroll, and **Exit**. It is Exit rather than Close for the same reason as
  the review: on a case screen, "Close" reads as closing the case.
- **One renderer.** `CaseDocumentPages` (the pages, the skeleton, the error
  banner) and `documentPagesProvider` (renamed from `reportPagesProvider`) serve
  both views. `showCaseFileDialog` is their shared `Dialog` frame.
- **Read-only.** Neither zoom nor an "open outside" button, by decision
  (26 Oct 2026). Look at real survey plans on a device first. A type the app
  cannot draw (not PDF or image) still opens outside through `LinkOpener`.

## Consequences

- Nobody can save or share a PDF or image from the app any more. If someone
  needs to, add an "open outside" action to the view.
- A detailed survey plan is drawn at the dialog's width. If it can't be read,
  zoom is the next step.
- Files are still fetched with a plain `Dio` and no session token (0019).
