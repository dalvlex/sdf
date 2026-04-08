# SDF Delete -- Permanently Remove a Flow or Quest

## Arguments
Flow or quest name: $ARGUMENTS

## Instructions

1. If no name provided, check `.sdf/flows/` for active flows and quests (all subdirectories excluding `_archived`). If one exists, confirm with the user. If multiple, ask which one.

2. Verify the entry exists at `.sdf/flows/<name>/` (also check `.sdf/flows/_archived/<name>/` for archived entries).
   - If it does not exist, tell the user: "Flow/quest '<name>' not found." List active and archived flows/quests if any exist.

3. Read the entry's STATE.md and show current status. Determine if this is a quest (name contains `--` or `type: quest` in STATE.md) or a flow.

4. Warn the user clearly, using the correct term (flow or quest):
   > PERMANENTLY DELETE <flow/quest> "<name>" and all its files?
   > This cannot be undone. All plans, decisions, test specs, and phase status will be lost.
   > (A) Yes, permanently delete
   > (B) Cancel

5. If confirmed:
   - Remove the entire directory (`.sdf/flows/<name>/` or `.sdf/flows/_archived/<name>/`).
   - Tell the user: "<Flow/Quest> '<name>' permanently deleted."
