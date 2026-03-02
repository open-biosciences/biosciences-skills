# biosciences-skills

Domain skills library for the [Open Biosciences](https://github.com/open-biosciences) platform.

**Wave 1 — Complete.** Owned by the **Quality & Skills Engineer** (Agent 8). This is a provider repository — all other repos consume these domain skills.

## Contents

### Domain Skills

Six skills in `.claude/skills/`:

| Skill | Domain |
|-------|--------|
| biosciences-clinical | Clinical trials and regulatory data |
| biosciences-crispr | CRISPR gene editing workflows |
| biosciences-genomics | Genomic data analysis and annotation |
| biosciences-graph-builder | Knowledge graph construction patterns |
| biosciences-pharmacology | Drug targets, mechanisms, pharmacology |
| biosciences-proteomics | Protein structure, interactions, pathways |

### Platform Skills

Platform-facing developer skills (scaffold commands, security review) have moved to [platform-skills](https://github.com/open-biosciences/platform-skills).

### Graphiti Skills (Global)

The 4 Graphiti knowledge graph skills (`graphiti-verify`, `graphiti-health`, `graphiti-aura-stats`, `graphiti-docker-stats`) are installed globally in `~/.claude/skills/` and available from any repo via `/graphiti-*`.

### SpecKit SDLC Commands

The 9 SpecKit workflow commands (per ADR-003) live in [biosciences-program](https://github.com/open-biosciences/biosciences-program) `.claude/commands/`:

`speckit.constitution`, `speckit.specify`, `speckit.clarify`, `speckit.plan`, `speckit.tasks`, `speckit.taskstoissues`, `speckit.analyze`, `speckit.checklist`, `speckit.implement`

They are available in any Claude Code session opened at the workspace root or inside `biosciences-program/`.

## Usage

Skills are consumed automatically by Claude Code when working within any Open Biosciences repo. To use them in a new repo, copy or symlink the relevant `.claude/` directories.

SpecKit workflow example:

```
/speckit.specify       # Create a feature specification
/speckit.plan          # Generate implementation plan
/speckit.tasks         # Break into actionable tasks
/speckit.implement     # Execute bounded implementation
```

## Dependencies

- [biosciences-program](https://github.com/open-biosciences/biosciences-program) — ADR-002 (skills structure) and ADR-003 (SpecKit workflow)

## Related Repos

- [platform-skills](https://github.com/open-biosciences/platform-skills) — platform skills (scaffold commands, security review)
- [biosciences-program](https://github.com/open-biosciences/biosciences-program) — governance and ADRs
- [biosciences-program](https://github.com/open-biosciences/biosciences-program) — SpecKit commands and migration coordination
- [biosciences-evaluation](https://github.com/open-biosciences/biosciences-evaluation) — quality gates that measure skill effectiveness

## License

MIT
