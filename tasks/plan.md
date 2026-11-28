# Implementation Plan: AI-Guardian UI/UX Overhaul

## Overview
Improve the existing Flutter product shell and core security screens with a coherent premium security-dashboard design, stronger responsive layouts, accessible interaction states, and focused tests while preserving Riverpod state, GoRouter routes, API contracts, real metrics, QR/SSRF behavior, and existing security CI.

## Audit findings
- Existing foundation: Material 3 theme, shared design primitives, Riverpod providers, GoRouter transitions, persisted theme/language/sidebar state.
- Existing risks: repeated ad hoc layout patterns and weak visual hierarchy across core security views; small-screen and desktop spacing needed stronger shared treatment.
- Security boundary: no backend or scanner algorithm changes; all displayed statistics remain API-backed.

## Task List

### Phase 1: Foundation
- [x] Refine shared design tokens, surface/card primitives, typography, focus/hover states, and responsive page scaffold.
- [x] Add reusable dashboard/status presentation and motion-aware page entrance.

### Checkpoint: Foundation
- [x] `flutter analyze` passes.
- [x] Existing widget tests still pass.

### Phase 2: Core product screens
- [x] Rework dashboard hierarchy, live status visualization, metrics, quick actions, and recent activity using real provider data.
- [x] Apply shared responsive UX to history, learning, process safety, QR, and settings screens.
- [x] Preserve scanner/process/theme behavior and API contracts.

### Phase 3: QA and release
- [x] Add focused widget coverage for shared UI states and redesigned interactions.
- [ ] Run release builds, commit, push feature branch, open PR, and verify GitHub Actions.

## Risks and mitigations
| Risk | Impact | Mitigation |
|---|---|---|
| UI changes break existing text-based widget tests | Medium | Preserve route labels and API-backed semantics; run tests after each screen group. |
| Responsive layout regressions | High | Use constrained layouts and existing multi-size tests. |
| Decorative UI implies fabricated security data | High | Bind metrics/status to existing providers and label unavailable data explicitly. |
| Animation harms reduced-motion users | Medium | Respect `MediaQuery.disableAnimationsOf` and keep transitions short. |
