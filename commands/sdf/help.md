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
| `/sdf:start <flow-name>` | Start autonomous implementation (Stage 10) |
| `/sdf:verify <flow-name>` | Run all tests, write missing ones, fix failures |
| `/sdf:simplify <flow-name>` | Simplify code from the flow -- DRY, reduce complexity |
| `/sdf:status` | Show all flows and their current stage |
| `/sdf:status <flow-name>` | Show detailed status for a specific flow |
| `/sdf:questions <flow-name>` | Jump to Stage 3 -- gap-filling questions on the ask |
| `/sdf:plan <flow-name>` | Jump to Stage 5 -- regenerate the plan |
| `/sdf:plan-questions <flow-name>` | Jump to Stage 6 -- gap-filling questions on the plan |
| `/sdf:testing <flow-name>` | Jump to Stage 7 -- testing strategy questions |
| `/sdf:tests <flow-name>` | Jump to Stages 8-9 -- test design and review |
| `/sdf:done <flow-name>` | Archive a completed flow |
| `/sdf:delete <flow-name>` | Permanently delete a flow |
| `/sdf:help` | Show this help |

### Stages

1. **State the Ask** -- describe what you want
2. **Echo Back** -- Claude restates your ask for confirmation
3. **Gap-Filling Questions (Ask)** -- targeted Q&A to fill ambiguities
4. **Refined Ask** -- completed ask after Q&A, for approval
5. **Plan Generation** -- phased implementation plan
6. **Gap-Filling Questions (Plan)** -- Q&A on the plan, then plan update
7. **Testing Strategy** -- Q&A on testing approach
8. **Test-First Design** -- tests written per phase
9. **Test Review** -- approve test suites per phase
10. **Autonomous Implementation** -- Claude implements and tests (via `/sdf:start`)

### Key concepts

- **Named flows**: each feature/task is a separate flow with its own state
- **Stage invalidation**: re-running an earlier stage marks later stages as stale
- **Soft approvals**: test approvals can be revoked and re-done in Stage 9
- **3-attempt escalation**: implementation stops and asks you after 3 failed fix attempts
- **Files as source of truth**: all state lives in `.sdf/` -- conversations can crash safely

---
