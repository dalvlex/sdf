# SDF Jump: Stage 6 -- Gap-Filling Questions (Plan)

Re-run the gap-filling questions on the plan for an existing flow.

## Arguments
Flow name: $ARGUMENTS

## Instructions

1. **Resolve flow name.** If no name provided, check `.sdf/flows/` for active flows. If one, use it. If multiple, ask which one.

2. **Load flow state.** Read `.sdf/flows/<flow-name>/STATE.md`. Verify the flow has a plan (Stage 5 completed).

3. **Trigger stage invalidation.** Mark stages 7, 8, 9 as stale in STATE.md. Inform the user:
   > Re-running Stage 6 (plan questions). Stages 7-9 are now marked as stale and will need to be re-run.

4. **Load context.** Read:
   - `.sdf/flows/<flow-name>/PLAN_<flow-name>.md`
   - `.sdf/flows/<flow-name>/DECISIONS_PLAN.md` (if it exists)
   - `.sdf/CODEBASE_SCAN.md` (if it exists)

5. **Run Q&A rounds.** Use the `AskUserQuestion` tool for all questions (up to 4 per call, batch larger rounds into sequential calls). Each question gets 2-4 options (an "Other" freeform is added automatically).
   - The last question in the last batch of every round must be: "Do you need more questions?" with options "Yes, ask more" / "No, stop after this round" (header: "More Qs?").
   - After each round, write accumulated decisions to `.sdf/flows/<flow-name>/DECISIONS_PLAN.md`.
   - Update STATE.md checkpoint.

6. **After all rounds complete, update the plan.**
   - Apply all decisions to `.sdf/flows/<flow-name>/PLAN_<flow-name>.md`.
   - Present the updated plan to the user and use `AskUserQuestion` for approval:
     - Question: "Plan updated with all decisions. Approve?"
     - Header: "Plan"
     - Options: "Plan looks good -- approve" / "I want changes"
   - Repeat until approved.

7. Update STATE.md to `current_stage: 6`. Tell the user:
   > Stage 6 complete. Run `/sdf:testing <flow-name>` for testing strategy, or `/sdf <flow-name>` to continue.
