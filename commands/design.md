---
description: Start a live UI design session with the ui-designer agent and Playwright browser preview
---

### `/design`

Start an interactive design session with live browser preview.

## Instructions

1. **Check that `ng serve` is running** by checking if `http://localhost:4200` is reachable:
   ```bash
   curl -s -o /dev/null -w "%{http_code}" http://localhost:4200
   ```
   - If it returns 200: proceed
   - If it fails: tell the user to start `ng serve` first (`cd frontend && ng serve`) and wait

2. **Launch the `ui-designer` agent** with the following prompt:

   > You are starting a live design session. The Angular dev server is running at http://localhost:4200.
   >
   > 1. Ask the user which page they want to work on (e.g. `/`, `/sites`, `/components`) — or check if they specified a path in their request
   > 2. Navigate to `http://localhost:4200{path}` using browser_navigate
   > 3. Take a screenshot with browser_screen_capture to see the current state
   > 4. Report back what you see and ask the user what they'd like to change or build
   >
   > User's request: $ARGUMENTS
   >
   > If the request includes a path (e.g. "/sites", "/components"), navigate there directly.
   > If no path is given, ask the user which page they want to work on before navigating.

3. **Continue the conversation** — relay user feedback to the designer agent and let them iterate with live screenshots.
