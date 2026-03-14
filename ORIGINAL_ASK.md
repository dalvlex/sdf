# SDF -- Supervised Decision Flow

A structured, multi-stage development workflow for Claude Code that enforces disciplined decision-making before any code is written. It is an interactive pipeline that supports multiple concurrent flows (features) per project.

## State Directory

All SDF internal files are written to a `.sdf/` folder in the project root. This keeps SDF's working files isolated from the user's existing project files. The `.sdf/` folder is created automatically when the first flow starts. Whether to add `.sdf/` to `.gitignore` is left to the user.

## Named Flows

Each SDF run is a **flow**, identified by its plan name (established in Stage 3). Flows are independent -- you can plan multiple features in parallel, pause one to work on another, and implement them one at a time.

- The plan name from Stage 3 doubles as the **flow identifier**.
- Each flow gets its own subdirectory under `.sdf/flows/`.
- Project-level files (like the codebase scan) are shared across all flows.
- There is no limit on how many flows can exist in planning stages (1-9) simultaneously.
- **Implementation guard**: only one flow should run Stage 10 at a time. When `/sdf:start <flow>` is invoked and another flow is mid-implementation, SDF warns the user and asks if they want to proceed. Concurrent implementation risks file conflicts if both flows touch the same code.

## File Manifest

```
.sdf/
  CODEBASE_SCAN.md                          -- existing codebase analysis (shared, only if brownfield)
  flows/
    <flow-name>/
      STATE.md                              -- current stage, checkpoint data, phase approvals, stage validity
      REFINED_ASK.md                        -- the completed ask after all Q&A (Stage 4 output)
      DECISIONS_ASK.md                      -- accumulated Q&A decisions from Stage 3
      DECISIONS_PLAN.md                     -- accumulated Q&A decisions from Stage 6
      TESTING_STRATEGY.md                   -- testing strategy decisions from Stage 7
      PLAN_<flow-name>.md                   -- the implementation plan (Stage 5 output, updated by Stage 6)
      tests/
        phase_N_tests.md                    -- test specs per phase (Stage 8 output)
      phases/
        phase_N_status.md                   -- implementation status per phase (Stage 10)
        phase_N_blocked.md                  -- diagnosis if escalated (Stage 10)
```

Each stage reads its inputs from flow files and writes its outputs back. This is what makes resumability, fresh-context subcommands, and multi-flow support possible.

## Context Management: Files as Source of Truth

All stages run in one conversation for UX continuity -- the user can reference earlier discussion naturally. But Claude does not rely on conversation memory for its actual work. At each stage boundary, the output is written to the flow's `.sdf/flows/<flow-name>/` files. When the next stage begins, Claude **reads its inputs from those files**, not from conversational recall.

The conversation is the UX layer. The `.sdf/` files are the data layer.

This means: if context degrades late in a long session, it does not matter -- Claude is reading from disk. And if the user needs a fully fresh window, they run any `/sdf:<subcommand>` in a new conversation and it picks up from the flow's files with zero loss.

## Resumability

The interactive flow checkpoints after each meaningful step (each completed question round, each stage transition, each user approval) into `.sdf/flows/<flow-name>/STATE.md`. If the conversation dies mid-flow (crash, rate limit, closed terminal), re-running `/sdf <flow-name>` picks up where it left off by reading state from disk. No progress is lost.

Note: Stages 1-2 occur before the flow name is established (the name is set during Stage 3). If the conversation dies during these two messages, the user simply re-states the ask. Checkpointing begins once the flow directory is created after Stage 3 round 1.

## Stage Invalidation

When an earlier stage is re-run via subcommand, all later stages are marked as **stale** in `STATE.md`. For example, re-running Stage 5 (plan generation) invalidates Stages 6-9.

When the user tries to advance past a stale stage or start implementation, SDF warns:

> Stages 7-9 were built against an older version of the plan. Re-run them before proceeding?
> (A) Yes, re-run from Stage 7
> (B) Skip warning and proceed anyway

This is a warning, not a hard block. The user decides. The invalidation chain:

