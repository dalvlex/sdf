# SDF Help

Display the following help text to the user exactly as written:

---

## SDF -- Supervised Decision Flow

A structured, multi-stage development workflow that enforces disciplined decision-making before implementation.

### Commands

| Command | Description |
|---------|-------------|
| `/sdf` | Start a new flow or resume an existing one |
| `/sdf <flow-name>` | Resume a specific flow from where it left off |
| `/sdf:quest` | Start a new quest or resume an existing one |
| `/sdf:quest <quest-name>` | Resume a specific quest |
| `/sdf:implement <flow-name>` | Start autonomous implementation (Stage 10) |
| `/sdf:verify <flow-name>` | Run all tests, write missing ones, fix failures |
| `/sdf:simplify <flow-name>` | Simplify code from the flow -- DRY, reduce complexity |
| `/sdf:status` | Show all flows and quests with their current stage |
| `/sdf:status <name>` | Show detailed status for a specific flow or quest |
| `/sdf:questions <flow-name>` | Jump to Stage 3 -- gap-filling questions on the ask |
| `/sdf:plan <flow-name>` | Jump to Stage 5 -- regenerate the plan |
| `/sdf:plan-questions <flow-name>` | Jump to Stage 6 -- gap-filling questions on the plan |
| `/sdf:testing <flow-name>` | Jump to Stage 7 -- testing strategy questions |
| `/sdf:tests <flow-name>` | Jump to Stages 8-9 -- test design and review |
| `/sdf:done <name>` | Archive a completed flow or quest |
| `/sdf:delete <name>` | Permanently delete a flow or quest |
| `/sdf:help` | Show this help |

### Flows (10 stages)

Full flows are for comprehensive, potentially ambiguous features that need thorough planning.

1. **State the Ask** -- describe what you want
2. **Echo Back** -- Claude restates your ask for confirmation
3. **Gap-Filling Questions (Ask)** -- targeted Q&A to fill ambiguities
4. **Refined Ask** -- completed ask after Q&A, for approval
5. **Plan Generation** -- phased implementation plan
6. **Gap-Filling Questions (Plan)** -- Q&A on the plan, then plan update
7. **Testing Strategy** -- Q&A on testing approach
8. **Test-First Design** -- tests written per phase
9. **Test Review** -- approve test suites per phase
10. **Autonomous Implementation** -- Claude implements and tests (via `/sdf:implement`)

### Quests (5 stages)

Quests are a lightweight flow for focused, well-scoped changes. They inherit testing strategy from their parent flow and skip test review.

1. **Ask** -- describe the change
2. **Confirm** -- echo back + multi-round Q&A + refined ask
3. **Plan** -- auto-generated plan, approve or tweak
4. **Implement** -- tests auto-generated, phase-by-phase implementation
5. **Verify + Simplify** -- same pipeline as full flows

Quest directories are named `<parent>--<quest-name>` (e.g., `rehab-tracker--add-week-block`). Standalone quests use the `standalone` prefix.

### Key concepts

- **Named flows**: each feature/task is a separate flow with its own state
- **Quests**: lightweight flows for focused changes, grouped under a parent flow
- **Stage invalidation**: re-running an earlier stage marks later stages as stale
- **Soft approvals**: test approvals can be revoked and re-done in Stage 9
- **3-attempt escalation**: implementation stops and asks you after 3 failed fix attempts
- **Files as source of truth**: all state lives in `.sdf/` -- conversations can crash safely

---
