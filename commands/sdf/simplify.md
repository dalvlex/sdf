# SDF Simplify: Code Cleanup After Implementation

Review and simplify code produced by a flow's implementation. Make the code shorter, drier, and more readable -- not differently organized.

## Arguments
Flow name: $ARGUMENTS

## Instructions

1. **Resolve flow name.** If no name provided, check `.sdf/flows/` for active flows and quests (all subdirectories excluding `_archived`). If one, use it. If multiple, ask which one.

2. **Load flow state.** Read `.sdf/flows/<flow-name>/STATE.md`. Check the `type` field:
   - If `type: quest` (or the name contains `--`): verify `current_stage` is at least 4 (implementation started or completed).
   - Otherwise (full flow): verify `current_stage` is at least 10 (implementation started or completed).
   If not ready, tell the user which command to run first (`/sdf <flow-name>` for flows, `/sdf:quest <quest-name>` for quests). Stop.

3. **Load context.** Read:
   - `.sdf/flows/<flow-name>/PLAN_<flow-name>.md` -- this applies to both flows and quests (e.g., `PLAN_rehab-tracker--add-week-block.md` for a quest named `rehab-tracker--add-week-block`)
   - `.sdf/flows/<flow-name>/TESTING_STRATEGY.md` -- if not found and this is a quest, read from the parent flow's directory (the `parent` field in STATE.md points to `.sdf/flows/<parent>/TESTING_STRATEGY.md`). If parent is `standalone` or no strategy exists anywhere, infer testing approach from `.sdf/CODEBASE_SCAN.md`.
   - `.sdf/flows/<flow-name>/tests/phase_N_tests.md` for each phase
   - `.sdf/CODEBASE_SCAN.md` (if it exists)
   - `.sdf/LEARNINGS.md` (if it exists)
   - `CLAUDE.md` and `README.md` from the project root (if they exist) -- follow any conventions they specify

4. **Create tasks for progress tracking.** Use `TaskCreate` to create one task per phase: `Simplify Phase N: <phase name>`.

---

## Simplification Loop

For each phase (in dependency order):

### 1. Review the phase's code
Read the files created or modified by this phase. Look for concrete simplification opportunities:
- **Duplicate code** that can be extracted into a shared function or constant
- **Unnecessary complexity** -- overly nested logic, verbose patterns that have simpler equivalents
- **Dead code** -- unused imports, unreachable branches, variables assigned but never read
- **Inconsistencies** with existing project conventions (from CLAUDE.md or codebase scan)

### 2. Apply simplifications
Make changes one logical group at a time. After each group of related changes, run the phase's tests to confirm nothing broke.

### 3. Verify after simplification
Run the full phase test suite after all simplifications for this phase are done. If tests fail, revert the last change and try a different approach (up to 3 attempts per failing simplification). If a simplification can't be made without breaking tests, skip it.

### 4. Move to the next phase
Mark the phase's task as `completed` using `TaskUpdate`.

---

## Scope Rules

**You may modify any file**, but every change must be directly related to the current flow's implementation.

- **In scope**: a change that wouldn't exist without this feature. Files the feature created, modified, or directly depends on.
- **Out of scope**: a change that would be useful regardless of this feature. Pre-existing code the feature doesn't interact with.

Examples of what's allowed:
- Extracting a shared utility from two new files into an existing helper
- Simplifying an existing function that the feature modified or depends on
- DRYing up a pattern where the new code duplicates something already in the codebase

Examples of what's NOT allowed:
- Refactoring an unrelated module just because you noticed it while browsing
- Cleaning up pre-existing code that the feature doesn't interact with
- Renaming variables in files the feature never touches or calls

---

## Quality Bar

Only simplify when there is a clear, concrete improvement. Each change must make the code shorter, drier, or more readable. If you can't explain the improvement in one sentence, don't make the change.

**The bar: would a senior developer look at this diff and say "yes, obviously better"?** If not, skip it.

**Explicitly banned:**
- Renaming for style preference
- Moving code between files without reducing it
- Adding abstractions that don't reduce duplication
- Extracting functions that are only called once
- Rewriting working code in a "cleaner" style that's the same length
- Adding comments, docstrings, or documentation

---

## Completion

When all phases are processed:

1. Present a summary of changes made:
   ```
   SDF Simplify: <flow-name>

   Phase 1: <name>    2 simplifications (removed 15 lines)
   Phase 3: <name>    1 simplification (extracted shared helper)
   Phase 4: <name>    no changes needed

   Total: X simplifications, Y lines removed
   ```
2. Run the full test suite one final time to confirm everything passes.

---

## Important Rules

1. **Tests must pass.** Every simplification must leave tests passing. If tests break, revert.
2. **Less code is better.** The primary metric is fewer lines, fewer abstractions, less complexity.
3. **Do not change behavior.** Simplifications must be strictly behavior-preserving.
4. **Do not modify tests.** Tests are the definition of done. Only modify implementation code.
5. **Capture learnings.** If you discover something non-obvious, append it to `.sdf/LEARNINGS.md`.
6. **Run only failing tests during fix attempts.** Full suite only after all fixes pass.
