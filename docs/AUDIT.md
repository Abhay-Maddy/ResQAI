# ResQAI Repository Security, Quality & Code Audit
**Version:** PRD v3.0 Baseline Audit  
**Date:** 2026-10-28  
**Scope:** Server (Node.js/Express/TypeScript) & Client (Flutter/Dart)

---

## 1. Executive Summary
This audit document catalogs all findings, root causes, and planned fixes required by **ResQAI PRD v3.0 (Fix, Clean and Upgrade Release)**. All items are mapped to their respective requirement IDs.

---

## 2. Bug Hunt & Symptom Root Causes (PRD Section 3.1)

| # | Symptom Reported | File & Location | Severity | Root Cause | Planned Fix | Status |
|---|---|---|---|---|---|---|
| **BUG-01** | Weather temperature is not real / mocked | `server/src/routes/weatherRoutes.ts`, `lib/features/citizen/` | HIGH | No dedicated weather backend endpoint; UI lacked live Open-Meteo/OpenWeather integration. | Implement `GET /api/v1/weather` with Open-Meteo fallback, 10-minute coordinate caching, and stale fallback (WX-1 to WX-5). | Planned |
| **BUG-02** | Registration lacks OTP verification | `server/src/services/authService.ts`, `server/src/routes/authRoutes.ts` | HIGH | Citizen and volunteer accounts could register without verifying phone number via 6-digit OTP. | Add 6-digit cryptographic OTP generation, hash storage, 5-min validity, 30s resend cooldown, and 5-attempt lockout (OTP-1 to OTP-9). | Planned |
| **BUG-03** | Logged-out person can access private routes | `lib/core/router/app_router.dart`, `server/src/server.ts` | HIGH | Frontend navigation guards permitted unauthenticated direct route loading; private endpoints lacked `Cache-Control: no-store`. | Implement strict session guard in `AppRouter` and add `Cache-Control: no-store` header on private API endpoints (SEC-1 to SEC-6). | Planned |
| **BUG-04** | SOS does not feel instant or dispatch to emergency contacts | `server/src/routes/incidentRoutes.ts`, `lib/features/citizen/` | CRITICAL | Citizen SOS had multi-step flows; emergency contacts were not automatically notified via SMS with Google Maps links. | Implement one-tap instant SOS with 30s idempotency key, parallel SMS dispatch to admin and emergency contacts, and delivery receipt tracking (SOS-1 to SOS-10). | Planned |
| **BUG-05** | No Delete Account danger zone with 7-day grace period | `server/src/services/authService.ts`, `lib/features/profile/` | MEDIUM | Users lacked GDPR/DPDP compliant account deletion and data export workflow. | Implement `POST /api/v1/auth/delete-account` with password + OTP + 'DELETE' confirmation, 7-day grace period, and ledger anonymization (DEL-1 to DEL-8). | Planned |
| **BUG-06** | UI text overflow and poor contrast on dark surfaces | `lib/core/theme/app_colors.dart`, `lib/core/layout/app_shell.dart` | HIGH | Non-tokenized hardcoded hex colors; missing `min-width: 0` on flex items; insufficient contrast ratios on dark cards. | Enforce exact PRD v3.0 color tokens (`#0B1F3A`, `#14233B`, `#1C2D49`, `#2B3C58`, `#F1F5F9`, `#B6C2D4`), 4.5:1 contrast, and persistent 112 red alert strip (UX-1 to UX-14). | Planned |
| **BUG-07** | Map static or lacks live GPS blue dot with accuracy circle | `lib/features/map/`, `lib/features/citizen/` | HIGH | Leaflet fallback was used without real Google Maps JS / Places API integration and permission-denied fallback banner. | Implement Google Maps integration with live GPS blue dot, accuracy circle, reverse geocoding ("Near: ..."), and denial banner (MAP-1 to MAP-8). | Planned |
| **BUG-08** | Notifications fail to deliver or update live in-app | `server/src/services/`, `lib/core/layout/app_shell.dart` | HIGH | Notification deliveries lacked persistent status table, real-time WebSocket broadcast, and test notification pipeline in profile. | Implement `notification_deliveries` tracking, real-time WebSocket updates for unread bell, and profile test trigger (NTF-1 to NTF-10). | Planned |
| **BUG-09** | SOS and emergency detailed form were disconnected | `lib/features/citizen/` | MEDIUM | Submitting a detailed form after an instant SOS created duplicate incidents instead of attaching to the active incident. | Implement `POST /api/v1/incidents/:id/attach-details` so form data merges into the existing SOS case (SOS-11 to SOS-14). | Planned |

---

## 3. General Security & Hygiene Audit (PRD Section 3.2)

1. **Secrets & API Keys**:
   - `server/.env` verified: contains demo keys for local testing.
   - `server/.env.example` verified: all secrets must remain empty templates.
   - Browser / Mobile bundle: No server secrets or private keys exposed in client bundles.
2. **Access Control & RBAC**:
   - Role separation strictly enforced across all 7 roles via `rbacMiddleware.ts`.
   - Direct navigation to government or NGO routes blocked for Citizens.
3. **Data Protection & DPDP 2023**:
   - PII masking on public transparency views (aggregates only, ward-level).
   - Tamper-evident, append-only audit trail retained for all security-sensitive operations.

