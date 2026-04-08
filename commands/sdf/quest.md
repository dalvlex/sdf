# SDF Quest -- Lightweight Side Quest Flow

You are running the SDF Quest orchestrator. Quests are a compressed 5-stage flow for focused, well-scoped changes on an existing project. Follow these instructions precisely, stage by stage.

## Initial Setup

**Step 1: Check for arguments.**
The user may have provided a quest name: $ARGUMENTS

- If a quest name was provided (contains `--`), skip to **Resume Quest** below.
- If a plain name was provided (no `--`), treat it as a parent flow hint and continue to Step 2.
- If no arguments, continue to Step 2.

**Step 2: Check for existing quests.**
Check if `.sdf/flows/` exists and contains any quest directories (directories whose name contains `--`, excluding `_archived`).

- If **no quests exist**: proceed to **Parent Flow Detection**.
- If **one quest exists**: ask the user:
  > SDF found an existing quest: `<full-quest-name>` (currently at Stage N).
  > (A) Resume this quest
  > (B) Start a new quest
- If **multiple quests exist**: ask the user:
  > SDF found existing quests:
  > - `<quest-1>` -- Stage N
  > - `<quest-2>` -- Stage N
  > (A) Resume an existing quest -- which one?
  > (B) Start a new quest

Wait for the user's response before proceeding.

---

## Resume Quest

Read `.sdf/flows/<full-quest-name>/STATE.md` to determine the current stage and checkpoint. Resume from where the quest left off.

---

## Parent Flow Detection

Check `.sdf/flows/` for active flows (directories whose name does NOT contain `--`, excluding `_archived`).

- If **no flows exist**: the parent will be `standalone`. Tell the user: "No parent flow found. This will be a standalone quest."
- If **one flow exists**: use it as the parent. Tell the user: "Parent flow: `<flow-name>`."
- If **multiple flows exist**: ask the user which flow this quest belongs to, or if it is standalone:
  > Which flow does this quest belong to?
  > - `<flow-1>`
  > - `<flow-2>`
  > - Standalone (no parent)

Wait for the user's response if asking.

**Inherit context from parent flow (if not standalone):**
- Read `.sdf/flows/<parent>/TESTING_STRATEGY.md` if it exists -- this becomes the default testing approach for the quest.
- Read `.sdf/CODEBASE_SCAN.md` if it exists.
- Read `.sdf/LEARNINGS.md` if it exists.

**If standalone:**
- Read `.sdf/CODEBASE_SCAN.md` if it exists.
- Read `.sdf/LEARNINGS.md` if it exists.

Then proceed to **Brownfield Detection**, then **Stage 1**.

---

## Brownfield Detection

Check if the project directory contains an existing codebase (source files, package.json, Cargo.toml, build configs, etc.). Ignore the `.sdf/` directory itself.

- If **existing codebase found** and `.sdf/CODEBASE_SCAN.md` does NOT exist: perform a lightweight scan and write results to `.sdf/CODEBASE_SCAN.md`. The scan should capture:
  - **Project purpose**: what the application does, its domain, and target users
  - **CLAUDE.md rules**: if any CLAUDE.md files exist, read and summarize key rules
  - **Tech stack and frameworks**: languages, frameworks, major libraries
  - **Project structure**: key directories and their roles
  - **Existing conventions**: naming patterns, architecture style, code organization
  - **Relevant configuration**: build tools, linters, formatters
  - **Testing setup**: test framework(s), test directory structure, existing helpers, how to run tests
  - **Core entities/models**: key domain objects and their relationships
  Then tell the user: "Codebase scan complete."
- If `.sdf/CODEBASE_SCAN.md` already exists: skip the scan.
- If **no codebase found**: skip the scan, proceed as greenfield.

---

## Stage 1: State the Ask

Tell the user:
> **Quest Stage 1: State your ask.**
> Describe the change you want to make. Quests work best for focused, well-scoped tasks.

Wait for the user to describe their ask. Do not proceed until they have provided it.

---

## Stage 2: Confirm

This stage combines echo back, quick questions, and the refined ask into one interaction.

### Echo Back

Restate the user's ask back to them -- clear, succinct, and structured.

- If `.sdf/CODEBASE_SCAN.md` exists, reflect how the ask fits within the existing project.
- If a parent flow exists, note relevant context from the parent (e.g., existing testing strategy, architecture decisions).

### Gap-Filling Questions

