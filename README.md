# biosciences-skills

Shared skills library and SpecKit commands for the [Open Biosciences](https://github.com/open-biosciences) platform.

Owned by the **Quality & Skills Engineer** agent. This is a provider repository -- all other repos consume these skills and commands.

## Contents

### Domain Skills

Six life sciences domain skills in `.claude/skills/`:

| Skill | Domain |
|-------|--------|
| lifesciences-clinical | Clinical trials and regulatory data |
| lifesciences-crispr | CRISPR gene editing workflows |
| lifesciences-genomics | Genomic data analysis and annotation |
| lifesciences-graph-builder | Knowledge graph construction patterns |
| lifesciences-pharmacology | Drug targets, mechanisms, pharmacology |
| lifesciences-proteomics | Protein structure, interactions, pathways |

### Commands

Fifteen commands in `.claude/commands/`:

**SpecKit SDLC** (9 commands, per ADR-003):
`speckit.constitution`, `speckit.specify`, `speckit.clarify`, `speckit.plan`, `speckit.tasks`, `speckit.taskstoissues`, `speckit.analyze`, `speckit.checklist`, `speckit.implement`

**Graphiti knowledge graph** (4 commands):
`graphiti-health`, `graphiti-verify`, `graphiti-aura-stats`, `graphiti-docker-stats`

**Scaffold** (2 commands):
`scaffold-fastmcp`, `scaffold-fastmcp-v2`

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

- [biosciences-architecture](https://github.com/open-biosciences/biosciences-architecture) -- ADR-002 (skills structure) and ADR-003 (SpecKit workflow)

## Related Repos

- [biosciences-architecture](https://github.com/open-biosciences/biosciences-architecture) -- governance and ADRs
- [biosciences-evaluation](https://github.com/open-biosciences/biosciences-evaluation) -- quality gates that measure skill effectiveness
- [biosciences-program](https://github.com/open-biosciences/biosciences-program) -- migration coordination

## License

MIT
