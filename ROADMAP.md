# TravelersWorkoutTracker Roadmap

Work is broken into bite-sized chunks; each chunk is one buildable commit.
Check items off as they land. Pick up at the first unchecked item.

## Phase 1 — Code health (small, low risk)
- [x] 1.1 Route mid-session exercise adds through ActiveSessionFactory
      (ActiveSessionView.addExerciseToActiveSession currently hand-builds
      ActiveSessionItem/ActiveSessionBlock; extract shared construction into
      the factory so defaults live in one place)
- [x] 1.2 Add `Movement.sourceLabel` computed property; use it in
      AddExerciseToTemplateView, MovementListView, ExerciseDetailView
- [x] 1.3 Extract one slugify helper in MovementEditorView (customMovementId
      and addCustomTag currently duplicate the regex)
- [x] 1.4 Shared movement search filter used by AddExerciseToTemplateView and
      MovementListView (name + category + tags)
- [x] 1.5 Minor view cleanups: hoist `isSelected` in MovementEditorView tag
      grid; deduplicate ForEach structure in MovementListView sections

## Phase 2 — Test foundation
- [x] 2.1 (already existed) Add a unit test target to the Xcode project
- [x] 2.2 MovementSeeder tests: fresh seed, version-bump update, custom
      movements untouched, seed idempotency
- [x] 2.3 Modality reconciliation tests (active session with now-invalid
      selectedModality gets repaired; completed/abandoned history untouched)
- [x] 2.4 ActiveSessionItem.upsertLog and ActiveSessionFactory travel-mode
      substitution tests

## Phase 3 — Data durability
- [x] 3.1 JSON export of all user data (movements, templates, sessions,
      history) via share sheet
- [x] 3.2 JSON import/restore with merge-or-replace choice
- [x] 3.3 CloudKit compatibility audit (SwiftData + CloudKit forbids
      @Attribute(.unique); all properties need defaults or optionals)

      Audit findings (2026-07-04):
      * All 6 models use `@Attribute(.unique)` on `id` — must be removed.
        Safe: no code relies on unique-constraint upserts (seeder, restore,
        and editors all dedupe manually or use fresh UUIDs).
      * Stored properties need in-declaration defaults (or optionals) in all
        6 models.
      * `WorkoutSession.sessionExercises` relationship must become optional
        (CloudKit rule); ~6 call sites need `?? []`.
      * `.externalStorage` attributes are fine (become CKAssets); cascade
        delete rule is fine; no deny rules in use.
- [ ] 3.4 Enable CloudKit sync
      - [ ] 3.4a Code prep: apply the model changes from the 3.3 audit
      - [ ] 3.4b User step in Xcode: add iCloud capability (CloudKit) +
            Background Modes remote-notification; container id
            iCloud.com.luckynumberthirteen.TravelersWorkoutTracker
      - [ ] 3.4c Switch ModelContainer to a CloudKit-backed
            ModelConfiguration and verify sync between two devices

## Phase 4 — Equipment-based substitution (travel-mode v2)
- [ ] 4.1 "Hotel gym equipment" profile: model + picker UI (reuse
      EquipmentFilterView patterns)
- [ ] 4.2 In active session, suggest substitutes filtered by available
      equipment when a movement's modalities don't fit
- [ ] 4.3 Keep hotelAlternativeMovementId as the preferred suggestion, fall
      back to equipment-based matches

## Deferred (agreed, revisit later)
- kg/lb unit support (weight is currently a bare Int)
- Rest timer + lock-screen Live Activity for active sessions
- Progress charts (Swift Charts over existing history: per-movement
  progression, weekly volume by tag, PRs)
- Stretch: enum-backed movement category; seed migration registry instead of
  a single version number
