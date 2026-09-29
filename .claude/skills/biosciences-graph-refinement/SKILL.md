---
name: biosciences-graph-refinement
description: "Use when revising, repairing, extending, or reviewing an existing biosciences knowledge graph or claim set — fixing dangling edges or count drift, adding or downgrading claims after new or negative evidence, preparing a graph revision for review or publication, or when asked to mark graph claims 'validated'. Also use when a refinement pass must stay within a bounded context or budget."
---

# Biosciences Graph Refinement

A refinement pass produces a **revision bundle**: a proposal that is traceable and deterministically checked, and that a human can accept or reject. A model proposes the revision, a deterministic validator checks its structure, and only a named human accepts a claim.

```
A model review, a validator pass, a quality score (e.g. "9.2/10 PASS"), an identifier,
or database concordance does NOT establish that a claim is scientifically true.
They establish that the claim is well-formed and traceable to evidence. Nothing more.
```

**REQUIRED SUB-SKILL:** Use `biosciences-graph-builder` for every new identifier or retrieval (Fuzzy-to-Fact, LOCATE → RETRIEVE, `slim` budgeting). This skill does not repeat that protocol.

## When not to use

- Building a graph from scratch for a new question → `biosciences-graph-builder`.
- Formatting a report, or reviewing a report's prose → `biosciences-reporting` / `biosciences-reporting-quality-review`.
- Implementing the Temporal workflow that runs refinement → the official Temporal developer skill ([temporalio/skill-temporal-developer](https://github.com/temporalio/skill-temporal-developer)) and [docs.temporal.io](https://docs.temporal.io/with-ai). This skill contains no Temporal guidance.

## 1. Load a bounded context packet

Before reasoning, collect only:

| Item | Content |
|---|---|
| Question | The one question this pass answers |
| Scope | Disease CURIE, genotype/co-mutation context, the branch being refined |
| Subgraph | Nodes and edges in that branch, and nothing else |
| Claims | ID, status, and evidence IDs for claims in the branch |
| Evidence index | `evidence_id` → source, record ID, retrieval time, digest. Do not load full bodies. |
| Open issues | Structural validator output for the parent graph (`--profile structural`, §5) and prior review findings. State a structural defect in the parent graph only if that output shows it. |

Fetch full documents and tool responses **by reference** (evidence ID, record ID, file path) only when a specific claim needs them. If the caller set caps (nodes, claims, retrievals, review rounds), stop at a cap and return `incomplete`. Do not exceed a cap.

## 2. Resolve identifiers before using them

An identifier is `resolved` only if a LOCATE → RETRIEVE pair in **this** pass or in cited evidence produced it. In every other case, write the node with `"id_status": "unresolved"` (or `"local_concept"` for framework or placeholder concepts) and list it under open issues. Every node still needs an `id`. If no CURIE has been retrieved yet, use a placeholder such as `UNRESOLVED:ATR`, and never a guessed database ID.

This applies even when the ID looks obvious. For example:
- The missing target of a dangling edge (`HGNC:9077`) stays unresolved until `hgnc_get_gene` returns it.
- A compound name → ChEMBL ID "from memory" stays unresolved until `chembl_search_compounds` → `chembl_get_compound`.
- A bare trial ID `NCT01294306` is written `NCT:01294306` and still needs retrieval before a claim can depend on it.

## 3. Record evidence, then write claims

Every retrieval that a claim relies on becomes an evidence record (illustrative values):

```json
{"evidence_id": "ev-7", "source": "clinicaltrials_get_trial", "record_id": "NCT:02688907",
 "retrieved_at": "2026-09-29T14:02:11Z", "content_digest": "sha256:<hash of the raw response>"}
```

Each claim is `subject –predicate→ object` with exactly one status:

| Status | Use when | Required |
|---|---|---|
| `supported` | Retrieved evidence states it in this context | `evidence_ids`; resolved endpoints |
| `contradicted` | Retrieved evidence conflicts with it (e.g. a negative trial) | `evidence_ids`; resolved endpoints |
| `hypothesis` | Framework-derived, predicted, or taken from a grounding document | Source reference if one exists |
| `inference` | Derived from other claims | `derived_from` claim IDs |
| `unresolved` | Identifier or evidence gap | Open issue describing the gap |

Every claim sets `qualifiers.disease` (a resolved MONDO, EFO, DOID or ORPHA CURIE). A genotype-dependent claim, such as synthetic lethality or a genotype-selective response, also sets `qualifiers.genotype`. If a claim's disease or context differs from the scope (NSCLC vs SCLC, a different co-mutation), declare `qualifiers.context_transfer` with a rationale.

Training knowledge ("well-known biology", "I believe this is PLK1", "the mechanism is contested") is never evidence. Record it as an open question or a retrieval to run, and do not use it as a claim status or justification. Negative evidence downgrades or qualifies a claim, and the claim stays visible. Do not delete it.

## 4. Emit the revision bundle

Output the bundle shape defined in `biosciences-temporal` [`docs/graph-refinement/validation-contract.md`](https://github.com/open-biosciences/biosciences-temporal/blob/main/docs/graph-refinement/validation-contract.md) (`graph-refinement-bundle/0.1-proposed`, proposed in [biosciences-temporal#3](https://github.com/open-biosciences/biosciences-temporal/pull/3)). It contains:

- `schema_version`
- `revision`: `revision_id`, `parent_revision_id` (`null` for a root), `created_at`, and `producer: {kind: model|human|deterministic, id}`
- `scope`
- `nodes`, `edges`, `evidence`, `claims`
- `open_issues`: a list of gaps, pending retrievals, and questions for the reviewer

Fill each part as follows:

- A claim's `subject` and `object` are node IDs. Genotype, disease, and cohort go in `qualifiers`, never in `object`.
- `evidence` holds only retrievals that actually ran. A retrieval you still need goes in `open_issues`, not in an evidence record with null fields.
- If no disease CURIE has been resolved, leave `qualifiers.disease` unset and let the validator report it. Do not write placeholder text such as `"unresolved"`.
- Anything the contract cannot express goes in `open_issues`. Do not add ad-hoc fields (`validation: "VERIFIED"`, `evidence_role`, `proposed_status_after_retrieval`, new edge types).

## 5. Validate deterministically

Run the validator. Do not count or check by hand:

```bash
uv run python -m biosciences_temporal.graph_refinement.validation bundle.json          # in biosciences-temporal
uv run python -m biosciences_temporal.graph_refinement.validation kg.json --profile structural   # existing KG JSON
```

If the validator is not available, compute the same invariants with a script over the JSON: unique IDs, edge endpoints exist, metadata counts equal the recomputed counts, and every cited evidence ID exists. Report the script and its output. Fix the errors you can, re-run, and include the final report. Errors that need a retrieval or a human decision stay in the report, and the outcome becomes `incomplete` or `needs_review`. Never reshape the bundle just to silence an error.

## 6. Review, then escalate

A model reviewer checks whether each cited evidence record supports the **exact** claim in the **stated** context. It may set `needs_review` or `rejected`, but never `accepted`.

Escalate to a human, and set the outcome to `needs_review`, when any of these hold:
- a claim is `contradicted`, or new evidence would change a claim's status;
- a claim uses `context_transfer`;
- two artifacts define the same metric or threshold differently (for example the sign convention for S′);
- a central claim depends on an `unresolved` identifier;
- someone asks for claims to be marked validated, accepted, or publication-ready;
- a budget or cap was reached.

Return exactly one outcome: `reviewed_draft` (validator passes, review found no blocking issue, human acceptance still pending), `needs_review`, or `incomplete`. Graph-memory writes, publication, and preprint export are separate steps, and a human approves each one. A refinement pass does not perform them.

## Common mistakes

| Mistake | Correction |
|---|---|
| Filling a dangling endpoint from memory | Node `id_status: unresolved` plus a LOCATE → RETRIEVE task |
| "Supported (weak sourcing)" based on known biology | `hypothesis`, or `unresolved` with a retrieval task |
| Disease or genotype written only in prose | `qualifiers.disease` / `qualifiers.genotype` |
| Evidence record with null `retrieved_at` or digest for a retrieval that never ran | An entry in `open_issues` |
| Claim object such as "TP53-loss lung cancer" | Object is a node ID. Context goes in `qualifiers`. |
| Hand-counted metadata | Validator output |
| Treating a prior PASS score as clearance | A score is presentation quality. It says nothing about truth. |
| Writing the revision to Graphiti or Neo4j | Bundle file only. Persistence is a separate, approved step. |
