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

SpecKit commands live in **`biosciences-architecture/.claude/commands/`** (moved from this repo — see ADR-003).

They are available in any Claude Code session opened inside `biosciences-architecture/` or the workspace root.

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

## FastMCP Cloud Integration

### Adding biosciences-mcp to .mcp.json

Create or update `biosciences-skills/.mcp.json` to register the cloud endpoint:

```json
{
  "mcpServers": {
    "biosciences-mcp": {
      "type": "http",
      "url": "https://biosciences-mcp.fastmcp.app/mcp"
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

When accessing tools via the FastMCP Cloud gateway in Claude Code, the MCP server name is prepended as an additional prefix using double-underscores:

```
mcp__biosciences-mcp__<gateway_tool_name>
```

Full tool inventory (gateway name → Claude Code name):

| Gateway Tool | Claude Code Name |
|---|---|
| `hgnc_search_genes` | `mcp__biosciences-mcp__hgnc_search_genes` |
| `hgnc_get_gene` | `mcp__biosciences-mcp__hgnc_get_gene` |
| `uniprot_search_proteins` | `mcp__biosciences-mcp__uniprot_search_proteins` |
| `uniprot_get_protein` | `mcp__biosciences-mcp__uniprot_get_protein` |
| `chembl_search_compounds` | `mcp__biosciences-mcp__chembl_search_compounds` |
| `chembl_get_compound` | `mcp__biosciences-mcp__chembl_get_compound` |
| `chembl_get_compounds_batch` | `mcp__biosciences-mcp__chembl_get_compounds_batch` |
| `opentargets_search_targets` | `mcp__biosciences-mcp__opentargets_search_targets` |
| `opentargets_get_target` | `mcp__biosciences-mcp__opentargets_get_target` |
| `opentargets_get_associations` | `mcp__biosciences-mcp__opentargets_get_associations` |
| `string_search_proteins` | `mcp__biosciences-mcp__string_search_proteins` |
| `string_get_interactions` | `mcp__biosciences-mcp__string_get_interactions` |
| `string_get_network_image_url` | `mcp__biosciences-mcp__string_get_network_image_url` |
| `biogrid_search_genes` | `mcp__biosciences-mcp__biogrid_search_genes` |
| `biogrid_get_interactions` | `mcp__biosciences-mcp__biogrid_get_interactions` |
| `ensembl_search_genes` | `mcp__biosciences-mcp__ensembl_search_genes` |
| `ensembl_get_gene` | `mcp__biosciences-mcp__ensembl_get_gene` |
| `ensembl_get_transcript` | `mcp__biosciences-mcp__ensembl_get_transcript` |
| `entrez_search_genes` | `mcp__biosciences-mcp__entrez_search_genes` |
| `entrez_get_gene` | `mcp__biosciences-mcp__entrez_get_gene` |
| `entrez_get_pubmed_links` | `mcp__biosciences-mcp__entrez_get_pubmed_links` |
| `pubchem_search_compounds` | `mcp__biosciences-mcp__pubchem_search_compounds` |
| `pubchem_get_compound` | `mcp__biosciences-mcp__pubchem_get_compound` |
| `iuphar_search_ligands` | `mcp__biosciences-mcp__iuphar_search_ligands` |
| `iuphar_get_ligand` | `mcp__biosciences-mcp__iuphar_get_ligand` |
| `iuphar_search_targets` | `mcp__biosciences-mcp__iuphar_search_targets` |
| `iuphar_get_target` | `mcp__biosciences-mcp__iuphar_get_target` |
| `wikipathways_search_pathways` | `mcp__biosciences-mcp__wikipathways_search_pathways` |
| `wikipathways_get_pathway` | `mcp__biosciences-mcp__wikipathways_get_pathway` |
| `wikipathways_get_pathways_for_gene` | `mcp__biosciences-mcp__wikipathways_get_pathways_for_gene` |
| `wikipathways_get_pathway_components` | `mcp__biosciences-mcp__wikipathways_get_pathway_components` |
| `clinicaltrials_search_trials` | `mcp__biosciences-mcp__clinicaltrials_search_trials` |
| `clinicaltrials_get_trial` | `mcp__biosciences-mcp__clinicaltrials_get_trial` |
| `clinicaltrials_get_trial_locations` | `mcp__biosciences-mcp__clinicaltrials_get_trial_locations` |

### Domain Skill Migration Note

Existing domain skills (e.g., `lifesciences-graph-builder`, `lifesciences-genomics`) reference tools using server-specific prefixes from when each API had its own MCP server:

```python
# Old pattern (individual servers, e.g. mcp__hgnc__search_genes)
hgnc.search_genes("p53")
uniprot.get_protein("UniProtKB:P04637")
```

After migration to the unified gateway, update domain skill pseudocode and examples to reflect the consolidated `biosciences-mcp` server name:

```python
# New pattern (unified gateway)
# mcp__biosciences-mcp__hgnc_search_genes
# mcp__biosciences-mcp__uniprot_get_protein
```

The Fuzzy-to-Fact workflow, CURIE formats, and all tool arguments remain unchanged. Only the Claude Code prefix (`mcp__<server>__`) changes from server-specific to `mcp__biosciences-mcp__`.

### scaffold-fastmcp Updates

The `scaffold-fastmcp.md` skill currently targets the predecessor `lifesciences-mcp` package and references `lifesciences_mcp` import paths. It should be updated to:

1. Target `biosciences_mcp` package paths (`src/biosciences_mcp/servers/<api>.py`)
2. Reference `biosciences-mcp` as the canonical gateway pattern (mount new server into `gateway.py`)
3. Include `fastmcp deploy` as the final deployment step after `fastmcp auth`:
   ```bash
   fastmcp auth                          # Authenticate with FastMCP Cloud (one-time)
   fastmcp deploy src/biosciences_mcp/servers/gateway.py  # Deploy unified gateway
   ```
4. Add the new server to `gateway.py` `mcp.mount()` block with a `tool_names` mapping following the `{server}_{operation}` convention
