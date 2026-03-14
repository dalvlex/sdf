# SDF -- Supervised Decision Flow

A structured, multi-stage development workflow for [Claude Code](https://claude.com/claude-code). Enforces disciplined decision-making before any code is written.

SDF walks you through **10 stages**: stating your ask, refining it with targeted Q&A, generating a phased plan, defining a testing strategy, designing tests per phase, reviewing and approving those tests, and then autonomous implementation with built-in escalation when things go wrong.

## Install

```bash
git clone <this-repo>
cd sdf
./install.sh
```

This copies the skill files to `~/.claude/commands/`, making them available in every project.

## Uninstall

```bash
./uninstall.sh
```

Removes the skill files. Your `.sdf/` project folders are untouched.

## Quick Start

In any project directory, run:

```
/sdf
```

SDF will walk you through all 10 stages interactively. At the end, it prompts you to start implementation with `/sdf:start`.

## The 10 Stages

### Stages 1-2: Ask and Echo Back

You describe what you want in natural language. Claude restates it back to you -- clear, succinct, structured. If the project has existing code, the echo back reflects how the ask fits within the existing project. You confirm or correct until it captures your intent.

### Stage 3: Gap-Filling Questions (on the Ask)

Claude asks targeted questions to fill ambiguities. Each question has **preset answer options** (A, B, C...) and a **freeform option**. This runs in rounds -- the last question in every round is "Do you need more questions?" so you control depth.

The first round includes the **flow name question** -- a short hyphenated name (e.g., `admin-interface`) that identifies this feature throughout the process.

### Stage 4: Refined Ask

Claude presents the completed ask enriched by all Q&A. You review, edit if needed, and approve. This is written to disk as the definitive spec for planning.

### Stage 5: Plan Generation

Claude generates a phased implementation plan. Each phase has: Goal, Implementation details, Dependencies, and Acceptance Criteria. The plan is written to `.sdf/flows/<flow-name>/PLAN_<flow-name>.md`.

### Stage 6: Gap-Filling Questions (on the Plan)

Same round-based Q&A mechanism, now focused on the plan. After rounds complete, Claude **updates the plan** with all decisions and presents it for your approval.

### Stage 7: Testing Strategy Questions

Dedicated round-based Q&A on testing. The first round asks: unit tests, integration tests, e2e tests, acceptance checks, or a mix? Subsequent rounds go deeper: frameworks, mocking strategy, coverage expectations, edge cases. You shape it as much or as little as you want.

### Stage 8: Test-First Phase Design

Claude writes test specs for each phase based on the plan and testing strategy. Tests define completion criteria -- a phase is only "done" when its tests pass.

### Stage 9: Test Review and Calibration

You review tests per phase. For each phase, you can: approve, add tests, remove tests, change tests, or give freeform feedback. **Approvals are soft** -- you can revoke and re-approve any phase at any time. The stage only completes when all phases are approved simultaneously.

### Stage 10: Autonomous Implementation

Triggered via `/sdf:start`. Runs in a **fresh context** to avoid context rot. Each phase gets its own fresh subagent context. Claude implements phase by phase, runs tests after each. If a bug can't be fixed in **3 attempts**, Claude pauses and returns control to you with a full diagnosis.

## Commands

| Command | Description |
|---------|-------------|
| `/sdf` | Start a new flow or resume an existing one |
| `/sdf <flow-name>` | Resume a specific flow from where it left off |
| `/sdf:start <flow-name>` | Start autonomous implementation (Stage 10) |
| `/sdf:status` | Show all flows and their current stage |
| `/sdf:status <flow-name>` | Show detailed phase-level status for a flow |
| `/sdf:questions <flow-name>` | Jump to Stage 3 -- re-run ask questions |
| `/sdf:plan <flow-name>` | Jump to Stage 5 -- regenerate the plan |
| `/sdf:plan-questions <flow-name>` | Jump to Stage 6 -- re-run plan questions |
| `/sdf:testing <flow-name>` | Jump to Stage 7 -- re-run testing strategy |
| `/sdf:tests <flow-name>` | Jump to Stages 8-9 -- redesign and review tests |
| `/sdf:done <flow-name>` | Archive a completed flow |
| `/sdf:delete <flow-name>` | Permanently delete a flow and all its files |
| `/sdf:help` | Show all commands in Claude Code |

If only one flow exists and no name is provided, SDF assumes that flow. If multiple exist, it asks which one.

## Command Files Reference

All skills live in `commands/` and are installed to `~/.claude/commands/`.

### `commands/sdf.md` -- Main Orchestrator

The core of SDF. When you run `/sdf`, this prompt is loaded. It handles:

- **Flow detection**: checks for existing `.sdf/flows/`, offers to resume or start new
- **Brownfield detection**: scans existing codebases on first run, writes `.sdf/CODEBASE_SCAN.md`
- **Stages 1-9**: walks through the entire interactive pipeline sequentially
- **Question mechanism**: enforces preset + freeform options on every question, closing question in every round
- **Checkpointing**: updates `STATE.md` after every meaningful interaction for crash-safe resumability
- **Stage invalidation**: tracks which stages are stale and warns before proceeding past them
- **File I/O**: reads from and writes to `.sdf/flows/<flow-name>/` at every stage boundary

This is the largest skill file (~300 lines). It is the single source of behavioral truth for the interactive flow.

### `commands/sdf/start.md` -- Stage 10 Launcher

Runs autonomous implementation in a **fresh context** (no conversation history from planning). Handles:

- **Readiness validation**: verifies all planning stages are complete, warns about stale stages
- **Concurrent implementation guard**: warns if another flow is mid-implementation
- **Phase execution loop**: implements each phase using a subagent with fresh context
- **Test running**: runs phase tests after each implementation
- **3-attempt escalation**: each attempt tries a meaningfully different approach; after 3 failures, writes a diagnosis to `phase_N_blocked.md` and returns control to the user
- **Bug-fixing discipline**: fix the code not the test; anti-tail-chasing rule
- **Status tracking**: updates `phase_N_status.md` in real-time so `/sdf:status` stays current

### `commands/sdf/status.md` -- Status Viewer

Read-only command. Two modes:

- **No arguments**: lists all active flows with their current stage. Notes archived flows.
- **With flow name**: shows detailed per-phase status (implemented/tested/passing/failing/blocked), stale stage warnings, and blocked phase references.

### `commands/sdf/help.md` -- Command Reference

Static help text. Lists all commands, all 10 stages, and key concepts (named flows, stage invalidation, soft approvals, escalation, files as source of truth).

### `commands/sdf/questions.md` -- Stage 3 Jump

Re-runs gap-filling questions on the ask. Triggers **stage invalidation** for Stages 4-9 (since the ask inputs are changing). Loads existing decisions, runs new Q&A rounds, updates `DECISIONS_ASK.md`.

### `commands/sdf/plan.md` -- Stage 5 Jump

Regenerates the implementation plan. Reads the refined ask and codebase scan, produces a new plan. Triggers **stage invalidation** for Stages 6-9. Presents the plan and guides the user to next steps.

### `commands/sdf/plan-questions.md` -- Stage 6 Jump

Re-runs gap-filling questions on the plan. After Q&A rounds complete, **updates the plan file** with all decisions and presents for approval. Triggers **stage invalidation** for Stages 7-9.

### `commands/sdf/testing.md` -- Stage 7 Jump

Re-runs testing strategy questions. First round covers the high-level approach (unit/integration/e2e/acceptance/mix). Subsequent rounds go deeper. Writes decisions to `TESTING_STRATEGY.md`. Triggers **stage invalidation** for Stages 8-9.

### `commands/sdf/tests.md` -- Stages 8-9 Jump

Re-runs both test design (Stage 8) and test review (Stage 9). Reads the plan and testing strategy, writes test specs per phase, then presents for review with the soft-approval mechanism. Only completes when all phases are approved simultaneously.

### `commands/sdf/done.md` -- Archive Flow

Moves a completed flow from `.sdf/flows/<name>/` to `.sdf/flows/_archived/<name>/`. Files are kept for reference but removed from active listings. Confirms before acting.

### `commands/sdf/delete.md` -- Delete Flow

Permanently removes a flow and all its files. Works on both active and archived flows. Requires explicit confirmation before deleting.

## Key Features

### Named Flows

Each feature/task is a separate flow with its own state directory. Plan multiple features in parallel, implement one at a time. The flow name (set in Stage 3) becomes the identifier used across all commands.

### Question Rounds with Presets

Every Q&A stage (Stages 3, 6, 7) uses the same mechanism:
- Each question has **preset options** (A, B, C...) plus a **freeform option**
- The last question in every round: "Do you need more questions? (A) Yes / (B) No, stop"
- You control how deep the questioning goes

### Files as Source of Truth

All state lives in `.sdf/` files. The conversation is the UX layer; files are the data layer. Claude reads from files at each stage boundary, not from conversation memory. This means:
- Conversations can crash safely -- resume with `/sdf <flow-name>`
- Subcommands work from any conversation -- they read state from disk
- Context degradation doesn't matter -- Claude reads fresh from files

### Resuming Flows

Start a new conversation and run `/sdf <flow-name>`. SDF reads `STATE.md` and picks up from the exact stage you left off. This works across conversation crashes, context limits, or deliberate restarts.

### Stage Invalidation

Re-running an earlier stage marks all later stages as stale:
- Stage 3 re-run invalidates: 4, 5, 6, 7, 8, 9
- Stage 5 re-run invalidates: 6, 7, 8, 9
- Stage 7 re-run invalidates: 8, 9

SDF warns before proceeding past stale stages. You decide whether to re-run or proceed anyway.

### Soft Test Approvals

In Stage 9, approving a phase's tests is not final. You can revoke any approval at any time during the review (e.g., "go back to Phase 2"). The stage only completes when all phases are approved at the same time.

### 3-Attempt Escalation

During implementation, if Claude can't fix a failing test in 3 attempts (each trying a meaningfully different approach), it:
1. Pauses the phase
2. Writes a full diagnosis to `phase_N_blocked.md` (what was tried, root cause hypotheses, suggested next steps)
3. Returns control to you

### Bug-Fixing Discipline

Two rules enforced during Stage 10:
- **Fix the code, not the test** -- tests represent your approved definition of done
- **Anti-tail-chasing** -- if fixes are just piling complexity, stop and reassess the root cause

### Brownfield Aware

On first run in a project with existing code, SDF scans the codebase and writes `.sdf/CODEBASE_SCAN.md`. This informs all stages: questions target integration points, plans respect existing architecture, testing strategy aligns with existing infrastructure.

### Concurrent Implementation Guard

When starting Stage 10 for a flow, SDF checks if another flow is already mid-implementation. If so, it warns about potential file conflicts. The user decides whether to proceed.

## Project File Structure

```
.sdf/
  CODEBASE_SCAN.md                          -- codebase analysis (shared across flows)
  flows/
    <flow-name>/
      STATE.md                              -- stage, checkpoints, approvals, validity
      REFINED_ASK.md                        -- approved ask (Stage 4)
      DECISIONS_ASK.md                      -- Q&A decisions (Stage 3)
      DECISIONS_PLAN.md                     -- Q&A decisions (Stage 6)
      TESTING_STRATEGY.md                   -- testing decisions (Stage 7)
      PLAN_<flow-name>.md                   -- implementation plan (Stage 5, updated by Stage 6)
      tests/
        phase_N_tests.md                    -- test specs per phase (Stage 8)
      phases/
        phase_N_status.md                   -- implementation status (Stage 10)
        phase_N_blocked.md                  -- escalation diagnosis (Stage 10)
    _archived/
      <flow-name>/                          -- archived flows (via /sdf:done)
```

Whether to add `.sdf/` to `.gitignore` is up to you.

## Architecture

**Interactive stages (1-9)** run in one conversation. The conversation provides UX continuity; `.sdf/` files provide the data. Claude reads from files at each stage boundary, not from conversation memory.

**Autonomous implementation (Stage 10)** runs in a fresh context via `/sdf:start`. Each phase gets its own fresh subagent context to avoid context rot. The subagent reads only its phase's plan slice and test spec from `.sdf/` files.

## Spec

The full specification and design rationale is in [IMPL_ASK.md](IMPL_ASK.md).

## License

MIT