- Re-running **Stage 3** (ask questions) invalidates: 4, 5, 6, 7, 8, 9. Stage 4 (refined ask) is tightly coupled to Stage 3 -- re-running Stage 3 via `/sdf:questions` flows into Stage 4 naturally. There is no separate subcommand for Stage 4 alone.
- Re-running **Stage 5** (plan generation) invalidates: 6, 7, 8, 9
- Re-running **Stage 6** (plan questions) invalidates: 7, 8, 9
- Re-running **Stage 7** (testing strategy) invalidates: 8, 9
- Re-running **Stage 8** (test design) invalidates: 9
- Re-running **Stage 9** (test review) invalidates: nothing (it is the last gate before implementation)

## Architecture: Hybrid Orchestrator

### Commands

- `/sdf` -- starts a new flow (enters Stage 1) OR, if flows already exist, asks: "(A) Start a new flow / (B) Resume an existing flow" and lists existing flows with their current stage
- `/sdf <flow-name>` -- resumes an existing flow from where it left off
- `/sdf:start <flow-name>` -- kicks off Stage 10 (autonomous implementation) for the named flow, with a fresh context reading only what it needs from that flow's `.sdf/` files. If another flow is mid-implementation, warns and asks to confirm. If any stages are stale, warns before proceeding
- `/sdf:<subcommand> <flow-name>` -- jump to a specific stage for the named flow (e.g. `/sdf:questions admin-interface`, `/sdf:plan product-listing`, `/sdf:tests admin-interface`). Triggers stage invalidation for all later stages
- `/sdf:status` -- show all flows and their current state
- `/sdf:status <flow-name>` -- show detailed status for a specific flow (includes stale stage warnings)
- `/sdf:done <flow-name>` -- marks a completed flow as done and archives it (moves to `.sdf/flows/_archived/<flow-name>/`). Keeps the files for reference but removes the flow from active listings
- `/sdf:delete <flow-name>` -- permanently removes a flow and all its files. Asks for confirmation before deleting
- `/sdf:help` -- list all available commands

If only one flow exists and no flow name is provided, SDF assumes that flow. If multiple flows exist and no name is provided, SDF asks which one.

### Execution boundary

Interactive stages (1-9) share context and benefit from conversation history. The autonomous stage (10) starts fresh to avoid context rot. Within Stage 10, each phase implementation gets its own fresh context -- the phase executor reads its slice of the plan and test spec from the flow's `.sdf/` files, implements, tests, and writes back status.

### `/sdf:status` output

Without a flow name, shows all flows:

```
SDF Flows:
  admin-interface    Stage 10 -- Phase 2/4 in progress
  product-listing    Stage 6 -- Plan questions (round 2)
```

With a flow name, shows detailed phase status:

```
SDF Status: admin-interface
Stage: 10 -- Autonomous Implementation
Phase 1: auth-system         [implemented] [tested] [passing]
Phase 2: api-endpoints       [implemented] [tested] [FAILING: 2/5]
Phase 3: frontend-forms      [in progress]
Phase 4: notifications       [pending]
```

If any stages are stale, the status includes a warning:

```
SDF Status: product-listing
Stage: 6 -- Plan questions (round 2)
WARNING: Stages 7-9 are stale (plan was re-generated since they were last run)
```

Reads from `.sdf/flows/<flow-name>/STATE.md` and `.sdf/flows/<flow-name>/phases/`. Works mid-implementation or at any point in the flow.

## Brownfield Detection

When the first `/sdf` flow starts in a project, Claude checks if the project directory contains an existing codebase. If it does, Claude performs a lightweight scan and writes the results to `.sdf/CODEBASE_SCAN.md` (shared across all flows). The scan captures:

- Tech stack and frameworks detected
- Project structure and key directories
- Existing conventions (naming, patterns, architecture)
- Relevant configuration (build tools, test runners, linters)

This scan informs all subsequent flows: the echo back reflects existing constraints, questions target integration points rather than greenfield decisions, the plan respects existing architecture, and the testing strategy aligns with existing test infrastructure.

