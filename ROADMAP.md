# TravelersWorkoutTracker Roadmap

Work is broken into bite-sized chunks; each chunk is one buildable commit.
Check items off as they land. Pick up at the first unchecked item.

## Phase 1 — Code health (small, low risk)
- [ ] 1.1 Route mid-session exercise adds through ActiveSessionFactory
      (ActiveSessionView.addExerciseToActiveSession currently hand-builds
      ActiveSessionItem/ActiveSessionBlock; extract shared construction into
      the factory so defaults live in one place)
- [ ] 1.2 Add `Movement.sourceLabel` computed property; use it in
      AddExerciseToTemplateView, MovementListView, ExerciseDetailView
- [ ] 1.3 Extract one slugify helper in MovementEditorView (customMovementId
      and addCustomTag currently duplicate the regex)
- [ ] 1.4 Shared movement search filter used by AddExerciseToTemplateView and
      MovementListView (name + category + tags)
- [ ] 1.5 Minor view cleanups: hoist `isSelected` in MovementEditorView tag
      grid; deduplicate ForEach structure in MovementListView sections

## Phase 2 — Test foundation
- [ ] 2.1 Add a unit test target to the Xcode project
- [ ] 2.2 MovementSeeder tests: fresh seed, version-bump update, custom
      movements untouched, seed idempotency
- [ ] 2.3 Modality reconciliation tests (active session with now-invalid
      selectedModality gets repaired; completed/abandoned history untouched)
- [ ] 2.4 ActiveSessionItem.upsertLog and ActiveSessionFactory travel-mode
      substitution tests

## Phase 3 — Data durability
- [ ] 3.1 JSON export of all user data (movements, templates, sessions,
      history) via share sheet
- [ ] 3.2 JSON import/restore with merge-or-replace choice
- [ ] 3.3 CloudKit compatibility audit (SwiftData + CloudKit forbids
      @Attribute(.unique); all properties need defaults or optionals)
- [ ] 3.4 Enable CloudKit sync (needs iCloud capability + paid dev account —
      user step in Xcode)

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
