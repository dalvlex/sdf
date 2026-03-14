# SDF Status

Show the current state of SDF flows.

## Arguments
Flow name (optional): $ARGUMENTS

## Instructions

**If no flow name provided:**

1. Check if `.sdf/flows/` exists. If not, tell the user: "No SDF flows found. Run `/sdf` to start one."
2. List all subdirectories in `.sdf/flows/` (excluding `_archived`).
3. For each flow, read its `STATE.md` and display a summary:

```
SDF Flows:
  <flow-name>    Stage N -- <stage description>
  <flow-name>    Stage N -- <stage description>
```

If there are archived flows in `.sdf/flows/_archived/`, note:
```
Archived: <flow-1>, <flow-2>
```

**If a flow name was provided:**

1. Read `.sdf/flows/<flow-name>/STATE.md`.
2. Display detailed status:

```
SDF Status: <flow-name>
Stage: N -- <stage name>
```

3. If the flow is at Stage 10 or has phase status files, read `.sdf/flows/<flow-name>/phases/` and display per-phase status:

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
BLOCKED: Phase 3 -- see .sdf/flows/<flow-name>/phases/phase_3_blocked.md
```

**Do not modify any files.** This command is read-only.
