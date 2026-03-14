# SDF Stage 10: Autonomous Implementation

You are running the SDF autonomous implementation phase. This runs with a **fresh context** -- you have no conversation history from previous stages. Everything you need is in the `.sdf/` files.

## Setup

**Step 1: Determine the flow.**
Flow name from arguments: $ARGUMENTS

- If a flow name was provided, use it.
- If no flow name: check `.sdf/flows/` for active flows. If one exists, use it. If multiple, list them and ask the user which one.

**Step 2: Validate readiness.**
Read `.sdf/flows/<flow-name>/STATE.md`.

- If current_stage is less than 9: tell the user "This flow has not completed all planning stages. Run `/sdf <flow-name>` to continue planning first." Stop.
- If any stages are marked stale: warn the user:
  > WARNING: Some stages are stale -- outputs may not reflect the latest decisions.
  > Stale stages: N, M, ...
  > (A) Proceed anyway
  > (B) Cancel -- go back and re-run stale stages first
  Wait for response. If (B), stop.

**Step 3: Check concurrent implementation guard.**
Check all flow directories in `.sdf/flows/` (excluding `_archived`). If any other flow has `current_stage: 10` in its STATE.md:
> Flow "<other-flow>" is currently mid-implementation (Phase X/Y).
> Running two implementations concurrently risks file conflicts if both flows touch the same code.
> (A) Proceed anyway
> (B) Cancel -- finish the other flow first

Wait for response. If (B), stop.

---

## Load Plan and Tests

Read these files:
- `.sdf/flows/<flow-name>/PLAN_<flow-name>.md` -- the implementation plan
- `.sdf/flows/<flow-name>/TESTING_STRATEGY.md` -- testing approach
- `.sdf/flows/<flow-name>/tests/phase_N_tests.md` -- test specs for each phase
- `.sdf/CODEBASE_SCAN.md` -- if it exists, for codebase context
- `.sdf/LEARNINGS.md` -- if it exists, for project-wide learnings from previous flows

Parse the plan into phases. Determine the order of execution based on phase dependencies.

Update STATE.md to `current_stage: 10`.

**Create tasks for progress tracking.** Use `TaskCreate` to create one task per phase (in dependency order) so the user can see implementation progress at a glance. Each task title should be: `Phase N: <phase name>`.

---

## Implementation Loop

For each phase (in dependency order):

### 1. Start the phase
- Mark the phase's task as `in_progress` using `TaskUpdate`.
- Update `.sdf/flows/<flow-name>/phases/phase_N_status.md` with:
  ```
  status: in_progress
  started: <timestamp>
  ```
- Read the phase's plan section and test spec.

### 2. Implement the phase
Use a **subagent with fresh context** for each phase. The subagent receives:
- The phase's plan section (Goal, Implementation, Dependencies, Acceptance Criteria)
- The phase's test spec from `.sdf/flows/<flow-name>/tests/phase_N_tests.md`
- The codebase scan (if it exists) for project context
- The testing strategy for framework/tooling decisions
- **CLAUDE.md and README.md** from the project root (if they exist). The subagent must read and follow any conventions, rules, or constraints they specify.

The subagent implements the code described in the phase, then writes and runs the tests from the test spec. Include these explicit instructions in the subagent prompt:
- "You MUST write the actual test files described in the test spec and run them."
- "A successful build or type-check is NOT a substitute for tests. Tests must be written, executed, and passing."
- "Do not mark the phase as complete until real tests pass."

### 3. Run tests
After the subagent finishes, verify that actual test files were created and run them. Determine how to run tests from the testing strategy, codebase scan, and project config (e.g., `package.json` scripts, test runner config). If you cannot figure out how to run the tests, ask the user. If the subagent skipped writing tests, write them yourself and run them before evaluating results.

### 4. Evaluate results

**If all tests pass:**
- Mark the phase's task as `completed` using `TaskUpdate`.
- Update `.sdf/flows/<flow-name>/phases/phase_N_status.md`:
  ```
  status: passing
  tests_total: N
  tests_passing: N
  completed: <timestamp>
  ```