Run in **rounds**, same mechanism as full SDF. Use the `AskUserQuestion` tool to present questions interactively. Each question gets 2-4 preset options (an "Other" freeform option is added automatically by the tool). The tool accepts up to 4 questions per call, so if a round has more than 4 questions, present them in sequential batches of up to 4.

**Mandatory questions in the first round:**

1. **Quest name**: Suggest a short, hyphenated name for this quest. The full directory name will be `<parent>--<quest-name>`.
   - Header: "Quest name"
   - Options: "Accept `<your-suggestion>`" / "Different name"

**The last question in EVERY round must be (always in the last batch):**
- Question: "Do you need more questions?"
- Header: "More Qs?"
- Options: "Yes, ask more" / "No, move to planning"

Include additional questions for genuine ambiguities. Do not pad with unnecessary questions.

**Ambiguity check:** If during the first round you identify more than ~5 genuine ambiguities, mention it to the user:
> "This ask has several open questions. You can continue as a quest, or switch to `/sdf` for the full planning flow. Your call."
This is informational only -- the user decides whether to continue or switch.

Wait for the user's answers.

### Each round:

1. Interpret and apply all answers from this round.
2. **After the first round only** (once the quest name is established): check if `.sdf/flows/<full-quest-name>/` already exists (from a previous quest, not this one). If it does, warn the user and ask for a different name. Then create the directory and all subdirectories (`tests/`, `phases/`). Skip this step on subsequent rounds -- the directory was already created in round 1.
3. Write all accumulated decisions to `.sdf/flows/<full-quest-name>/DECISIONS.md`.
4. Update `.sdf/flows/<full-quest-name>/STATE.md` with the current round number.

### Round continuation:
- If the user answered **Yes, ask more**: prepare another round of questions based on remaining ambiguities and gaps. Repeat the round process.
- If the user answered **No, move to planning**: proceed to finalize.
- If you have no more meaningful questions to ask, tell the user: "I have no more gaps to fill. Moving to planning." Then proceed to finalize.

### Finalize

1. Present the completed ask -- enriched by all the Q&A -- to the user. Use `AskUserQuestion` for confirmation:
   - Question: "Does this capture your intent?"
   - Header: "Confirm"
   - Options: "Yes, confirmed" / "Needs correction" / "Add something"
2. If the user corrected or added something, incorporate changes, present again. Repeat until confirmed.
3. Write the confirmed ask to `.sdf/flows/<full-quest-name>/REFINED_ASK.md`.
4. Update `.sdf/flows/<full-quest-name>/STATE.md`:
   ```
   current_stage: 2
   stage_name: Confirm
   type: quest
   parent: <parent-flow-name or standalone>
   valid_stages: [1, 2]
   ```
5. Proceed to Stage 3.

---

## Stage 3: Plan

Read `.sdf/flows/<full-quest-name>/REFINED_ASK.md`. Also read `.sdf/CODEBASE_SCAN.md` and `.sdf/LEARNINGS.md` if they exist.

Generate a phased implementation plan. Each phase must follow this structure:

```markdown
# Phase N: <name>

## Goal
What this phase achieves in one or two sentences.

## Implementation
What to build. Which files to create or modify. Key logic and behavior.

## Dependencies
Which phases must complete before this one, if any. "None" if independent.

## Acceptance Criteria
How to know this phase is done. Maps directly to auto-generated tests.
```

Quests should typically have 1-3 phases. Keep them focused.

Write the plan to `.sdf/flows/<full-quest-name>/PLAN_<full-quest-name>.md`.

Present the plan to the user. Then use `AskUserQuestion`:
- Question: "Plan looks good?"
- Header: "Plan"
- Options: "Approve -- start implementation" / "Needs changes"

If **needs changes**: let the user describe changes, regenerate or update the plan, present again. Repeat until approved.

Update `.sdf/flows/<full-quest-name>/STATE.md`:
```
current_stage: 3
stage_name: Plan
type: quest
parent: <parent-flow-name or standalone>
valid_stages: [1, 2, 3]
```
Proceed to Stage 4.

---

## Stage 4: Implement

This stage combines test generation and implementation. Read:
- `.sdf/flows/<full-quest-name>/PLAN_<full-quest-name>.md`
- `.sdf/flows/<full-quest-name>/REFINED_ASK.md`
- Parent flow's `TESTING_STRATEGY.md` if it exists (for framework/tooling decisions)
- `.sdf/CODEBASE_SCAN.md` if it exists
- `.sdf/LEARNINGS.md` if it exists

