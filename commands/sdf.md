# SDF -- Supervised Decision Flow

You are running the SDF (Supervised Decision Flow) orchestrator. Follow these instructions precisely, stage by stage.

## Initial Setup

**Step 1: Check for arguments.**
The user may have provided a flow name: $ARGUMENTS

- If a flow name was provided, skip to **Resume Flow** below.
- If no arguments, continue to Step 2.

**Step 2: Check for existing flows.**
Check if `.sdf/flows/` exists and contains any subdirectories (excluding `_archived`).

- If **no flows exist**: proceed directly to **Brownfield Detection**, then **Stage 1**.
- If **one flow exists**: ask the user:
  > SDF found an existing flow: `<flow-name>` (currently at Stage N).
  > (A) Resume this flow
  > (B) Start a new flow
- If **multiple flows exist**: ask the user:
  > SDF found existing flows:
  > - `<flow-1>` -- Stage N
  > - `<flow-2>` -- Stage N
  > (A) Resume an existing flow -- which one?
  > (B) Start a new flow

Wait for the user's response before proceeding.

---

## Resume Flow

Read `.sdf/flows/<flow-name>/STATE.md` to determine the current stage and checkpoint. Resume from where the flow left off. If any stages are marked stale, warn the user before proceeding past them.

---

## Brownfield Detection

Check if the project directory contains an existing codebase (source files, package.json, Cargo.toml, build configs, etc.). Ignore the `.sdf/` directory itself.

- If **existing codebase found**: perform a lightweight scan and write results to `.sdf/CODEBASE_SCAN.md`. The scan should capture:
  - **Project purpose**: what the application does, its domain, and target users (check README, package.json description, or infer from code)
  - **CLAUDE.md rules**: if any CLAUDE.md files exist (root or subdirectories), read them and summarize key rules, conventions, and constraints -- these override defaults
  - **Tech stack and frameworks**: languages, frameworks, major libraries
  - **Project structure**: key directories and their roles
  - **Existing conventions**: naming patterns, architecture style, code organization patterns
  - **Relevant configuration**: build tools, linters, formatters, environment setup
  - **Testing setup**: test framework(s), test directory structure, existing helpers/fixtures, how to run tests
  - **Core entities/models**: key domain objects and their relationships (check models/, types/, or schema files)
  Then tell the user: "Codebase scan complete. This will inform all stages."

- If **no codebase found** (empty or no meaningful code): skip the scan, proceed as greenfield. If `.sdf/CODEBASE_SCAN.md` already exists from a previous flow, keep it.

---

## Stage 1: State the Ask

Tell the user:
> **Stage 1: State your ask.**
> Describe what you want to build or change. Be as messy or detailed as you like -- I will structure it for you.

Wait for the user to describe their ask. Do not proceed until they have provided it.

---

## Stage 2: Echo Back

Restate the user's ask back to them -- clear, succinct, and structured.

- If `.sdf/CODEBASE_SCAN.md` exists, reflect how the ask fits within the existing project.
- If other active flows exist, note any potential overlap or interaction with them.

Then use `AskUserQuestion` to confirm:
- Question: "Does this capture your intent?"
- Header: "Echo Back"
- Options: "Yes, confirmed" / "Needs correction" / "Add something"

If the user corrects or adds, incorporate changes, echo back again, and re-ask. Repeat until confirmed.

---

## Stage 3: Gap-Filling Questions (on the Ask)

Identify important ambiguities in the ask and prepare targeted questions. Run in **rounds**.

### Each round:

Use the `AskUserQuestion` tool to present questions interactively. Each question gets 2-4 preset options (an "Other" freeform option is added automatically by the tool). The tool accepts up to 4 questions per call, so if a round has more than 4 questions, present them in sequential batches of up to 4.

Each question requires: `question` (the question text), `header` (short label, max 12 chars), `options` (2-4 choices with `label` and `description`), and `multiSelect` (usually false).

**Mandatory questions in the first round:**
1. **Flow name**: Suggest a short, hyphenated name for this flow (e.g., `admin-interface`, `auth-overhaul`). This becomes both the plan filename and the flow identifier.
   - Header: "Flow name"
   - Options: "Accept `<your-suggestion>`" / "Different name"

**The last question in EVERY round must be (always in the last batch):**
- Question: "Do you need more questions?"
- Header: "More Qs?"
- Options: "Yes, ask more" / "No, stop after this round"

Wait for the user's answers via the tool.

### After each round:

1. Interpret and apply all answers from this round.
2. **After the first round** (once the flow name is established): check if `.sdf/flows/<flow-name>/` already exists. If it does, warn the user and ask for a different name. Then create the directory and all subdirectories (`tests/`, `phases/`).
3. Write all accumulated decisions to `.sdf/flows/<flow-name>/DECISIONS_ASK.md`.
4. Update `.sdf/flows/<flow-name>/STATE.md` with:
   ```
   current_stage: 3
   stage_name: Gap-Filling Questions (Ask)
   round: <N>
   valid_stages: [1, 2, 3]
   ```

### Round continuation:
- If the user answered **(A) Yes, ask more**: prepare another round of questions based on remaining ambiguities and gaps. Repeat the round process.
- If the user answered **(B) No, stop after this round**: proceed to Stage 4.
- If you have no more meaningful questions to ask, tell the user: "I have no more gaps to fill. Proceeding to the refined ask." Then proceed to Stage 4.

---

## Stage 4: Refined Ask

Read `.sdf/flows/<flow-name>/DECISIONS_ASK.md` to ensure you have all decisions.

Present the completed ask -- enriched by all the Q&A -- to the user. This should be clear, structured, and comprehensive.

Then use `AskUserQuestion` to get approval:
- Question: "Is this refined ask accurate and complete?"
- Header: "Refined Ask"
- Options: "Yes, approve it" / "I want to edit it" / "Let me provide edits directly"

- If **approved**: write the refined ask to `.sdf/flows/<flow-name>/REFINED_ASK.md`. Update STATE.md to `current_stage: 4, valid_stages: [1,2,3,4]`. Proceed to Stage 5.
- If **edit requested**: incorporate edits, present again, repeat until approved.

---

## Stage 5: Plan Generation

Read `.sdf/flows/<flow-name>/REFINED_ASK.md`. Also read `.sdf/CODEBASE_SCAN.md` if it exists.

Generate a full implementation plan. Each phase must follow this structure:

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

Phases can include additional sections if needed (migration steps, external service setup, etc.). Each phase must have enough detail for independent implementation and enough acceptance criteria for tests.

Write the plan to `.sdf/flows/<flow-name>/PLAN_<flow-name>.md`.

Present the plan to the user. Then use `AskUserQuestion`:
- Question: "Plan generated. How would you like to proceed?"
- Header: "Plan"
- Options: "Ready for plan questions" / "I have initial thoughts first"

If **ready**: update STATE.md to `current_stage: 5, valid_stages: [1,2,3,4,5]`. Proceed to Stage 6.
If **initial thoughts**: let the user share thoughts, incorporate if needed, then proceed to Stage 6.

---

## Stage 6: Gap-Filling Questions (on the Plan)

Read `.sdf/flows/<flow-name>/PLAN_<flow-name>.md`.

Same question mechanism as Stage 3 -- use `AskUserQuestion` for all questions, up to 4 per call, with the closing question always in the last batch:

- Question: "Do you need more questions?"
- Header: "More Qs?"
- Options: "Yes, ask more" / "No, stop after this round"

After each round:
1. Write accumulated decisions to `.sdf/flows/<flow-name>/DECISIONS_PLAN.md`.
2. Update STATE.md checkpoint.

When rounds are complete (user says stop or no more gaps):
1. **Update the plan**: apply all decisions to `.sdf/flows/<flow-name>/PLAN_<flow-name>.md`.
2. Present the **updated plan** to the user and use `AskUserQuestion` for approval:
   - Question: "Plan updated with all decisions. Approve?"
   - Header: "Plan"
   - Options: "Plan looks good -- approve" / "I want changes"
3. Repeat until approved.
4. Update STATE.md to `current_stage: 6, valid_stages: [1,2,3,4,5,6]`. Proceed to Stage 7.

---

## Stage 7: Testing Strategy Questions

A dedicated round-based Q&A focused exclusively on testing. Use `AskUserQuestion` for all questions, up to 4 per call.

**First round must include this question:**
- Question: "What testing approach fits this implementation?"
- Header: "Test type"
- Options: "Unit tests" (isolated function/component tests) / "Integration tests" (hit real services/databases) / "End-to-end tests" (full user flow, e.g. Playwright/Cypress) / "Mix or other"

Subsequent rounds (if requested) dig deeper: specific frameworks and tooling, coverage expectations, what to mock vs hit real, edge cases to cover, performance thresholds, phases needing heavier vs lighter testing.

Same closing question in the last batch of every round:
- Question: "Do you need more questions?"
- Header: "More Qs?"
- Options: "Yes, ask more" / "No, stop after this round"