- Move to the next phase.

**If tests fail -- attempt to fix (up to 3 attempts):**

Each attempt must try a **meaningfully different approach**, not just tweak the same fix.

- **Attempt 1**: Analyze the failure. Identify the most likely root cause. Fix it.
- **Attempt 2**: If attempt 1 failed, reconsider the root cause. The cause you identified may be wrong. Try a different approach.
- **Attempt 3**: If attempt 2 failed, step back further. Re-read the phase plan and test spec. Consider whether the implementation approach itself is flawed, not just a bug in the code.

**Bug-fixing discipline:**
- **Fix the bug, do not fix the test.** Prefer fixing code over tailoring tests to pass around bugs. Tests represent the user's approved definition of done.
- **Anti-tail-chasing rule.** If each attempt is just adding complexity on top of the previous attempt, you are chasing your tail. Stop and escalate.

**After 3 failed attempts -- escalate:**
1. Mark the phase's task as `blocked` using `TaskUpdate` with a note about the failure.
2. Update `.sdf/flows/<flow-name>/phases/phase_N_status.md`:
   ```
   status: blocked
   tests_total: N
   tests_passing: M
   attempts: 3
   blocked_at: <timestamp>
   ```
3. Write a diagnosis to `.sdf/flows/<flow-name>/phases/phase_N_blocked.md`:
   ```markdown
   # Phase N Blocked: <phase name>

   ## Attempt 1
   - Root cause hypothesis: ...
   - What was tried: ...
   - Result: ...

   ## Attempt 2
   - Root cause hypothesis: ...
   - What was tried: ...
   - Result: ...

   ## Attempt 3
   - Root cause hypothesis: ...
   - What was tried: ...
   - Result: ...

   ## Current State
   - Tests passing: M/N
   - Failing tests: ...
   - Best hypothesis for remaining failures: ...

   ## Suggested Next Steps
   - ...
   ```
4. Return control to the user with a summary:
   > Phase N (`<phase name>`) is blocked after 3 attempts.
   > Passing: M/N tests.
   > See `.sdf/flows/<flow-name>/phases/phase_N_blocked.md` for full diagnosis.
   >
   > (A) I will fix it manually -- skip this phase and continue with the next
   > (B) Here is new guidance -- retry this phase (provide guidance)
   > (C) Skip this phase entirely
   > (D) Stop implementation -- I will handle this

Wait for user response and act accordingly.

---

## Completion

When all phases are processed (either passing, skipped, or blocked-and-user-decided):

1. Update STATE.md with final status.
2. Present a summary:
   ```
   SDF Implementation Complete: <flow-name>

   Phase 1: <name>    [passing]
   Phase 2: <name>    [passing]
   Phase 3: <name>    [blocked -- skipped by user]
   Phase 4: <name>    [passing]

   X/Y phases passing. Z skipped/blocked.
   ```
3. If all phases are passing:
   > All phases implemented and tested successfully.
   > Run `/sdf:done <flow-name>` to archive this flow.
4. If some phases are blocked/skipped:
   > Some phases need attention. Use `/sdf:status <flow-name>` to review.

---

## Important Rules

1. **Fresh context per phase.** Use subagents so each phase implementation gets a clean context window. Do not carry accumulated implementation context across phases.
2. **Files are the source of truth.** Read everything from `.sdf/` files. You have no conversation history from planning stages.
3. **3 attempts max.** Never exceed 3 fix attempts per phase. Escalate to the user.
4. **Do not modify tests.** Tests represent the user's approved definition of done. Fix the code, not the tests.
5. **Update status files.** Keep phase status files current so `/sdf:status` always reflects reality.
6. **A successful build is NOT a passing test.** You must run the actual test commands defined in the testing strategy. Type-checking or linting alone does not count as tests passing. If a phase has test specs, those tests must be written, executed, and passing.
7. **Capture learnings.** If you discover something non-obvious during implementation (environment quirks, setup steps, service behaviors, gotchas, workarounds), append it to `.sdf/LEARNINGS.md` with the flow name and date. This file is project-wide and persists across flows.
