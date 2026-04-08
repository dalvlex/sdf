# SDF Status

Show the current state of SDF flows and quests.

## Arguments
Flow or quest name (optional): $ARGUMENTS

## Instructions

**If no name provided:**

1. Check if `.sdf/flows/` exists. If not, tell the user: "No SDF flows found. Run `/sdf` to start one."
2. List all subdirectories in `.sdf/flows/` (excluding `_archived`).
3. Separate entries into **flows** (directory name does NOT contain `--`) and **quests** (directory name contains `--`). For quests, parse the parent from the prefix before `--` and the quest name from after `--`.
4. For each entry, read its `STATE.md` and extract: `current_stage`, `stage_name`, `type`, `all_phases_passing` (if present).
5. Display a grouped summary. Flows are shown first, with their child quests indented below. Standalone quests are grouped under "standalone". Use this format:

```
SDF Status:

  <flow-name>                            flow    Stage N -- <stage description>
    +-- <quest-name>                     quest   Stage N -- <stage description>
    +-- <quest-name>                     quest   Stage N -- <stage description>

  <flow-name>                            flow    Stage N -- <stage description>

  standalone
    +-- <quest-name>                     quest   Stage N -- <stage description>
```

If a flow has `all_phases_passing: true`, show `[all passing]` after the stage description.
If a quest has `all_phases_passing: true`, show `[all passing]` after the stage description.

If there are archived flows/quests in `.sdf/flows/_archived/`, note:
```
Archived: <name-1>, <name-2>
```

**If a name was provided:**

1. Read `.sdf/flows/<name>/STATE.md`.
2. Display detailed status. If the entry is a quest (name contains `--`), show the parent flow:

```
SDF Status: <name>
Type: <flow or quest>
Parent: <parent-flow or standalone>     (only for quests)
Stage: N -- <stage name>
```

3. If the flow/quest is at Stage 10 (flows) or Stage 4+ (quests) or has phase status files, read `.sdf/flows/<name>/phases/` and display per-phase status:

```
Phase 1: <name>    [implemented] [tested] [passing]
Phase 2: <name>    [implemented] [tested] [FAILING: M/N]
Phase 3: <name>    [in progress]
Phase 4: <name>    [pending]
```

4. If any stages are marked stale in STATE.md, include a warning:

```
WARNING: Stages N-M are stale (built against an older version of a previous stage's output)
```

5. If any phases are blocked, note them:

```
BLOCKED: Phase 3 -- see .sdf/flows/<name>/phases/phase_3_blocked.md
```

**Do not modify any files.** This command is read-only.