If the project directory is empty or has no meaningful code, the scan is skipped and SDF proceeds as greenfield. The scan can be re-run if the codebase changes significantly between flows.

## Stage 1: State the Ask

The user describes what they want in natural language -- messy, long, whatever.

## Stage 2: Echo Back

Claude restates the ask back to the user -- clear, succinct, structured. If a codebase scan exists (`.sdf/CODEBASE_SCAN.md`), the echo back reflects how the ask fits within the existing project. If other flows exist, Claude notes any potential overlap or interaction with them. The user confirms or corrects.

## Stage 3: Gap-Filling Questions (on the Ask)

Claude identifies important ambiguities and asks targeted questions. Each question has:

- A few **preset answer options** (A, B, C...)
- A **freeform option** to provide a custom answer

One of these questions is the **flow name question**: Claude suggests a name that will serve as both the plan filename (`PLAN_<name>.md`) and the flow identifier. The user confirms or provides their own. The name should be short, descriptive, and use hyphens (e.g. `admin-interface`, `product-listing`, `auth-overhaul`). Once established, the flow directory `.sdf/flows/<flow-name>/` is created and checkpointing begins.

**Every round includes a built-in closing question as the last question:**

> Do you need more questions? (A) Yes, ask more / (B) No, stop after this round

If **(A)**: another round of questions follows. If **(B)**: the current round's answers are still interpreted and applied, but no further rounds occur. This closing question is present in every round -- there is no separate "should we continue?" step between rounds.

All accumulated decisions are written to `.sdf/flows/<flow-name>/DECISIONS_ASK.md` after each round.

## Stage 4: Refined Ask

Claude presents the completed ask -- enriched by all the Q&A. The user reviews it, can manually edit or ask Claude to edit, and gives final approval. The approved ask is written to `.sdf/flows/<flow-name>/REFINED_ASK.md`.

## Stage 5: Plan Generation

Claude reads from `.sdf/flows/<flow-name>/REFINED_ASK.md` (and `.sdf/CODEBASE_SCAN.md` if it exists) and writes a full implementation plan into `.sdf/flows/<flow-name>/PLAN_<flow-name>.md`.

Each phase in the plan follows this loose structure:

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

The structure is a guideline, not rigid. Phases can include additional sections if needed (e.g. migration steps, external service setup). The key requirement: each phase must have enough detail for Claude to implement it independently and enough acceptance criteria for tests to be written against it.

## Stage 6: Gap-Filling Questions (on the Plan)

Same question mechanism as Stage 3 -- preset answers + freeform option per question. Same built-in closing question in every round: "Do you need more questions? Yes / No, stop after this round." Rounds continue until the user stops them or Claude has no more gaps to fill.

All accumulated decisions are written to `.sdf/flows/<flow-name>/DECISIONS_PLAN.md` after each round.

**After all rounds complete, Claude updates the plan.** Claude applies the decisions from the Q&A to `.sdf/flows/<flow-name>/PLAN_<flow-name>.md` and presents the updated plan to the user for approval. This mirrors the Stage 3 to Stage 4 pattern: questions refine understanding, then the artifact is updated. The user reviews the updated plan, can request further edits, and gives final approval before proceeding.

## Stage 7: Testing Strategy Questions

A dedicated round-based Q&A focused exclusively on testing. Uses the same mechanism as Stages 3 and 6 -- preset answers + freeform option per question, with the "Do you need more questions?" closing question in every round.

The first round establishes the high-level testing approach:

> What testing approach fits this implementation?
> (A) Unit tests (isolated function/component tests)
> (B) Integration tests (tests that hit real services/databases)
> (C) End-to-end tests (full user flow tests, e.g. Playwright/Cypress)
> (D) Acceptance criteria checks (structured pass/fail assertions against requirements)
> (E) Mix -- specify which types for which phases
> (F) Freeform -- describe your testing preference

