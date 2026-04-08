# SDF Done -- Archive a Completed Flow or Quest

## Arguments
Flow or quest name: $ARGUMENTS

## Instructions

1. If no name provided, check `.sdf/flows/` for active flows and quests (all subdirectories excluding `_archived`). If one exists, confirm with the user. If multiple, ask which one.

2. Verify the entry exists at `.sdf/flows/<name>/`.
   - If it does not exist, tell the user: "Flow/quest '<name>' not found." List active flows and quests if any exist.

3. Read `.sdf/flows/<name>/STATE.md` and show current status. Determine if this is a quest (name contains `--` or `type: quest` in STATE.md) or a flow.

4. Confirm with the user, using the correct term (flow or quest):
   > Archive <flow/quest> "<name>"? This moves it to `.sdf/flows/_archived/<name>/`.
   > The files are kept for reference but the <flow/quest> is removed from active listings.
   > (A) Yes, archive it
   > (B) Cancel

5. If confirmed:
   - Create `.sdf/flows/_archived/` if it does not exist.
   - Move `.sdf/flows/<name>/` to `.sdf/flows/_archived/<name>/`.
   - Tell the user: "<Flow/Quest> '<name>' archived."
