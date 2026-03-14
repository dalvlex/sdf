# SDF Done -- Archive a Completed Flow

## Arguments
Flow name: $ARGUMENTS

## Instructions

1. If no flow name provided, check `.sdf/flows/` for active flows. If one exists, confirm with the user. If multiple, ask which one.

2. Verify the flow exists at `.sdf/flows/<flow-name>/`.
   - If it does not exist, tell the user: "Flow '<flow-name>' not found." List active flows if any exist.

3. Read `.sdf/flows/<flow-name>/STATE.md` and show current status to the user.

4. Confirm with the user:
   > Archive flow "<flow-name>"? This moves it to `.sdf/flows/_archived/<flow-name>/`.
   > The files are kept for reference but the flow is removed from active listings.
   > (A) Yes, archive it
   > (B) Cancel

5. If confirmed:
   - Create `.sdf/flows/_archived/` if it does not exist.
   - Move `.sdf/flows/<flow-name>/` to `.sdf/flows/_archived/<flow-name>/`.
   - Tell the user: "Flow '<flow-name>' archived."
