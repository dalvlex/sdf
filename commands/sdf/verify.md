# SDF Verify: Run Tests and Fix Failures

Run all tests for a flow's phases. Write tests from specs if they don't exist yet. Fix failures with the same 3-attempt escalation as Stage 10.

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
   - `.sdf/LEARNINGS.md` (if it exists) -- project-wide learnings from previous flows and quests
   - `CLAUDE.md` and `README.md` from the project root (if they exist) -- follow any conventions they specify

4. **Reset all phase statuses.** Before running any tests, reset every phase's status to `pending`. For each phase, update `.sdf/flows/<flow-name>/phases/phase_N_status.md`:
   ```
   status: pending
   ```
   Set `all_phases_passing: false` in STATE.md. This ensures no stale "verified" status survives from a previous run -- every phase must re-earn its status by actually passing tests.

5. **Create tasks for progress tracking.** Use `TaskCreate` to create one task per phase: `Verify Phase N: <phase name>`.

---

## Verification Loop

For each phase (in dependency order):

### 1. Check if tests exist in the codebase
Look for the actual test files described in the phase's test spec. If the test files don't exist yet, write them from the test spec using the testing strategy.

### 2. Run the tests
Determine how to run tests from the testing strategy, codebase scan, and project config (e.g., `package.json` scripts, test runner config). If you cannot figure out how to run the tests, ask the user. A successful build or type-check does NOT count as tests passing.

### 3. Evaluate results

**If all tests pass:**
- Mark the phase's task as `completed` using `TaskUpdate`.
- Update `.sdf/flows/<flow-name>/phases/phase_N_status.md`:
  ```
  status: verified
  tests_total: N
  tests_passing: N
  verified_at: <timestamp>
  ```
- Move to the next phase.

**If tests fail -- attempt to fix (up to 3 attempts):**

Each attempt must try a **meaningfully different approach**, not just tweak the same fix.

- **Attempt 1**: Analyze the failure. Identify the most likely root cause. Fix the code.
- **Attempt 2**: If attempt 1 failed, reconsider the root cause. Try a different approach.
- **Attempt 3**: If attempt 2 failed, step back further. Re-read the phase plan and test spec. Consider whether the implementation approach itself is flawed.

**Bug-fixing discipline:**
- **Fix the bug, do not fix the test.** Tests represent the user's approved definition of done.
- **Run only failing tests during fix attempts.** When a test fails, re-run only the failing test(s) while fixing -- not the full suite. After all failing tests pass individually, run the full phase suite once to confirm nothing else broke.
- **Anti-tail-chasing rule.** If each attempt is just adding complexity on top of the previous attempt, stop and escalate.

**After 3 failed attempts -- escalate:**
1. Mark the phase's task as `blocked` using `TaskUpdate`.
2. Update `.sdf/flows/<flow-name>/phases/phase_N_status.md`:
   ```
   status: blocked
   attempts: 3
   blocked_at: <timestamp>
   ```
3. Write a diagnosis to `.sdf/flows/<flow-name>/phases/phase_N_blocked.md` with all 3 attempts, current state, and suggested next steps.
4. Return control to the user:
   > Phase N (`<phase name>`) is blocked after 3 attempts.
   > Passing: M/N tests.
   > See `.sdf/flows/<flow-name>/phases/phase_N_blocked.md` for full diagnosis.
   >
   > (A) I will fix it manually -- skip this phase and continue
   > (B) Here is new guidance -- retry this phase
   > (C) Skip this phase entirely
   > (D) Stop verification

Wait for user response and act accordingly.

---

## Completion

When all phases are processed:

1. Present a summary:
   ```
   SDF Verification: <flow-name>

   Phase 1: <name>    [verified]
   Phase 2: <name>    [verified]
   Phase 3: <name>    [blocked]
   Phase 4: <name>    [verified]

   X/Y phases verified. Z blocked.
   ```
2. If all verified: "All phases verified and passing."
3. If some blocked: "Some phases need attention. Use `/sdf:status <flow-name>` to review."

---

## Important Rules

1. **A successful build is NOT a passing test.** Run actual test commands from the testing strategy.
2. **Do not modify tests.** Fix the code, not the tests.
3. **3 attempts max.** Escalate to the user after 3 failed fix attempts.
4. **Update status files.** Keep phase status files current.
5. **Capture learnings.** If you discover something non-obvious during verification (environment quirks, setup steps, service behaviors, gotchas, workarounds), append it to `.sdf/LEARNINGS.md` with the flow name and date.
