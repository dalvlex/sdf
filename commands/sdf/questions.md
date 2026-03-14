# SDF Jump: Stage 3 -- Gap-Filling Questions (Ask)

Re-run the gap-filling questions on the ask for an existing flow.

## Arguments
Flow name: $ARGUMENTS

## Instructions

1. **Resolve flow name.** If no name provided, check `.sdf/flows/` for active flows. If one, use it. If multiple, ask which one.

2. **Load flow state.** Read `.sdf/flows/<flow-name>/STATE.md`. Verify the flow exists and has at least completed Stage 2.

3. **Trigger stage invalidation.** Mark stages 4, 5, 6, 7, 8, 9 as stale in STATE.md. Inform the user:
   > Re-running Stage 3 (ask questions). Stages 4-9 are now marked as stale and will need to be re-run.

4. **Load context.** Read:
   - `.sdf/flows/<flow-name>/REFINED_ASK.md` (if it exists, for reference)
   - `.sdf/flows/<flow-name>/DECISIONS_ASK.md` (if it exists, for existing decisions)
   - `.sdf/CODEBASE_SCAN.md` (if it exists)

5. **Run Q&A rounds.** Use the `AskUserQuestion` tool for all questions (up to 4 per call, batch larger rounds into sequential calls). Each question gets 2-4 options (an "Other" freeform is added automatically).
   - The last question in the last batch of every round must be: "Do you need more questions?" with options "Yes, ask more" / "No, stop after this round" (header: "More Qs?").
   - After each round, write accumulated decisions to `.sdf/flows/<flow-name>/DECISIONS_ASK.md`.
   - Update STATE.md checkpoint.

6. **When rounds complete**, tell the user:
   > Stage 3 questions complete. Run `/sdf <flow-name>` to continue from Stage 4 (refined ask), or use other subcommands.
