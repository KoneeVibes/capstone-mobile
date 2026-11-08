# 0031 — Notifications, built as a mock

- **Status:** Accepted
- **Recorded:** 2026-11-08

## Context

The design puts a bell, with an unread dot, on both homes' new top bar and on
the Profile tab. The bell opens a list of notifications, or a "No
Notifications" empty state. As of 8 Nov 2026 the API has no notifications
endpoint. The user chose to build it on an in-memory mock, as was done for chat
(ADR 0016).

## Decision

- **A `notifications` feature behind a repository interface.**
  `NotificationsRepository` offers `fetchNotifications` and `markAllRead`.
  `MockNotificationsRepository` seeds a list per role: the design's copy for
  staff, and a few client-side entries for clients. A fresh mock is made on
  each sign-in.
- **Opening the list marks everything read**, which clears the bell's dot
  (`hasUnreadNotificationsProvider`). The design shows no per-row unread state.
- **The bell is passed in.** `NotificationBell` is given to both homes and to
  `ProfileScreen` by the router, with the role's notifications route. No
  feature imports notifications.
- **The top bar** (app icon, "PropertyIntel", bell) heads both the staff
  Dashboard and the client Home. It stays fixed above the scrolling content.

## Consequences

- The dot shows on every sign-in, until the list has been opened.
- The real endpoint needs only a remote repository in place of the mock. The
  entity, provider, bell and screen stay as they are. Its shape — pagination,
  per-item read, and what a tap opens — is unknown until the backend ships it.
