---
description: Initialize an Angular landing page with plain CSS based on the project's openspec context
---

### `/ui-step-1-init-project`

Scaffold an Angular landing page (hero, features, header) using plain CSS — no Tailwind, no component libraries.

## Instructions

### Step 1: Check frontend project

Check if `frontend/` exists and contains an Angular project (`angular.json`).

- If it exists: proceed to Step 2
- If it does not exist: run `ng new frontend --style=css --routing --ssr=false` and then proceed

### Step 2: Read project context

Read `openspec/project.md` and extract:
- The **Overview** (what the project is)
- The **Problem Statement** (what problem it solves)
- The **Modules** list (key capabilities)

If `openspec/project.md` does not exist, tell the user to run `/bootstrap-openspec` first and stop.

### Step 3: Build the landing page

Launch the **angular-engineer** agent with the following prompt:

> Build an Angular landing page for the frontend project at `frontend/`.
>
> **Project context:**
> - Overview: {overview from project.md}
> - Problem statement: {problem statement from project.md}
> - Key modules: {modules from project.md}
>
> **Requirements:**
> - Use **plain CSS only** — no Tailwind, no Spartan UI, no component libraries
> - Create a **header** with navigation and project name
> - Create a **hero section** with a headline, subtitle, and call-to-action button
> - Create a **features section** showcasing the key modules/capabilities from the project context
> - **No footer** needed
> - Use semantic HTML elements (`<header>`, `<section>`, `<nav>`, etc.)
> - Make it responsive with CSS media queries so it works on Desktop and Mobile devices
> - Use a clean, modern design with good spacing and typography
> - Use the Angular app component or create a dedicated landing page component
> - All text content should reflect the actual project (not placeholder lorem ipsum)
>
> $ARGUMENTS

### Step 4: Verify

After the agent completes, check that `ng serve` compiles without errors:

```bash
cd frontend && npx ng build --configuration development 2>&1 | tail -5
```

Report the result to the user. If there are errors, fix them.
