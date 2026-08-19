# Chaty Production Enhancement Plan

## Objective

Harden Chaty into a deeply customizable production messaging client without replacing its existing Supabase-backed chat, task, media, auth, privacy, or settings flows.

## Phase A — Correctness before customization

- Remove the Flutter splash route from application startup.
- Restore the authenticated session directly into the main shell; unauthenticated users go directly to Welcome.
- Remove duplicate home search fields. Search is icon-only by default and expands only when requested unless the user explicitly enables an always-visible search field.
- Make all root navigation theme-aware; remove hard-coded dark navigation colors.
- Make chat detail consume the live ThemeController so switching light/dark mode while a chat route is open updates bubbles and text immediately.
- Enforce readable message text and delivery icons by contrast, including quoted replies and attachment surfaces.
- Show presence/last-seen information on chat rows and inside direct chats.
- Use chevrons for route navigation instead of generic directional arrows.
- Android back behavior: nested routes pop normally; root non-chat tabs return to Chats; Chats root requires a second back press within two seconds to exit.

## Phase B — Status / Updates

- Add a real `status_updates` data model with a 24-hour expiry.
- Add a private `status-media` Supabase Storage bucket.
- Allow My Status to publish text, image, video, audio and document updates.
- Add a status viewer, secure signed URLs, own-status deletion and realtime refresh.
- Preserve privacy settings such as hidden viewing/anti-delete behavior at the presentation layer where they do not conflict with server authorization.

## Phase C — Tasks and Kanban

- Make every task card open a full task detail screen.
- Display creator, assignees, source conversation, priority, status, due date, labels and timestamps.
- Render task activity history as a VS Code-style event tree with actor and timestamp.
- Add long-press drag/drop across Kanban columns.
- Add left/right chevrons for keyboard/touch-friendly status progression without requiring drag gestures.
- Keep status changes server-backed through the existing `update_task_status` RPC so activity history remains authoritative.

## Phase D — Appearance engine

Introduce a persisted `VisualPreferences` model with exactly 20 selectable variants for each of the following categories:

- top navigation
- bottom navigation
- chat bubble treatment
- in-app icon treatment
- notification icon treatment
- typography profile
- route entry animation
- route exit animation

All appearance pages show a live preview above controls. Variant implementations are parameterized profiles instead of twenty copy-pasted widgets, which prevents design drift and keeps accessibility fixes global.

The OS launcher icon and Android status-bar notification small icon cannot be arbitrarily swapped at runtime from Flutter alone. Chaty therefore treats these options as in-app visual profiles unless native alternate icon resources are explicitly provisioned in a later Android/iOS release.

## Phase E — Themes and responsiveness

- Expand the registered theme preset catalogue to 20.
- Every preset must satisfy foreground/background and chat-bubble contrast requirements in its native mode and when dynamically toggled between light/dark.
- Support compact/floating/split-screen widths without overflow.
- Use compact bottom navigation on narrow windows and a NavigationRail on wider layouts.
- Cap message-bubble width on tablet/desktop while remaining fluid on phones.

## Phase F — Calling

The existing repository contains simulated call UI and call records, not a production VoIP media stack. A reliable real-world call session requires WebRTC media plus authenticated signaling and TURN relay infrastructure. STUN-only calling is not production-grade because carrier NAT/firewalls will fail unpredictably.

This enhancement pass will remove misleading “working call” claims and prepare navigation/state boundaries, but production voice/video calling is gated on TURN credentials/service selection. It must not be marked complete until two-device tests pass over Wi-Fi, LTE/5G, NAT-to-NAT, background/resume and permission-denied scenarios.

## Release gates

A change is mergeable only when all of the following pass:

1. `flutter pub get`
2. `flutter analyze --no-fatal-infos`
3. `flutter test`
4. Android release APK compilation
5. APK archive verification and SHA-256 generation
6. Supabase RLS/security checks for any new tables/buckets
7. Manual two-account smoke test for chat, status and task transitions

No mock success toast is accepted as a substitute for a real mutation.