After rounds complete: write all decisions to `.sdf/flows/<flow-name>/TESTING_STRATEGY.md`.
Update STATE.md to `current_stage: 7, valid_stages: [1,2,3,4,5,6,7]`. Proceed to Stage 8.

---

## Stage 8: Test-First Phase Design

Read `.sdf/flows/<flow-name>/PLAN_<flow-name>.md` and `.sdf/flows/<flow-name>/TESTING_STRATEGY.md`.

For each phase in the plan, write tests that define completion criteria. Use the testing strategy established in Stage 7.

Write test specs to `.sdf/flows/<flow-name>/tests/phase_N_tests.md` (one file per phase). If a phase has no dedicated tests because it is fully covered by another phase's tests, do not create a test file for it -- instead note in STATE.md which phases' tests cover it (e.g., `phase_1: covered by phase 3, 4 tests`).

Update STATE.md to `current_stage: 8, valid_stages: [1,2,3,4,5,6,7,8]`. Proceed to Stage 9.

---

## Stage 9: Test Review and Calibration

Present the tests **per phase** to the user. For each phase, show the test list as text, then use `AskUserQuestion` for the verdict:

- Question: "Phase N: `<phase name>` -- verdict on these tests?"
- Header: "Phase N"
- Options: "Approve" / "Need more tests" / "Too many tests" / "Change specific test(s)"

Track approvals per phase in STATE.md.

**Approvals are soft.** The user can revoke any phase's approval at any time by saying so (e.g., "go back to Phase 2"). When revoked, show the tests for that phase again after applying changes. Re-approval is required.

**Stage 9 completes only when ALL phases are approved simultaneously.**

After all phases are approved:
1. Update STATE.md to `current_stage: 9, valid_stages: [1,2,3,4,5,6,7,8,9]`.
2. Use `AskUserQuestion`:
   - Question: "All test suites approved. Ready to start implementation?"
   - Header: "Implement?"
   - Options: "Start now" / "Start in a new conversation (recommended for large plans)" / "Make changes first"

If **start now**: proceed directly to Stage 10 implementation in this conversation.
If **new conversation**: tell the user to run `/sdf:start <flow-name>` in a new conversation for fresh context. The flow is saved and ready.
If **make changes first**: the flow is saved and ready. The user can use subcommands to revise and start when ready.

---

## Checkpointing Rules

After EVERY meaningful interaction (each question round, each approval, each stage transition), update `.sdf/flows/<flow-name>/STATE.md` with:

STATE.md must always use this structure:

```
current_stage: <number>
stage_name: <human-readable name>
valid_stages: [<list of non-stale stage numbers>]
```

Optional fields (include when relevant):
```
round: <number>                    # during Q&A stages (3, 6, 7)
phase_approvals:                   # during Stage 9
  phase_1: approved
  phase_2: covered by phase 3, 4 tests
  phase_3: pending
```

Always use this exact field naming. This ensures that `/sdf <flow-name>` can parse STATE.md reliably when resuming.

---

## Stage Invalidation

If this flow is being resumed and has stale stages, warn before proceeding past them:

> WARNING: Stages N-M were built against an older version of a previous stage's output.
> (A) Re-run from Stage N
> (B) Proceed anyway (use existing outputs)

The invalidation chain:
- Stage 3 re-run invalidates: 4, 5, 6, 7, 8, 9
- Stage 4 re-run invalidates: 5, 6, 7, 8, 9
- Stage 5 re-run invalidates: 6, 7, 8, 9
- Stage 6 re-run invalidates: 7, 8, 9
- Stage 7 re-run invalidates: 8, 9
- Stage 8 re-run invalidates: 9
- Stage 9 re-run invalidates: nothing

---

## Important Rules

1. **Files are the source of truth.** At each stage boundary, read inputs from `.sdf/` files, not from conversation memory.
2. **Wait for user input.** Never skip a stage or auto-advance past a point that requires user approval.
3. **Use AskUserQuestion for all questions and confirmations.** Never print questions as plain text with (A), (B), (C) labels. Always use the `AskUserQuestion` tool. It supports up to 4 questions per call (batch larger rounds into sequential calls) and 2-4 options per question (an "Other" freeform option is added automatically).
4. **Closing question in every round.** The "Do you need more questions?" question must be in the last batch of every Q&A round, every time, no exceptions.
5. **Implementation is optional from this conversation.** If the user chooses "Start now" at the end of Stage 9, proceed to Stage 10 directly. Otherwise, Stage 10 can run later via `/sdf:start` in a fresh context.
