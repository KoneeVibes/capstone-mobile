# 0018 — Add Report sheet, three files per report (mock)

- **Status:** Accepted; the file cap and mock upload superseded by [0019](0019-case-status-actions-and-reports.md)
- **Recorded:** 2026-10-21

## Context

ADR 0017 left Add Report saying "coming soon". The design now shows it as a
bottom sheet: an upload box (PDF, JPG, JPEG or PNG under 10 MB), the chosen
files listed under it, and an Upload button. The team has not set a file limit,
and there is still no report endpoint.

## Decision

- **Add Report opens `CaseReportSheet`.** It is the same shared upload box as
  disputes. Upload stays greyed out until a file is chosen.
- **Three files per report** (`CaseReportSheet.maxFiles`). The cap applies to
  one upload, not to the case. Tapping the box when all three are chosen says
  so. A pick that runs past the cap keeps the first files that fit and says
  the rest were left out. Messages show inside the sheet, since a snackbar
  would sit behind it.
- **`MediaPicker.pickDocuments` reports what it trimmed.** It returns
  `PickedDocuments` (`files`, `dropped`) in place of a bare list, so no caller
  drops files without saying so. The dispute form now says so too.
- **Upload is mock and keeps nothing.** It closes the sheet and raises
  "Report submitted."; the files never leave the device. Review report still
  says "coming soon", and Property Update's report half stays hidden.

## Consequences

- A submitted report leaves no trace, and a case keeps offering Add Report.
  The sheet carries a `TODO(backend)` where the upload will plug in.
- If the backend sets a different limit, only `maxFiles` and its copy change.
