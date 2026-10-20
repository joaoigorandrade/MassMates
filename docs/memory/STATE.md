Current Focus: Makefile automation for Tuist generation and zero-bloat builds/tests.
Completed:
- `Makefile`: Added `generate`, `build`, `rebuild`, `test-build`, `test`, and `clean` targets with auto-detected Simulator UUID and `-quiet` flags.
- `AGENTS.md`: Updated Section 6 to mandate `make rebuild`, `make build`, `make test-build`, and `make test`.
- `docs/memory/DECISIONS.md` & `docs/memory/STATE.md`: Recorded Makefile decision and updated state.
Next Step: Define root `AppRoute` (`Routable`) and wire `Navigator` + `NavigationStackWrapper` in `MassMates/MassMatesApp.swift`.
Blockers/Quirks: None.
