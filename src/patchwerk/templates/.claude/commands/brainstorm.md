Load the `brainstorming` skill if not already loaded.

Then run the brainstorming protocol:

1. If the user provided a task description with this command, proceed to **Step 1: Context Discovery** using that description.
2. If no task was provided, ask: "What do you want to build or change?"

**Do not write any code until the protocol completes.**

The protocol will:
- Discover project context silently (Step 1)
- Assess scope and decompose into beads if needed (Step 2)
- Ask clarifying questions only if necessary (Step 3)
- Propose approaches for the user to choose from (Step 4)
- Produce beads or proceed directly for quick-fixes (Step 5)
- Transition to implementation with user's chosen strategy (Step 6)
