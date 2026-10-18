# Akrili Mobile App — Build Plan

Flutter mobile app for **host (owner)** and **guest (tenant)** with FCM push notifications.

## Context

Akrili is a **short-term rental marketplace** (Airbnb-style, Algeria wilaya/commune geo), not property management. "Owner" = host, "tenant" = guest. There are **no leases and no payments** — bookings carry only `total_price` (int) and `price_breakdown`. Mobile scope works on **bookings**, not payments.

**Repos**
- Laravel backend: `/home/faycal/Desktop/Valet/akrili`
- Flutter app: `/home/faycal/AndroidStudioProjects/akrili`

**Decisions**
- API auth: `laravel/sanctum` personal-access-tokens (Fortify session auth stays for web).
- FCM sender: `kreait/laravel-firebase`.
- Flutter state: Riverpod.
- Android-first (iOS/APNs later).

**Workflow:** you code each phase, then send the diff. I review at the gate before the next phase. Build backend first (Phases 0–3), then Flutter (Phase 4) against a stable API.

---

## Phase 0 — Dependencies

- [x] `composer require laravel/sanctum` (backend)
- [x] `composer require kreait/laravel-firebase` (backend)
- [ ] Download Firebase service-account JSON → `storage/app/firebase/service-account.json`
- [x] Add `.env`: `FIREBASE_CREDENTIALS=storage/app/firebase/service-account.json`
- [x] Add the JSON path to `.gitignore` — **never commit the secret**
- [x] Publish Sanctum config + migration (`php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"`)

**Review gate 0:** secret gitignored, deps at expected versions.

---

## Phase 1 — Token auth + device tokens

- [x] `User` model: add `Laravel\Sanctum\HasApiTokens` trait
- [x] Migration `device_tokens`: `id, user_id (fk, cascade), token (string, unique), platform (enum: android/ios), last_used_at (nullable), timestamps`
- [x] `DeviceToken` model + `User::deviceTokens()` hasMany
- [x] Create `routes/api.php`; register in `bootstrap/app.php` → `withRouting(api: ...)`, prefix `api`
- [x] Endpoints (group `auth:sanctum` except login):
  - [x] `POST /api/auth/login` — validate, throttle, issue token, return `{ token, user }`
  - [x] `POST /api/auth/logout` — revoke current token
  - [x] `GET  /api/me` — profile + `getRoleNames()`
  - [x] `POST /api/device-tokens` — upsert `{ token, platform }` for current user (no duplicates)
  - [x] `DELETE /api/device-tokens/{token}` — unregister

**Review gate 1:** token issue/revoke, device-token upsert idempotent, login rate-limited, no password in response.

---

## Phase 2 — JSON API resources (role-scoped)

Use Eloquent API Resources in `app/Http/Resources/`. Version endpoints under `/api/v1`. Reuse existing policies/services — do not duplicate business logic from the Inertia controllers.

- [x] Resources: `PropertyResource`, `BookingResource`, `UserResource`, `NotificationResource`
- [x] Shared:
  - [x] `GET /api/v1/properties` (filters: wilaya, commune, check_in, check_out, capacity)
  - [x] `GET /api/v1/properties/{id}`
  - [x] `GET /api/v1/properties/{id}/availability`
- [x] Guest (tenant):
  - [x] `GET  /api/v1/bookings` (own)
  - [x] `POST /api/v1/bookings`
  - [x] `GET  /api/v1/bookings/{id}`
  - [x] `GET/POST` favorites (list / toggle)
  - [x] `POST /api/v1/reviews`
- [x] Host (owner):
  - [x] `GET  /api/v1/host/properties`
  - [x] `GET  /api/v1/host/bookings` (incoming)
  - [x] `POST /api/v1/bookings/{id}/accept`
  - [x] `POST /api/v1/bookings/{id}/reject`

**Review gate 2:** role authorization enforced, no N+1 (eager loads), resource shapes stable, business logic shared with web.

---

## Phase 3 — Notifications + FCM

- [x] `php artisan notifications:table` + migrate
- [x] Notification classes in `app/Notifications/` — each `via()` = `['database', FcmChannel::class]`:
  - [x] `BookingRequested` → host
  - [x] `BookingAccepted` → guest
  - [x] `BookingRejected` → guest
  - [x] `MessageReceived` → recipient (mirror existing `app/Events/MessageSent.php`)
- [x] FCM send targets all of the user's `deviceTokens`
- [x] On FCM invalid/`unregistered` response → delete that device-token row
- [x] Fire `->notify()` at booking create / accept / reject, and on message sent
- [x] Feed endpoints:
  - [x] `GET  /api/v1/notifications`
  - [x] `POST /api/v1/notifications/{id}/read`
  - [x] `POST /api/v1/notifications/read-all`

**Review gate 3:** no self-notify, stale-token cleanup works, reads idempotent, push payload carries deep-link data (type + id).

---

## Phase 4 — Flutter app

Project: `/home/faycal/AndroidStudioProjects/akrili`

- [x] Packages: `dio`, `flutter_riverpod`, `firebase_core`, `firebase_messaging`, `flutter_secure_storage`, `go_router`, `intl`, `flutter_local_notifications`
- [x] Firebase Android setup: `google-services.json` template, Gradle plugin & settings
- [x] Auth flow: login → store token in secure storage → Dio auth interceptor
- [x] On login + `onTokenRefresh`: register FCM token via `POST /api/device-tokens`
- [x] On logout: `DELETE /api/device-tokens/{token}` + clear secure storage
- [x] After `/api/me`: branch host stack vs guest stack by role (+ dynamic mode switcher in profile)
- [x] Screens v1: auth, property search + detail, booking create (guest), incoming bookings accept/reject (host), notifications feed, conversations, favorites
- [x] FCM handlers: foreground (local notification), background handler, tap → deep link to booking/conversation

**Review gate 4:** token never logged, FCM lifecycle correct (refresh + logout clears server token), deep links resolve, role branching correct.

---

## Progress log

- 2026-10-18 — plan created.
- 2026-10-18 — Phase 0 completed (Sanctum + Firebase credentials gitignored).
- 2026-10-18 — Phase 1 completed (Sanctum PAT + Device tokens + 8 passing tests).
- 2026-10-18 — Phase 2 completed (JSON API resources v1 + policies + 8 passing tests).
- 2026-10-18 — Phase 3 completed (FCM push + DB notifications + 6 passing tests, 25 total).
- 2026-10-18 — Phase 4 completed (Flutter app with Riverpod, GoRouter role navigation, FCM lifecycle, guest and host flows, all analyzer checks and unit tests passing).

