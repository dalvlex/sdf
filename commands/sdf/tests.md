# SDF Jump: Stages 8-9 -- Test Design and Review

Re-run test design (Stage 8) and test review (Stage 9) for an existing flow.

## Arguments
Flow name: $ARGUMENTS

## Instructions

1. **Resolve flow name.** If no name provided, check `.sdf/flows/` for active flows (exclude quest directories whose name contains `--`). If one, use it. If multiple, ask which one.

2. **Load flow state.** Read `.sdf/flows/<flow-name>/STATE.md`.
   - If `type: quest` (or the name contains `--`): tell the user "This is a quest, not a full flow. Quest tests are auto-generated during implementation. Use `/sdf:quest <name>` to manage quests." Stop.
   - Verify the flow has a testing strategy (Stage 7 completed).

3. **Trigger stage invalidation.** Mark stage 9 as stale in STATE.md (since we are re-running Stage 8). Inform the user:
   > Re-running Stages 8-9 (test design and review).

4. **Load context.** Read:
   - `.sdf/flows/<flow-name>/PLAN_<flow-name>.md`
   - `.sdf/flows/<flow-name>/TESTING_STRATEGY.md`

---

## Stage 8: Test-First Phase Design

For each phase in the plan, write tests that define completion criteria using the testing strategy.

Write test specs to `.sdf/flows/<flow-name>/tests/phase_N_tests.md` (one file per phase). If a phase has no dedicated tests because it is fully covered by another phase's tests, do not create a test file for it -- instead note in STATE.md which phases' tests cover it (e.g., `phase_1: covered by phase 3, 4 tests`).

Update STATE.md to `current_stage: 8`.

---

## Stage 9: Test Review and Calibration

Present the tests **per phase** to the user. For each phase, show the test list as text, then use `AskUserQuestion` for the verdict:

- Question: "Phase N: `<phase name>` -- verdict on these tests?"
- Header: "Phase N"
- Options: "Approve" / "Need more tests" / "Too many tests" / "Change specific test(s)"

Track approvals per phase in STATE.md.

**Approvals are soft.** The user can revoke any phase's approval at any time (e.g., "go back to Phase 2"). Show the amended tests, require re-approval.

**Stage 9 completes only when ALL phases are approved simultaneously.**

After all phases are approved:
1. Update STATE.md to `current_stage: 9, valid_stages: [1,2,3,4,5,6,7,8,9]`.
2. Use `AskUserQuestion`:
   - Question: "All test suites approved. Ready to start implementation?"
   - Header: "Implement?"
   - Options: "Start now" / "Start in a new conversation (recommended for large plans)" / "Make changes first"

If **start now**: proceed directly to Stage 10 implementation in this conversation.
If **new conversation**: tell the user to run `/sdf:implement <flow-name>` in a new conversation for fresh context. The flow is saved and ready.
If **make changes first**: the flow is saved and ready.
