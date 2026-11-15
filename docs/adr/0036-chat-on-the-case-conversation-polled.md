# 0036 — Chat reads the case's conversation, and polls for it

- **Status:** Accepted
- **Recorded:** 2026-11-15
- **Supersedes:** the chat parts of
  [0016](0016-staff-home-queue-and-chat-mock.md) and
  [0017](0017-case-actions-and-disputes.md); ends chat's exemption in
  [0033](0033-per-user-state-is-auto-disposed.md)

## Context

Chat was an in-memory mock shared by both roles (ADRs 0016, 0017). The API now
carries a conversation, on the case itself (spec read 15 Nov 2026):

- `GET /case/{id}` returns `conversation: {status: open|closed, chat: [...]}`.
  Each message is `{id, senderId, text, sentAt, updatedAt}`, plus a
  `senderName` the spec does not list (seen live). There is no messages
  endpoint, no "since" parameter and no ETag.
- `POST /case/{id}/message` with `{text}` adds a message; a closed
  conversation answers 409.
- `PATCH /case/{id}` with `status: pending-information` toggles: an accepted
  case becomes pending-information and its conversation opens; sent again, the
  case returns to its previous status and the conversation closes. Only the
  staff member the case is assigned to may send it.

There is no socket and no push. Cases filed before conversations existed have
no `conversation` key at all (checked live, 15 Nov 2026).

## Decision

- **Chat gets a data layer of its own, reading the case.** It decodes only the
  slice it needs (`conversation`, `status`, `assigneeId`, `applicantName`) and
  keeps its own two-value stage enum, so it still does not import the cases
  feature. A missing conversation reads as closed and empty.
- **Open and close follow the API, not the mock.** Only the holder of the case
  sees the buttons: Open on an accepted case, Close on a pending-information
  one. Clients and other staff can read, and write while it is open. A toggle
  bumps `casesChangedProvider`, since the case's status moved.
- **"Live" is a foreground poll of `GET /case/{id}`.**
  - Only while the chat screen is up and the app is in view. The provider is
    `autoDispose`, so leaving the screen stops it; `AppLifecycleListener`
    pauses it when the app is hidden and re-reads at once on return. Nothing
    polls in the background, and no list or badge polls.
  - One read at a time: each answer arms a one-shot timer for the next, so a
    slow network or a cold-started host slows the polling by itself.
  - The wait adapts (`ChatPollSchedule`, intervals in `AppConstants`): 4 s
    after a message is sent or arrives, then 8 s, 15 s and 30 s, each held for
    three unchanged reads; 30 s flat while the conversation is closed. A failed
    read keeps the transcript and doubles the wait, up to 60 s.
  - An unchanged read assigns no state, so nothing rebuilds.
- **Sending is optimistic.** The message shows greyed at once and the server's
  copy replaces it. A failure removes it and hands the text back to the
  composer. A 409 re-reads immediately, since the conversation was closed
  meanwhile. A read already in flight when a send or toggle starts is dropped,
  so it cannot undo the newer state.
- **Names.** The reader's own messages are "You". A client sees every other
  sender as "Property Intel". Staff see each sender's `senderName`; without
  one, the holder is "Case officer" and anyone else the applicant's name.
- **`chatProvider` joins the per-user rule.** It watches the session and is
  auto-disposed, like every other provider of one user's data.

## Consequences

- A reply appears within 4 s in an active chat and within 30 s in an idle one.
  Anything livelier needs the backend: a `messages?after=` read or an ETag to
  make polls cheap, and push for delivery while the app is closed.
- Each poll re-reads the whole case (about 2 KB without messages); it grows
  with the transcript.
- Checked live on 15 Nov 2026, through the app as the holder and as the
  client: open, send both ways, close, the 409 on a closed send, a reply
  arriving by poll within about 8 s, and no requests while the app was hidden.
  `PATCH` takes JSON.
- A disputed case's chat can be read, but not opened: the API opens a
  conversation from `accepted` only.
- Attachments are not offered; the API takes text only. The mock's read-aloud
  and copy glyphs are gone.
- A request in flight when the screen closes is left to finish and its answer
  is ignored; it is one small read.
