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
  - Tech stack and frameworks detected
  - Project structure and key directories
  - Existing conventions (naming, patterns, architecture)
  - Relevant configuration (build tools, test runners, linters)
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

Then ask:
> Does this capture your intent? Confirm, correct, or add anything.

Wait for the user's response. If they correct or add, incorporate changes and echo back again. Repeat until the user confirms.

---

## Stage 3: Gap-Filling Questions (on the Ask)

Identify important ambiguities in the ask and prepare targeted questions. Run in **rounds**.

### Each round:

Present questions, each with:
- **Preset answer options** labeled (A), (B), (C), etc.
- A **freeform option** as the last choice for each question (e.g., "(D) Other -- describe")

**Mandatory questions in the first round:**
1. **Flow name**: Suggest a short, hyphenated name for this flow (e.g., `admin-interface`, `auth-overhaul`). This becomes both the plan filename and the flow identifier.
   > Suggested flow name: `<your-suggestion>`
   > (A) Accept
   > (B) Use a different name -- type it

**The last question in EVERY round must be:**
> Do you need more questions?
> (A) Yes, ask more
> (B) No, stop after this round

Wait for the user's answers.

### After each round:

1. Interpret and apply all answers from this round.
2. **After the first round** (once the flow name is established): create the directory `.sdf/flows/<flow-name>/` and all subdirectories (`tests/`, `phases/`).
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

Then ask:
> Is this refined ask accurate and complete?
> (A) Yes, approve it
> (B) I want to edit it -- tell me what to change
> (C) Let me provide edits directly

Wait for the user's response.
- If **(A)**: write the refined ask to `.sdf/flows/<flow-name>/REFINED_ASK.md`. Update STATE.md to `current_stage: 4, valid_stages: [1,2,3,4]`. Proceed to Stage 5.
- If **(B)** or **(C)**: incorporate edits, present again, repeat until approved.

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

Present the plan to the user. Then ask:
> Review the plan. We will refine it with questions in the next stage.

Update STATE.md to `current_stage: 5, valid_stages: [1,2,3,4,5]`. Proceed to Stage 6.

---

## Stage 6: Gap-Filling Questions (on the Plan)

Read `.sdf/flows/<flow-name>/PLAN_<flow-name>.md`.

Same question mechanism as Stage 3 -- preset answers + freeform option per question. Same built-in closing question in every round:

> Do you need more questions?
> (A) Yes, ask more
> (B) No, stop after this round

After each round:
1. Write accumulated decisions to `.sdf/flows/<flow-name>/DECISIONS_PLAN.md`.
2. Update STATE.md checkpoint.

When rounds are complete (user says stop or no more gaps):
1. **Update the plan**: apply all decisions to `.sdf/flows/<flow-name>/PLAN_<flow-name>.md`.
2. Present the **updated plan** to the user for approval:
   > Here is the updated plan with all decisions applied. Review and approve.
   > (A) Plan looks good -- approve
   > (B) I want changes -- specify
3. Repeat until approved.
4. Update STATE.md to `current_stage: 6, valid_stages: [1,2,3,4,5,6]`. Proceed to Stage 7.

---

## Stage 7: Testing Strategy Questions

A dedicated round-based Q&A focused exclusively on testing. Same mechanism as Stages 3 and 6.

**First round must include this question:**

> What testing approach fits this implementation?
> (A) Unit tests (isolated function/component tests)
> (B) Integration tests (tests that hit real services/databases)
> (C) End-to-end tests (full user flow tests, e.g. Playwright/Cypress)
> (D) Acceptance criteria checks (structured pass/fail assertions against requirements)
> (E) Mix -- specify which types for which phases
> (F) Freeform -- describe your testing preference

Subsequent rounds (if requested) dig deeper: specific frameworks and tooling, coverage expectations, what to mock vs hit real, edge cases to cover, performance thresholds, phases needing heavier vs lighter testing.

Same closing question every round:
> Do you need more questions?
> (A) Yes, ask more
> (B) No, stop after this round

After rounds complete: write all decisions to `.sdf/flows/<flow-name>/TESTING_STRATEGY.md`.
Update STATE.md to `current_stage: 7, valid_stages: [1,2,3,4,5,6,7]`. Proceed to Stage 8.

---

## Stage 8: Test-First Phase Design

Read `.sdf/flows/<flow-name>/PLAN_<flow-name>.md` and `.sdf/flows/<flow-name>/TESTING_STRATEGY.md`.

For each phase in the plan, write tests that define completion criteria. Use the testing strategy established in Stage 7.

Write test specs to `.sdf/flows/<flow-name>/tests/phase_N_tests.md` (one file per phase).

Update STATE.md to `current_stage: 8, valid_stages: [1,2,3,4,5,6,7,8]`. Proceed to Stage 9.

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

**Approvals are soft.** The user can revoke any phase's approval at any time by saying so (e.g., "go back to Phase 2"). When revoked, show the tests for that phase again after applying changes. Re-approval is required.

**Stage 9 completes only when ALL phases are approved simultaneously.**

After all phases are approved:
1. Update STATE.md to `current_stage: 9, valid_stages: [1,2,3,4,5,6,7,8,9]`.
2. Ask the user:
   > All test suites approved. Ready to start implementation?
   > (A) Start implementation now -- run `/sdf:start <flow-name>`
   > (B) Make changes first -- use subcommands to revise, then start manually with `/sdf:start <flow-name>`

If **(A)**: tell the user to run `/sdf:start <flow-name>` in a new conversation for fresh context. Do NOT attempt to run Stage 10 from this conversation -- it must start with a clean context window.
If **(B)**: the flow is saved and ready. The user can use subcommands to revise and start when ready.

---

## Checkpointing Rules

After EVERY meaningful interaction (each question round, each approval, each stage transition), update `.sdf/flows/<flow-name>/STATE.md` with:

- `current_stage`: the stage number
- `stage_name`: human-readable stage name
- `round`: question round number (if in a Q&A stage)
- `valid_stages`: list of stages that are current (not stale)
- `phase_approvals`: map of phase approvals (for Stage 9)

This ensures that if the conversation is interrupted, `/sdf <flow-name>` can resume from the exact checkpoint.

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
3. **Preset + freeform.** Every question must have preset options AND a freeform option.
4. **Closing question in every round.** The "Do you need more questions?" question must be the last question in every Q&A round, every time, no exceptions.
5. **No implementation.** This orchestrator handles Stages 1-9 only. Stage 10 runs via `/sdf:start` in a fresh context.
