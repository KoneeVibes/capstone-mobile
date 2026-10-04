# 0005 — One app, one tab shell per role

- **Status:** Accepted
- **Recorded:** 2026-10-04

## Context

The product has two audiences: staff (Dashboard, Cases, Staff, Profile) and
clients (Home, Search, Cases, Profile). Both see cases, and the API already
scopes `GET /case` by who is asking: staff get every case, clients only their
own.

## Decision

- **One app**, with a `StatefulShellRoute.indexedStack` per role under `/staff`
  and `/client`. Each tab keeps its own navigation history.
- **The role comes from the session**, and the redirect keeps each role inside
  its own shell.
- **Shared features are mounted in both shells.** The Cases screens serve both;
  they read the session to hide staff-only actions (assigning) and to skip
  staff-only requests (`GET /staff` for assignee names).
- `AppShell` takes its tabs as a parameter; a debug assert checks the tab count
  matches the branch count.

## Consequences

- One codebase, one release, and server-side scoping does the data separation.
- A shared screen carries a few role checks; when a role's version grows apart
  enough, split it into its own screen rather than adding more conditions.
- Routes are role-prefixed, so a feature mounted in both shells has a route name
  per shell (`caseDetailName`, `clientCaseDetailName`) and is told which to use.
