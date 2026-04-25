# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bin/rails server          # start dev server
bundle exec rspec         # run all tests
bundle exec rspec spec/controllers/bus_controller_spec.rb  # run a single spec file
bundle exec rubocop       # lint
bundle exec brakeman      # security scan
```

## Architecture

Single-purpose Rails 8 app with no database. One controller (`BusController`) fetches live bus arrival data from the TMB (Barcelona transit) API and renders it in a self-refreshing page.

**Request flow:**
1. `GET /` → `BusController#index`
2. Controller calls `https://api.tmb.cat/v1/ibus/stops/822` with credentials from `ENV["TMB_APP_ID"]` / `ENV["TMB_APP_KEY"]`
3. Filters the response to line `"6"` and returns an array of `{ minutes:, destination: }` hashes
4. `app/views/bus/index.html.erb` renders the arrivals — the view is self-contained HTML+CSS (no application layout, no asset pipeline involvement)
5. `<meta http-equiv="refresh" content="30">` handles auto-refresh

**TMB API note:** The documented `temps-espera` endpoint (`/v1/transit/linies/bus/:line/parades/:stop/temps-espera`) does not exist. Real-time data comes from `/v1/ibus/stops/:stop` instead, which returns all lines at the stop.

**Credentials:** stored in `.env` (gitignored), loaded by `dotenv-rails` in development.

**Tests:** RSpec request specs in `spec/controllers/`. WebMock stubs all outbound HTTP — no real API calls in tests.

# Working Preferences

## Git & Commits
- Always commit in small, focused chunks — one commit per logical change
- Never bundle unrelated changes in a single commit
- Use clear, descriptive commit messages in the format: `type: short description`
  - Examples: `fix: correct TMB API base URL`, `feat: add auto-refresh`, `style: improve bus card layout`
- Always stop and wait for my approval before committing anything
- Show me what you're about to commit with `git diff --staged` before proceeding

## General Workflow
- After each meaningful change, pause and let me review before moving on
- Don't chain multiple big changes together without checking in
- If you're unsure about an approach, ask me before implementing it

## Ruby Coding Style

### Methods
- Keep methods small and focused — one responsibility per method
- If a method does more than one thing, split it into smaller private methods
- Aim for methods under 10 lines
- Order private methods by usage, the first used up.

### Constants
- Never hardcode URLs, strings or config values inside methods
- Extract them as constants at the top of the class in SCREAMING_SNAKE_CASE

### General
- Prefer readable code over clever one-liners
- Use private methods to hide implementation details
