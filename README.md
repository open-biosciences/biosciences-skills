# biosciences-skills

Shared skills library and SpecKit commands for the [Open Biosciences](https://github.com/open-biosciences) platform.

**Wave 1 — Complete.** Owned by the **Quality & Skills Engineer** (Agent 8). This is a provider repository — all other repos consume these skills and commands.

## Contents

### Domain Skills

Seven skills in `.claude/skills/`:

| Skill | Domain |
|-------|--------|
| lifesciences-clinical | Clinical trials and regulatory data |
| lifesciences-crispr | CRISPR gene editing workflows |
| lifesciences-genomics | Genomic data analysis and annotation |
| lifesciences-graph-builder | Knowledge graph construction patterns |
| lifesciences-pharmacology | Drug targets, mechanisms, pharmacology |
| lifesciences-proteomics | Protein structure, interactions, pathways |
| security-review | Pre-commit security review (secrets, paths, config hygiene) |

### Commands

Two commands in `.claude/commands/`:

**Scaffold** (2 commands):
`scaffold-fastmcp`, `scaffold-fastmcp-v2`

### Graphiti Skills (Global)

The 4 Graphiti knowledge graph skills (`graphiti-verify`, `graphiti-health`, `graphiti-aura-stats`, `graphiti-docker-stats`) are installed globally in `~/.claude/skills/` and available from any repo via `/graphiti-*`.

### SpecKit SDLC Commands

The 9 SpecKit workflow commands (per ADR-003) live in [biosciences-architecture](https://github.com/open-biosciences/biosciences-architecture) `.claude/commands/`:

`speckit.constitution`, `speckit.specify`, `speckit.clarify`, `speckit.plan`, `speckit.tasks`, `speckit.taskstoissues`, `speckit.analyze`, `speckit.checklist`, `speckit.implement`

They are available in any Claude Code session opened at the workspace root or inside `biosciences-architecture/`.

## Usage

Skills and commands are consumed automatically by Claude Code when working within any Open Biosciences repo. To use them in a new repo, copy or symlink the relevant `.claude/` directories.

SpecKit workflow example:

```
/speckit.specify       # Create a feature specification
/speckit.plan          # Generate implementation plan
/speckit.tasks         # Break into actionable tasks
/speckit.implement     # Execute bounded implementation
```

## Dependencies

- [biosciences-architecture](https://github.com/open-biosciences/biosciences-architecture) — ADR-002 (skills structure) and ADR-003 (SpecKit workflow)

## Related Repos

- [biosciences-architecture](https://github.com/open-biosciences/biosciences-architecture) — governance and ADRs (SpecKit commands live here)
- [biosciences-evaluation](https://github.com/open-biosciences/biosciences-evaluation) — quality gates that measure skill effectiveness
- [biosciences-program](https://github.com/open-biosciences/biosciences-program) — migration coordination

## License

MIT
