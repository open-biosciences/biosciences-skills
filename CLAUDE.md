# CLAUDE.md — biosciences-skills

## Purpose

Shared skills library and SpecKit commands for the Open Biosciences platform. This repo is co-owned by the **Quality & Skills Engineer** agent.

## Skills Architecture (ADR-002)

Skills are stored in `.claude/skills/` and follow the Platform-as-Product pattern:

```
.claude/skills/
└── {capability-name}/
    ├── SKILL.md            # Instructions and triggers
    ├── templates/          # Boilerplate files
    └── scripts/            # Validation or execution scripts
```

## Domain Skills (from predecessor)

| Skill | Purpose | Trigger |
|-------|---------|---------|
| `lifesciences-crispr` | BioGRID ORCS 5-phase synthetic lethality validation | "CRISPR screen", "synthetic lethality" |
| `lifesciences-genomics` | Ensembl, NCBI, HGNC curl endpoints | "gene lookup", "genomics query" |
| `lifesciences-proteomics` | UniProt, STRING, BioGRID curl endpoints | "protein search", "interaction network" |
| `lifesciences-pharmacology` | ChEMBL, PubChem, DrugBank, IUPHAR curl endpoints | "drug search", "compound lookup" |
| `lifesciences-clinical` | Open Targets, ClinicalTrials.gov curl endpoints | "clinical trials", "disease associations" |
| `lifesciences-graph-builder` | Fuzzy-to-Fact orchestration workflow | "build graph", "knowledge graph" |

## Scaffold Skills

| Skill | Purpose | Trigger |
|-------|---------|---------|
| `scaffold-fastmcp` | Create new MCP server with standard structure | "Scaffold a new API", "Create MCP server" |
| `scaffold-fastmcp-v2` | Updated v2 scaffold | "Scaffold FastMCP v2" |

## Graphiti Skills

| Skill | Purpose |
|-------|---------|
| `graphiti-aura-stats` | Neo4j Aura graph statistics |
| `graphiti-docker-stats` | Local Docker graph statistics |
| `graphiti-health` | Graphiti server health check |
| `graphiti-verify` | Verify Graphiti MCP connections |

## SpecKit Commands (ADR-003)

Specification-driven development workflow:

| Command | Purpose |
|---------|---------|
| `/speckit.constitution` | Establish project principles (one-time) |
| `/speckit.specify` | Create feature specification |
| `/speckit.clarify` | Surface underspecified areas |
| `/speckit.plan` | Create implementation plan |
| `/speckit.tasks` | Generate actionable tasks |
| `/speckit.analyze` | Cross-artifact consistency check |
| `/speckit.implement` | Execute bounded implementation |
| `/speckit.checklist` | Pre-flight checklist |
| `/speckit.taskstoissues` | Convert tasks to GitHub issues |

## Skill Authoring Guide

New skills must follow ADR-002:
1. Create directory in `.claude/skills/{name}/`
2. Write `SKILL.md` with clear triggers and constraints
3. Add `templates/` for any boilerplate
4. Test that the skill triggers correctly from natural language

## Dependencies

- **Upstream**: `biosciences-architecture` (ADR-002, ADR-003 governance)
- **Downstream**: All repos consume skills and SpecKit commands

## Pre-Migration Source

Until Wave 1 migration:
- Skills: `/home/donbr/graphiti-org/lifesciences-research/.claude/skills/`
- Commands: `/home/donbr/graphiti-org/lifesciences-research/.claude/commands/`