### Auto-generate test specs

For each phase, auto-generate test specs from the plan's acceptance criteria and the inherited testing strategy (or project defaults from the codebase scan). Write to `.sdf/flows/<full-quest-name>/tests/phase_N_tests.md`.

Show the user a brief summary of what tests will be written (not the full specs). Do NOT ask for approval -- quests skip test review.

### Check concurrent implementation guard

Check all flow directories in `.sdf/flows/` (excluding `_archived`). If any other flow or quest is mid-implementation -- check for `current_stage: 10` (full flows) or `current_stage: 4` with `type: quest` (quests) in their STATE.md:
> Quest/flow "<other-name>" is currently mid-implementation.
> Running two implementations concurrently risks file conflicts.
> (A) Proceed anyway
> (B) Cancel -- finish the other one first

Wait for response. If (B), stop.

### Update state

Update `.sdf/flows/<full-quest-name>/STATE.md`:
```
current_stage: 4
stage_name: Implement
type: quest
parent: <parent-flow-name or standalone>
valid_stages: [1, 2, 3, 4]
```

**Create tasks for progress tracking.** Use `TaskCreate` to create one task per phase: `Phase N: <phase name>`.

### Implementation loop

For each phase (in dependency order):

#### 1. Start the phase
- Mark the phase's task as `in_progress` using `TaskUpdate`.
- Update `.sdf/flows/<full-quest-name>/phases/phase_N_status.md` with:
  ```
  status: in_progress
  started: <timestamp>
  ```

#### 2. Implement the phase
Use a **subagent with fresh context** for each phase. The subagent receives:
- The phase's plan section (Goal, Implementation, Dependencies, Acceptance Criteria)
- The phase's test spec from `.sdf/flows/<full-quest-name>/tests/phase_N_tests.md`
- The codebase scan (if it exists) for project context
- The testing strategy (inherited from parent or project defaults)
- **CLAUDE.md and README.md** from the project root (if they exist). The subagent must read and follow any conventions they specify.

The subagent implements the code described in the phase, then writes and runs the tests from the test spec. Include these explicit instructions in the subagent prompt:
- "You MUST write the actual test files described in the test spec and run them."
- "A successful build or type-check is NOT a substitute for tests. Tests must be written, executed, and passing."
- "Do not mark the phase as complete until real tests pass."

#### 3. Run tests
After the subagent finishes, verify that actual test files were created and run them. Determine how to run tests from the testing strategy, codebase scan, and project config. If you cannot figure out how to run the tests, ask the user. If the subagent skipped writing tests, write them yourself and run them before evaluating results.

#### 4. Evaluate results

**If all tests pass:**
- Mark the phase's task as `completed` using `TaskUpdate`.
- Update `.sdf/flows/<full-quest-name>/phases/phase_N_status.md`:
  ```
  status: passing
  tests_total: N
  tests_passing: N
  completed: <timestamp>
  ```
- Move to the next phase.

**If tests fail -- attempt to fix (up to 3 attempts):**

Each attempt must try a **meaningfully different approach**, not just tweak the same fix.

- **Attempt 1**: Analyze the failure. Identify the most likely root cause. Fix it.
- **Attempt 2**: If attempt 1 failed, reconsider the root cause. Try a different approach.
- **Attempt 3**: If attempt 2 failed, step back further. Re-read the phase plan and test spec. Consider whether the implementation approach itself is flawed.

**Bug-fixing discipline:**
- **Fix the bug, do not fix the test.** Tests represent the definition of done.
- **Run only failing tests during fix attempts.** After all failing tests pass individually, run the full phase suite once to confirm nothing else broke.
- **Anti-tail-chasing rule.** If each attempt is just adding complexity on top of the previous attempt, stop and escalate.

**After 3 failed attempts -- escalate:**
1. Mark the phase's task as `blocked` using `TaskUpdate` with a note about the failure.
2. Update `.sdf/flows/<full-quest-name>/phases/phase_N_status.md`:
   ```
   status: blocked
   tests_total: N
   tests_passing: M
   attempts: 3
   blocked_at: <timestamp>
   ```
