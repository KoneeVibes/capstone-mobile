# Architecture decision records

An ADR captures one decision: the situation, what was chosen, and what it costs.
They are kept so the reason survives the people who were in the room.

| # | Decision | Status |
| --- | --- | --- |
| [0001](0001-riverpod-without-codegen.md) | Riverpod 3 without code generation | Accepted |
| [0002](0002-result-and-error-handler.md) | Repositories return `Result`; one `ErrorHandler` | Accepted |
| [0003](0003-backend-enums-are-truth.md) | The backend is the source of truth over the designs | Accepted |
| [0004](0004-single-light-theme-portrait.md) | One light theme, portrait only | Accepted |
| [0005](0005-one-app-two-role-shells.md) | One app, one tab shell per role | Accepted |
| [0006](0006-cases-fetched-whole.md) | Fetch the case list whole and filter on the device | Accepted; closed-cases request superseded by 0023 |
| [0007](0007-auth-through-core-seams.md) | Auth plugs into core through provider seams | Accepted |
| [0008](0008-session-from-jwt-claims.md) | The session is the JWT, read but not verified | Accepted; staff role superseded by 0011 |
| [0009](0009-platform-plugins-behind-wrappers.md) | Platform plugins sit behind core wrappers | Accepted |
| [0010](0010-unit-tests-only.md) | Unit tests only, plus a live check | Accepted |
| [0011](0011-staff-role-from-own-record.md) | The staff role comes from the user's own staff record | Accepted; who may edit whom superseded by 0024 |
| [0012](0012-property-search-follows-the-api.md) | Property search follows the API and the website, not the mockups | Accepted; payment superseded by 0014 |
| [0013](0013-case-assignment-rules.md) | Who can take a case, and what an assignment writes | Accepted; assignable statuses superseded by 0019 |
| [0014](0014-paystack-checkout-in-a-webview.md) | Pay through Paystack's hosted checkout in a WebView; the invoice is the proof | Accepted |
| [0015](0015-pay-an-unpaid-case-by-case-id.md) | Pay an unpaid case through the invoice screen, looked up by case id | Accepted |
| [0016](0016-staff-home-queue-and-chat-mock.md) | Staff home "My queue" and case chat, built as mock UI | Accepted; queue superseded by 0019 |
| [0017](0017-case-actions-and-disputes.md) | Case actions menu, the client case view, and disputes (mock) | Accepted; Add Report superseded by 0018, actions by 0019 |
| [0018](0018-add-report-sheet.md) | Add Report sheet, three files per report (mock) | Accepted; cap and upload superseded by 0019 |
| [0019](0019-case-status-actions-and-reports.md) | Case status actions and reports write for real | Accepted; suspend and lifting it superseded by 0021, file tiles by 0022 |
| [0020](0020-search-through-the-search-endpoint.md) | Search cases and staff through `GET /search`, one tab at a time | Accepted |
| [0021](0021-suspend-through-delete.md) | Suspend a case through `DELETE /case/{id}`; re-assign to lift it | Accepted |
| [0022](0022-case-files-open-in-the-app.md) | Every case file opens in the app | Accepted |
| [0023](0023-default-case-list-includes-closed.md) | The default case list includes closed cases | Accepted |
| [0024](0024-who-may-edit-which-staff.md) | Who may edit which staff | Accepted |

## Writing one

Copy the shape of an existing ADR: **Context**, **Decision**, **Consequences**,
with a status and date at the top. Number it next in sequence. Never rewrite an
accepted ADR's decision — supersede it with a new one and mark the old one
"Superseded by 00xx".