Subsequent rounds (if the user asks for more) dig deeper: specific frameworks and tooling, coverage expectations, what to mock vs hit real, edge cases to cover, performance thresholds, phases that need heavier vs lighter testing, etc.

The user shapes the testing strategy as much or as little as they want. When they stop the rounds, Claude has a clear testing mandate for Stage 8. All decisions are written to `.sdf/flows/<flow-name>/TESTING_STRATEGY.md`.

## Stage 8: Test-First Phase Design

For each phase of the plan, Claude reads from `.sdf/flows/<flow-name>/PLAN_<flow-name>.md` and `.sdf/flows/<flow-name>/TESTING_STRATEGY.md`, then writes tests that define completion criteria. Test specs are written to `.sdf/flows/<flow-name>/tests/phase_N_tests.md`. A phase is only "done" when its tests pass.

## Stage 9: Test Review and Calibration

Claude presents the tests **per phase** to the user. For each phase, the user sees the test suite and answers a structured review:

> **Phase N: `<phase name>`**
> Tests: `<list of tests with brief descriptions>`
>
> (A) Tests look good -- approve
> (B) Need more tests -- specify what is missing
> (C) Too many tests / over-tested -- specify what to remove
> (D) Change specific test(s) -- specify which and how
> (E) Freeform feedback

The user can address multiple phases at once or go phase-by-phase. After Claude applies the feedback, the amended tests are shown again for that phase.

**Approvals are soft.** The user can revoke any phase's approval at any time during Stage 9 by saying so (e.g. "go back to Phase 2"). Claude shows the amended tests, the user re-approves. Stage 9 only completes when all phases are approved simultaneously. This allows the user to revise earlier decisions as they review later phases without needing to re-run the entire stage.

This is the gate that ensures the "definition of done" is correct before autonomous implementation begins -- bad tests mean bad implementation, so this stage is non-negotiable.

After Stage 9 completes, the orchestrator asks:

> Ready to start implementation, or do you want to make changes first?
> (A) Start implementation now (`/sdf:start <flow-name>`)
> (B) Make changes first -- use subcommands to revise, then start manually

## Stage 10: Autonomous Implementation

Claude implements the plan phase by phase, running tests after each phase. Control returns to the user **only when**:

- Every phase is implemented
- Every phase is tested
- All tests pass
- Each phase is explicitly marked: implemented, tested, passing

Phase status is tracked in `.sdf/flows/<flow-name>/phases/phase_N_status.md` and reflected in `/sdf:status <flow-name>`.

### Concurrent implementation guard

When `/sdf:start <flow-name>` is invoked, SDF checks if any other flow is currently mid-implementation (has a Stage 10 in progress). If so, SDF warns:

> Flow "admin-interface" is currently mid-implementation (Phase 2/4).
> Running two implementations concurrently risks file conflicts if both flows touch the same code.
> (A) Proceed anyway
> (B) Cancel -- finish the other flow first

This is a warning, not a hard block. The user decides.

## Bug-Fixing Discipline (enforced throughout Stage 10)

- **Fix the bug, do not fix the test** -- prefer fixing code over tailoring tests to pass around bugs.
- **Anti-tail-chasing rule** -- if you have tried fixing a bug a few times and you are just piling complexity, stop. Reassess whether the root cause is actually the root cause. Step back, look wider, do not spiral.

## Escalation Path (when Stage 10 gets stuck)

When Claude encounters a failing test it cannot fix, it gets **3 attempts** to resolve the issue. Each attempt should try a meaningfully different approach, not just tweak the same fix. After 3 failed attempts:

1. Claude **pauses implementation** for the blocked phase.
2. Claude **writes a diagnosis** to `.sdf/flows/<flow-name>/phases/phase_N_blocked.md` containing: what was attempted across all 3 tries, what the suspected root cause is, and why the fixes are not working.
3. Claude **returns control to the user** with a summary of the blockage.
4. The user decides: fix it manually, give Claude new guidance and retry, or skip the phase.

This ensures the autonomous loop never spirals indefinitely -- there is always a defined exit to human judgment after a bounded number of attempts.
