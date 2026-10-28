# ResQAI Kept on Purpose Register
**Compliance with PRD v3.0 CLN-7 and CLN-8**

---

The following modules, files, and architectures may appear redundant or unused during static code analysis, but are **actively required** and must NOT be removed:

1. **`server/src/db/schema.sql`**: Full relational schema containing 40+ domain tables (cases, drills, ledger, transparent funds, missing persons, audit logs).
2. **`server/src/services/floodMLService.ts`**: Calibrated flood risk inference, SHAP attribution, and stale telemetry detector used for early warnings.
3. **`server/src/services/smsAdapterService.ts`**: Telephony adapter providing dual-mode execution (real Twilio / cellular SMS provider and mock simulator fallback for offline tests).
4. **`server/test/*.test.ts` (18 test suites)**: Exhaustive test coverage proving Phase 1 through Phase 9 compliance.
5. **`lib/data/services/demo_data_service.dart`**: Watermarked demo dataset (`is_demo=true`) providing offline mock state for field responder demonstration without an active internet connection.
6. **`server/.env.example`**: Complete environment variable template with empty defaults.

