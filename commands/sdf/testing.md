# SDF Jump: Stage 7 -- Testing Strategy Questions

Re-run the testing strategy questions for an existing flow.

## Arguments
Flow name: $ARGUMENTS

## Instructions

1. **Resolve flow name.** If no name provided, check `.sdf/flows/` for active flows (exclude quest directories whose name contains `--`). If one, use it. If multiple, ask which one.

2. **Load flow state.** Read `.sdf/flows/<flow-name>/STATE.md`.
   - If `type: quest` (or the name contains `--`): tell the user "This is a quest, not a full flow. Quests inherit their testing strategy from the parent flow. Use `/sdf:quest <name>` to manage quests." Stop.
   - Verify the flow has a plan (Stage 5 or 6 completed).

3. **Trigger stage invalidation.** Mark stages 8, 9 as stale in STATE.md. Inform the user:
   > Re-running Stage 7 (testing strategy). Stages 8-9 are now marked as stale and will need to be re-run.

4. **Load context.** Read:
   - `.sdf/flows/<flow-name>/PLAN_<flow-name>.md`
   - `.sdf/flows/<flow-name>/TESTING_STRATEGY.md` (if it exists, for existing decisions)
   - `.sdf/CODEBASE_SCAN.md` (if it exists)

5. **Run Q&A rounds.** Focused exclusively on testing. Use the `AskUserQuestion` tool for all questions (up to 4 per call, batch larger rounds into sequential calls).

   **First round must include:**
   - Question: "What testing approach fits this implementation?"
   - Header: "Test type"
   - Options: "Unit tests" (isolated function/component tests) / "Integration tests" (hit real services/databases) / "End-to-end tests" (full user flow, e.g. Playwright/Cypress) / "Mix or other"

   Subsequent rounds dig deeper: frameworks, tooling, coverage, mocking strategy, edge cases, per-phase testing weight.

   Last question in the last batch of every round: "Do you need more questions?" with options "Yes, ask more" / "No, stop after this round" (header: "More Qs?")

6. **After rounds complete**, write all decisions to `.sdf/flows/<flow-name>/TESTING_STRATEGY.md`.

7. Update STATE.md to `current_stage: 7`. Tell the user:
   > Testing strategy complete. Run `/sdf:tests <flow-name>` for test design and review, or `/sdf <flow-name>` to continue.
