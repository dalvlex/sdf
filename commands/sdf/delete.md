# SDF Delete -- Permanently Remove a Flow

## Arguments
Flow name: $ARGUMENTS

## Instructions

1. If no flow name provided, check `.sdf/flows/` for active flows. If one exists, confirm with the user. If multiple, ask which one.

2. Verify the flow exists at `.sdf/flows/<flow-name>/` (also check `.sdf/flows/_archived/<flow-name>/` for archived flows).
   - If it does not exist, tell the user: "Flow '<flow-name>' not found." List active and archived flows if any exist.

3. Read the flow's STATE.md and show current status.

4. Warn the user clearly:
   > PERMANENTLY DELETE flow "<flow-name>" and all its files?
   > This cannot be undone. All plans, decisions, test specs, and phase status will be lost.
   > (A) Yes, permanently delete
   > (B) Cancel

5. If confirmed:
   - Remove the entire flow directory (`.sdf/flows/<flow-name>/` or `.sdf/flows/_archived/<flow-name>/`).
   - Tell the user: "Flow '<flow-name>' permanently deleted."
