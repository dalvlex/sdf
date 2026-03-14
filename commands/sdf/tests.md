# SDF Jump: Stages 8-9 -- Test Design and Review

Re-run test design (Stage 8) and test review (Stage 9) for an existing flow.

## Arguments
Flow name: $ARGUMENTS

## Instructions

1. **Resolve flow name.** If no name provided, check `.sdf/flows/` for active flows. If one, use it. If multiple, ask which one.

2. **Load flow state.** Read `.sdf/flows/<flow-name>/STATE.md`. Verify the flow has a testing strategy (Stage 7 completed).

3. **Trigger stage invalidation.** Mark stage 9 as stale in STATE.md (since we are re-running Stage 8). Inform the user:
   > Re-running Stages 8-9 (test design and review).

4. **Load context.** Read:
   - `.sdf/flows/<flow-name>/PLAN_<flow-name>.md`
   - `.sdf/flows/<flow-name>/TESTING_STRATEGY.md`

---

## Stage 8: Test-First Phase Design

For each phase in the plan, write tests that define completion criteria using the testing strategy.

Write test specs to `.sdf/flows/<flow-name>/tests/phase_N_tests.md` (one file per phase).

Update STATE.md to `current_stage: 8`.

---

## Stage 9: Test Review and Calibration

Present the tests **per phase** to the user. For each phase, show:

> **Phase N: `<phase name>`**
> Tests:
> - Test 1: description
> - Test 2: description
> - ...
>
> (A) Tests look good -- approve
> (B) Need more tests -- specify what is missing
> (C) Too many tests / over-tested -- specify what to remove
> (D) Change specific test(s) -- specify which and how
> (E) Freeform feedback

Track approvals per phase in STATE.md.

**Approvals are soft.** The user can revoke any phase's approval at any time (e.g., "go back to Phase 2"). Show the amended tests, require re-approval.

**Stage 9 completes only when ALL phases are approved simultaneously.**

After all phases are approved:
1. Update STATE.md to `current_stage: 9, valid_stages: [1,2,3,4,5,6,7,8,9]`.
2. Ask the user:
   > All test suites approved. Ready to start implementation?
   > (A) Start implementation now -- run `/sdf:start <flow-name>`
   > (B) Make changes first -- use subcommands to revise, then start manually with `/sdf:start <flow-name>`

If (A): tell the user to run `/sdf:start <flow-name>` in a new conversation for fresh context.
If (B): the flow is saved and ready.
