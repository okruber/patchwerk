## A patchwork of CC-related materials I've found on the web
---

### To use:
1. Use an LLM to generate a spec file describing the project/feature:
> Ask me one question at a time so we can develop a thorough, step-by-step spec for this idea. Each question should build on my previous answers, and our end goal is to have a detailed specification I can hand off to a developer. Let’s do this iteratively and dig into every relevant detail. Remember, only one question at a time. 
> Here’s the idea:

#### As the brainstorming concludes:

> Now that we’ve wrapped up the brainstorming process, can you compile our findings into a comprehensive, developer-ready specification? Include all relevant requirements, architecture choices, data handling details, error handling strategies, and a testing plan so a developer can immediately begin implementation.

2. Save the results from above as spec.md
3. Optional: feed the spec.md file to a reasoning model
4. Add the spec.md in the project repository
5. Execute /plan-tdd spec.md