---
name: feature-plan
description: Create or update a structured feature plan with architecture diagrams, test strategy, and alternatives analysis. Use when asked to plan, design, or spec out a feature before implementing it.
argument-hint: "<feature-name> | update <feature-name>"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, Agent
effort: high
---

# Feature Plan Skill

You are creating or updating a **feature plan document**. These plans serve as living technical documentation that evolves with the feature.

## Determine Mode

Parse `$ARGUMENTS`:
- If it starts with `update `: this is an **update** to an existing plan. Read the existing plan file first.
- Otherwise: this is a **new plan** creation.

## Output Location

Write the plan to: `docs/plans/<feature-name>.md`

If the `docs/plans/` directory doesn't exist, create it.

## For New Plans

Follow the template in [templates/feature-plan.md](templates/feature-plan.md) exactly. Fill every section thoroughly.

### Requirements

1. **Description**: Clear problem statement and goals at the top.

2. **Architecture Diagram**: Create detailed ASCII diagrams using Unicode box-drawing characters:
   - Use `┌─┐│└┘├┤┬┴┼` for boxes
   - Use `───`, `│`, `──▶`, `│▼` for connections
   - Use `╔═╗║╚╝` for emphasis/boundaries
   - Label all components and data flows
   - Show system boundaries with double-line boxes
   - Include a legend if the diagram has more than 5 components
   - Create separate diagrams for: system overview, data flow, and sequence (where applicable)

3. **Alternatives Analysis**: For each major design decision:
   - List at least 2-3 alternatives considered
   - Provide pros/cons for each
   - State the chosen approach with clear rationale
   - Note what would trigger reconsidering this decision

4. **Test Strategy**: Break down into three tiers:
   - **Unit Tests**: Individual function/component tests, edge cases, mocking strategy
   - **Integration Tests**: Cross-module interactions, API contract tests, database interactions
   - **E2E Tests**: Full user workflow tests, critical path coverage, environment requirements
   - For each tier: list specific test cases, not just categories

5. **Update Log**: Initialize with the creation entry at the top.

## For Updates

When updating an existing plan:

1. Read the current plan file
2. Do NOT modify existing update entries
3. Prepend a new entry to the `## Update Log` section (reverse chronological - newest first)
4. Update any sections that have changed (architecture, test plan, etc.)
5. If a decision from alternatives analysis has been reversed, document why in both the alternatives section and the update log

## Diagram Style Guide

Use this style for all ASCII diagrams:

```
╔══════════════════════════════════════════════════════╗
║                   SYSTEM BOUNDARY                    ║
╠══════════════════════════════════════════════════════╣
║                                                      ║
║  ┌──────────┐   request   ┌──────────┐              ║
║  │  Client  │────────────▶│   API    │              ║
║  └──────────┘             └────┬─────┘              ║
║                                │                     ║
║                    ┌───────────┼───────────┐         ║
║                    │           │           │         ║
║                    ▼           ▼           ▼         ║
║              ┌─────────┐ ┌─────────┐ ┌─────────┐   ║
║              │ Service  │ │  Cache  │ │  Queue  │   ║
║              │    A     │ │         │ │         │   ║
║              └────┬─────┘ └─────────┘ └────┬────┘   ║
║                   │                        │         ║
║                   ▼                        ▼         ║
║              ┌─────────┐           ┌──────────┐     ║
║              │   DB    │           │  Worker  │     ║
║              └─────────┘           └──────────┘     ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
```

For sequence diagrams:
```
  Client          API           Service         DB
    │              │               │             │
    │──── GET ────▶│               │             │
    │              │── validate ──▶│             │
    │              │               │── query ───▶│
    │              │               │◀── rows ────│
    │              │◀── result ────│             │
    │◀── 200 OK ──│               │             │
    │              │               │             │
```

For data flow diagrams:
```
  ┌─────────┐      ┌─────────┐      ┌─────────┐
  │  Input  │─────▶│ Process │─────▶│ Output  │
  └─────────┘      └────┬────┘      └─────────┘
                        │
                   ┌────▼────┐
                   │  Side   │
                   │ Effect  │
                   └─────────┘
```

## Quality Checklist

Before writing the plan, verify:
- [ ] Problem statement is clear and specific
- [ ] At least one architecture diagram is included
- [ ] Every major decision has alternatives documented
- [ ] Test cases are specific (not just "test the API")
- [ ] Unit/integration/e2e split is justified for the feature's complexity
- [ ] Update log is initialized
- [ ] The plan is actionable — a developer could start implementing from it
