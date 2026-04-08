# SDF Jump: Stage 5 -- Plan Generation

Re-generate the implementation plan for an existing flow.

## Arguments
Flow name: $ARGUMENTS

## Instructions

1. **Resolve flow name.** If no name provided, check `.sdf/flows/` for active flows (exclude quest directories whose name contains `--`). If one, use it. If multiple, ask which one.

2. **Load flow state.** Read `.sdf/flows/<flow-name>/STATE.md`.
   - If `type: quest` (or the name contains `--`): tell the user "This is a quest, not a full flow. Quest plans are managed within `/sdf:quest <name>`." Stop.
   - Verify the flow exists and has at least a refined ask (Stage 4 completed).

3. **Trigger stage invalidation.** Mark stages 6, 7, 8, 9 as stale in STATE.md. Inform the user:
   > Re-running Stage 5 (plan generation). Stages 6-9 are now marked as stale and will need to be re-run.

4. **Load context.** Read:
   - `.sdf/flows/<flow-name>/REFINED_ASK.md`
   - `.sdf/CODEBASE_SCAN.md` (if it exists)
   - `.sdf/flows/<flow-name>/PLAN_<flow-name>.md` (if it exists, for reference on what to change)

5. **Generate the plan.** Each phase follows this structure:

   ```markdown
   # Phase N: <name>

   ## Goal
   What this phase achieves in one or two sentences.

   ## Implementation
   What to build. Which files to create or modify. Key logic and behavior.

   ## Dependencies
   Which phases must complete before this one, if any. "None" if independent.

   ## Acceptance Criteria
   How to know this phase is done. Maps directly to tests written in Stage 8.
   ```

6. **Write the plan** to `.sdf/flows/<flow-name>/PLAN_<flow-name>.md`.

7. **Present to user** and ask:
   > Here is the regenerated plan. Review it.
   > Run `/sdf:plan-questions <flow-name>` to refine it with questions, or `/sdf <flow-name>` to continue the flow.

8. Update STATE.md to `current_stage: 5`.
