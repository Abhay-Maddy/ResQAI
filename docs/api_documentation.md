# ResQAI API Specification (v1)

Base URL: `http://localhost:5000/api/v1`

---

## 1. Authentication & Persistent Login (`/auth`)

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/auth/register` | Register Citizen, Volunteer, NGO, or Government Officer | None |
| `POST` | `/auth/login` | Login with phone & password; issues 30-day refresh token | None |
| `POST` | `/auth/refresh` | Rotate refresh token & receive new access token | Refresh Token |
| `POST` | `/auth/set-pin` | Set 4-digit quick unlock PIN | Bearer |
| `POST` | `/auth/verify-pin` | Unlock session with PIN (locked after 5 failed attempts) | Bearer |
| `POST` | `/auth/reauth` | Sensitive action challenge re-authentication | Bearer |
| `POST` | `/auth/devices/register` | Register device for push notifications | Bearer |
| `POST` | `/auth/devices/revoke` | Remote session revocation for stolen devices | Bearer |
| `GET` | `/auth/me` | Fetch active user profile and roles | Bearer |

---

## 2. Incidents & Emergency Triage (`/incidents`)

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/incidents` | Submit emergency SOS report (with idempotency key) | Optional (Guest SOS supported) |
| `GET` | `/incidents` | List active incidents with priority scores & filters | Bearer |
| `GET` | `/incidents/:id` | Incident detail view with status history audit | Bearer |
| `POST` | `/incidents/:id/verify` | Official or volunteer verification decision | Bearer (Volunteer/Govt) |
| `POST` | `/incidents/:id/assign` | Assign incident to rescue team battalion | Bearer (Dispatcher/Govt) |
| `POST` | `/incidents/:id/resolve` | Mark incident resolved with on-scene resolution notes | Bearer (Responder/Govt) |

---

## 3. Damage Claims & Official Aid (`/claims`)

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/claims` | File damage claim with completeness evaluation | Bearer (Citizen) |
| `GET` | `/claims` | List claims (filtered by role and jurisdiction) | Bearer |
| `POST` | `/claims/:id/verify` | Community or official inspection verification | Bearer (Volunteer/Govt) |
| `POST` | `/claims/:id/sanction-aid` | Sanction aid relief package in integer paise | Bearer (Govt Officer) |
| `POST` | `/claims/:id/deliver-aid` | Confirm aid delivery with OTP or signature proof | Bearer (Officer/Volunteer) |
| `POST` | `/claims/:id/appeal` | File appeal routed to a distinct independent officer | Bearer (Citizen) |
| `GET` | `/claims/public-stats` | Public aggregated statistics masked for counts < 5 | None |

---

## 4. Warnings & Weather Feeds (`/alerts`)

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `GET` | `/alerts` | Get active warning bulletins | None |
| `POST` | `/alerts` | Draft official warning with polygon coordinates | Bearer (Govt Officer) |
| `POST` | `/alerts/:id/approve` | 4-eyes second officer approval to broadcast | Bearer (Govt Officer) |
| `POST` | `/alerts/:id/pause` | Pause warning transmission during false alarm | Bearer (Govt Officer) |
| `POST` | `/alerts/:id/all-clear` | Broadcast all-clear notification to affected zone | Bearer (Govt Officer) |
| `POST` | `/alerts/telemetry/evaluate` | Ingest IMD/GDACS feeds & evaluate flood risk | Bearer (System/Govt) |

---

## 5. NGO Consoles, Campaigns & Transparency (`/campaigns`, `/transparency`)

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/campaigns` | Create relief campaign (must be approved by Admin) | Bearer (NGO) |
| `POST` | `/campaigns/:id/approve` | Approve NGO campaign for public donations | Bearer (Super Admin) |
| `POST` | `/donations/order` | Create Razorpay test mode donation order | None / Bearer |
| `POST` | `/donations/verify` | Verify payment HMAC signature & issue 80G receipt | None / Bearer |
| `POST` | `/donations/webhook` | Idempotent webhook receiver (duplicate webhooks safe) | Razorpay Webhook |
| `GET` | `/transparency/ngos` | Public explorer of registered NGOs and audited ledger | None |
| `GET` | `/transparency/compare` | Side-by-side comparison of 2 NGOs (balance, receipts) | None |

---

## 6. Government Command & Connect-and-Inform (`/government`)

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `GET` | `/government/overview` | District crisis oversight KPI metrics | Bearer (Govt/Admin) |
| `POST` | `/government/notices` | Send targeted role-filtered broadcast notice | Bearer (Govt Officer) |
| `GET` | `/government/watch-panel` | Watch panel identifying ignored areas & missing receipts | Bearer (Govt/Admin) |
| `POST` | `/government/ngos/:id/suspend` | Suspend non-compliant NGO with recorded reason | Bearer (Govt/Admin) |
| `POST` | `/government/datasets/import` | Import beneficiary dataset with review & rollback | Bearer (Govt/Admin) |
| `POST` | `/government/mutual-aid/request`| Inter-district requisition for mutual emergency aid | Bearer (Govt/Admin) |

---

## 7. Research Features & Explainability (`/research`)

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/research/priority/what-if` | Interactive what-if priority delta calculator | None / Bearer |
| `POST` | `/research/silent-zones/evaluate`| Sudden drop (>75%) blackout alert detector | None / Bearer |
| `GET` | `/research/situation-summary` | 1-click briefing built strictly from relational facts | None / Bearer |
| `POST` | `/research/volunteer-matching` | Proximity & skill matching for volunteer dispatch | Bearer (Dispatcher) |
| `POST` | `/research/route-caution` | Flags damaged arterial roads as "NOT VERIFIED SAFE" | None / Bearer |
| `POST` | `/research/prediction-feedback`| Field responder ground-truth feedback on AI models | Bearer (Responder) |

---

## 8. Low-Bandwidth SMS & Voice Gateway (`/sms`)

| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/sms/inbound` | Inbound SMS webhook (5-min de-duplication) | Gateway Key / Open |
| `POST` | `/sms/whatsapp/inbound` | Inbound WhatsApp distress webhook | Gateway Key / Open |
| `POST` | `/sms/voice-note` | Transcribe 112 audio note & save playback link | Open / Citizen |
| `GET` | `/sms/voice-notes/:id` | Fetch voice note transcript and audio playback link | Bearer |
| `POST` | `/sms/simulate-offline-fallback`| Format offline emergency SMS (< 160 characters) | Open |
| `POST` | `/sms/status-callback` | Delivery receipt callback for outbound SMS | Provider Webhook |
| `GET` | `/sms/messages` | List all parsed inbound SMS records | Bearer (Govt/Admin) |