3. Write a diagnosis to `.sdf/flows/<full-quest-name>/phases/phase_N_blocked.md`:
   ```markdown
   # Phase N Blocked: <phase name>

   ## Attempt 1
   - Root cause hypothesis: ...
   - What was tried: ...
   - Result: ...

   ## Attempt 2
   - Root cause hypothesis: ...
   - What was tried: ...
   - Result: ...

   ## Attempt 3
   - Root cause hypothesis: ...
   - What was tried: ...
   - Result: ...

   ## Current State
   - Tests passing: M/N
   - Failing tests: ...
   - Best hypothesis for remaining failures: ...

   ## Suggested Next Steps
   - ...
   ```
4. Return control to the user:
   > Phase N (`<phase name>`) is blocked after 3 attempts.
   > Passing: M/N tests.
   > See `.sdf/flows/<full-quest-name>/phases/phase_N_blocked.md` for full diagnosis.
   >
   > (A) I will fix it manually -- skip this phase and continue with the next
   > (B) Here is new guidance -- retry this phase (provide guidance)
   > (C) Skip this phase entirely
   > (D) Stop implementation -- I will handle this

Wait for user response and act accordingly.

---

## Stage 5: Verify and Simplify

When all phases are processed (either passing, skipped, or blocked-and-user-decided):

### Check completion

If some phases are blocked/skipped:
1. Present a summary showing each phase's status.
2. Tell the user: "Some phases need attention. Use `/sdf:status <full-quest-name>` to review."
3. Stop here. Do not proceed to verify or simplify.

If all phases are passing, proceed to the pipeline below.

### Step 1: Verify
Reset all phase statuses to `pending` and set `all_phases_passing: false` in STATE.md. Then for each phase: confirm test files exist, write them if missing, run them, fix failures (up to 3 attempts with the same escalation rules). If any phase gets blocked during verification, stop and escalate to the user.

### Step 2: Simplify
After all phases are verified, review for concrete simplification opportunities (DRY, reduce complexity, remove dead code). Only make changes directly related to this quest's implementation. Run tests after each change. Skip changes that are not obviously better.

### Step 3: Final verify
Reset all phase statuses to `pending` and set `all_phases_passing: false` in STATE.md again. Run the full test suite one more time across all phases. If any tests fail, fix them (up to 3 attempts) or revert the offending simplification.

### Step 4: Final summary
Present a combined summary:
```
SDF Quest Complete: <full-quest-name>

Implementation: X/Y phases passing
Verification: all tests confirmed
Simplification: N changes (M lines removed)
```
> Run `/sdf:done <full-quest-name>` to archive this quest.

Update STATE.md to:
```
current_stage: 5
stage_name: Complete
type: quest
parent: <parent>
valid_stages: [1, 2, 3, 4, 5]
all_phases_passing: true
```

---

## Checkpointing Rules

After EVERY meaningful interaction (each approval, each stage transition), update `.sdf/flows/<full-quest-name>/STATE.md` with:

```
current_stage: <number>
stage_name: <human-readable name>
type: quest
parent: <parent-flow-name or standalone>
valid_stages: [<list of non-stale stage numbers>]
```

Optional fields (include when relevant):
```
all_phases_passing: true/false    # after implementation
```

Always use this exact field naming. This ensures that `/sdf:quest <full-quest-name>` can parse STATE.md reliably when resuming.

---

## Important Rules

1. **Files are the source of truth.** At each stage boundary, read inputs from `.sdf/` files, not from conversation memory.
2. **Wait for user input.** Never skip a stage or auto-advance past a point that requires user approval.
3. **Use AskUserQuestion for all questions and confirmations.** Never print questions as plain text with (A), (B), (C) labels. Always use the `AskUserQuestion` tool.
4. **Closing question in every round.** The "Do you need more questions?" question must be in the last batch of every Q&A round, every time, no exceptions.
5. **Quest naming convention.** Quest directories are always `<parent>--<quest-name>`. The `--` separator distinguishes quests from full flows.
6. **Inherit, don't re-ask.** Testing strategy, codebase context, and conventions come from the parent flow or project -- never re-ask what's already been decided.
7. **Implementation is always in this conversation.** Unlike full SDF, quests do not offer "start in a new conversation" -- they are small enough to complete in one session.
8. **Capture learnings.** If you discover something non-obvious during implementation, append it to `.sdf/LEARNINGS.md` with the quest name and date.
9. **Missing tools in Docker.** If you need a system package that is not installed, install it with `sudo apt-get install -y <package>`. Only after successful installation, append the working package name to `.sdf/packages.txt` (one per line). If the install required troubleshooting, document it in `.sdf/LEARNINGS.md`.
