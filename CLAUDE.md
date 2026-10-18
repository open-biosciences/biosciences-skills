# CLAUDE.md — biosciences-skills

## Purpose

Domain skills library for the Open Biosciences platform. This repo is co-owned by the **Quality & Skills Engineer** agent.

Domain skills are research-facing — they encode life-sciences workflows (genomics, proteomics, pharmacology, etc.) and are consumed by agents and researchers. Platform-facing developer skills (scaffold commands, security review) live in [platform-skills](https://github.com/open-biosciences/platform-skills).

## Skills Architecture (ADR-002)

Skills are stored in `.claude/skills/` and follow the Platform-as-Product pattern:

```
.claude/skills/
└── {capability-name}/
    ├── SKILL.md            # Instructions and triggers
    ├── templates/          # Boilerplate files
    └── scripts/            # Validation or execution scripts
```

## Domain Skills (6)

| Skill | Purpose | Trigger |
|-------|---------|---------|
| `biosciences-crispr` | BioGRID ORCS 5-phase synthetic lethality validation | "CRISPR screen", "synthetic lethality" |
| `biosciences-genomics` | Ensembl, NCBI, HGNC curl endpoints | "gene lookup", "genomics query" |
| `biosciences-proteomics` | UniProt, STRING, BioGRID curl endpoints | "protein search", "interaction network" |
| `biosciences-pharmacology` | ChEMBL, PubChem, DrugBank, IUPHAR curl endpoints | "drug search", "compound lookup" |
| `biosciences-clinical` | Open Targets, ClinicalTrials.gov curl endpoints | "clinical trials", "disease associations" |
| `biosciences-graph-builder` | Fuzzy-to-Fact orchestration workflow | "build graph", "knowledge graph" |

## Graphiti Skills (Global)

These 4 skills are installed globally in `~/.claude/skills/` and available from any repo:

| Skill | Purpose |
|-------|---------|
| `graphiti-verify` | Day 1 verification sequence (5 checks) |
| `graphiti-health` | Unified health status report |
| `graphiti-aura-stats` | Neo4j Aura production analytics |
| `graphiti-docker-stats` | Docker dev environment analytics |

## SpecKit Commands (ADR-003)

SpecKit commands live in **`biosciences-program/.claude/commands/`**. They are available in any Claude Code session opened inside `biosciences-program/` or the workspace root.

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
- **Downstream**: All repos consume domain skills

## FastMCP Cloud Integration

### Adding biosciences-mcp to .mcp.json

Create or update `biosciences-skills/.mcp.json` to register the cloud endpoint:

```json
{
  "mcpServers": {
    "biosciences-mcp": {
      "type": "http",
      "url": "https://biosciences-mcp.fastmcp.app/mcp",
      "headers": {
        "Authorization": "Bearer ${BIOSCIENCES_API_KEY}"
      }
    }
  }
}
```

This makes all 40+ gateway tools available in Claude Code sessions within this project.

### Tool Name Alignment

The gateway registers tools with flat prefixed names (no slash-separated namespace). Each tool's name is `{server}_{operation}`, e.g. `hgnc_search_genes`, `uniprot_get_protein`. This is enforced by the `tool_names` mapping in `gateway.py`:

```python
mcp.mount(hgnc_mcp, prefix="hgnc", as_proxy=False,
    tool_names={"search_genes": "hgnc_search_genes", "get_gene": "hgnc_get_gene"})
```

In skills, reference a gateway tool by server and tool name, the `ServerName:tool_name` form from Anthropic's skill-authoring guidance:

```
biosciences-mcp:<gateway_tool_name>
```

Claude Code's full tool name depends on which configuration provides the server: `mcp__plugin_bio-research_biosciences-mcp__<gateway_tool_name>` when the bio-research plugin provides it, or `mcp__<server-key>__<gateway_tool_name>` when a user, project or local `.mcp.json` entry for the same URL takes precedence. Write the full name only where Claude Code requires one (permission rules, `allowed-tools`, subagent `tools`, hook matchers), and list both forms there, because which one applies depends on the install.

Full tool inventory (gateway name → skill reference):

| Gateway Tool | Skill Reference |
|---|---|
| `hgnc_search_genes` | `biosciences-mcp:hgnc_search_genes` |
| `hgnc_get_gene` | `biosciences-mcp:hgnc_get_gene` |
| `uniprot_search_proteins` | `biosciences-mcp:uniprot_search_proteins` |
| `uniprot_get_protein` | `biosciences-mcp:uniprot_get_protein` |
| `chembl_search_compounds` | `biosciences-mcp:chembl_search_compounds` |
| `chembl_get_compound` | `biosciences-mcp:chembl_get_compound` |
| `chembl_get_compounds_batch` | `biosciences-mcp:chembl_get_compounds_batch` |
| `opentargets_search_targets` | `biosciences-mcp:opentargets_search_targets` |
| `opentargets_get_target` | `biosciences-mcp:opentargets_get_target` |
| `opentargets_get_associations` | `biosciences-mcp:opentargets_get_associations` |
| `string_search_proteins` | `biosciences-mcp:string_search_proteins` |
| `string_get_interactions` | `biosciences-mcp:string_get_interactions` |
| `string_get_network_image_url` | `biosciences-mcp:string_get_network_image_url` |
| `biogrid_search_genes` | `biosciences-mcp:biogrid_search_genes` |
| `biogrid_get_interactions` | `biosciences-mcp:biogrid_get_interactions` |
| `ensembl_search_genes` | `biosciences-mcp:ensembl_search_genes` |
| `ensembl_get_gene` | `biosciences-mcp:ensembl_get_gene` |
| `ensembl_get_transcript` | `biosciences-mcp:ensembl_get_transcript` |
| `entrez_search_genes` | `biosciences-mcp:entrez_search_genes` |
| `entrez_get_gene` | `biosciences-mcp:entrez_get_gene` |
| `entrez_get_pubmed_links` | `biosciences-mcp:entrez_get_pubmed_links` |
| `pubchem_search_compounds` | `biosciences-mcp:pubchem_search_compounds` |
| `pubchem_get_compound` | `biosciences-mcp:pubchem_get_compound` |
| `iuphar_search_ligands` | `biosciences-mcp:iuphar_search_ligands` |
| `iuphar_get_ligand` | `biosciences-mcp:iuphar_get_ligand` |
| `iuphar_search_targets` | `biosciences-mcp:iuphar_search_targets` |
| `iuphar_get_target` | `biosciences-mcp:iuphar_get_target` |
| `wikipathways_search_pathways` | `biosciences-mcp:wikipathways_search_pathways` |
| `wikipathways_get_pathway` | `biosciences-mcp:wikipathways_get_pathway` |
| `wikipathways_get_pathways_for_gene` | `biosciences-mcp:wikipathways_get_pathways_for_gene` |
| `wikipathways_get_pathway_components` | `biosciences-mcp:wikipathways_get_pathway_components` |
| `clinicaltrials_search_trials` | `biosciences-mcp:clinicaltrials_search_trials` |
| `clinicaltrials_get_trial` | `biosciences-mcp:clinicaltrials_get_trial` |
| `clinicaltrials_get_trial_locations` | `biosciences-mcp:clinicaltrials_get_trial_locations` |

### Domain Skill Migration Note

Existing domain skills (e.g., `biosciences-graph-builder`, `biosciences-genomics`) reference tools using server-specific prefixes from when each API had its own MCP server:

```python
# Old pattern (individual servers, e.g. mcp__hgnc__search_genes)
hgnc.search_genes("p53")
uniprot.get_protein("UniProtKB:P04637")
```

After migration to the unified gateway, update domain skill pseudocode and examples to reflect the consolidated `biosciences-mcp` server name:

```python
# New pattern (unified gateway)
# biosciences-mcp:hgnc_search_genes
# biosciences-mcp:uniprot_get_protein
```

The Fuzzy-to-Fact workflow, CURIE formats, and all tool arguments remain unchanged. Only the server changes, from per-API servers to `biosciences-mcp`.
