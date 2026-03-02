## Thermo Data Explorer — Improvement Tasks

### In Progress
[Claude moves tasks here when working on them]

### To Do
- [ ] Add pressure unit toggle (kPa / bar / atm / psi) — convert to kPa before API call
- [ ] Add CSV export button for results table
- [ ] Highlight differences when comparing 2 compounds in results table
- [ ] Add search history — remember last 5 compound searches per session
- [ ] Replace spinner with loading skeleton in results table
- [ ] Add "copy results" button to copy table as plain text
- [ ] Improve error messages — make them more specific and helpful

### Done
- [x] Add temperature unit toggle (K / °C / °F) — convert to K before API call
```

---

## First Prompt to Give Claude Code

Once Claude Code is running in your project folder, paste this:
```
Read CLAUDE.md and tasks/todo.md. 

Let's start with the temperature unit toggle. The app currently only accepts 
Kelvin. I want a toggle above the temperature field that lets the user pick 
K, °C, or °F. The display should show whatever unit they picked, but always 
convert to Kelvin before sending to the API.

Plan the change first — tell me which files you'll touch and what you'll do 
before writing any code.