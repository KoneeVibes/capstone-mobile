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
| [0006](0006-cases-fetched-whole.md) | Fetch the case list whole and filter on the device | Accepted |
| [0007](0007-auth-through-core-seams.md) | Auth plugs into core through provider seams | Accepted |
| [0008](0008-session-from-jwt-claims.md) | The session is the JWT, read but not verified | Accepted; staff role superseded by 0011 |
| [0009](0009-platform-plugins-behind-wrappers.md) | Platform plugins sit behind core wrappers | Accepted |
| [0010](0010-unit-tests-only.md) | Unit tests only, plus a live check | Accepted |
| [0011](0011-staff-role-from-own-record.md) | The staff role comes from the user's own staff record | Accepted |
| [0012](0012-property-search-follows-the-api.md) | Property search follows the API and the website, not the mockups | Accepted |

## Writing one

Copy the shape of an existing ADR: **Context**, **Decision**, **Consequences**,
with a status and date at the top. Number it next in sequence. Never rewrite an
accepted ADR's decision — supersede it with a new one and mark the old one
"Superseded by 00xx".
