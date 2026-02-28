#!/usr/bin/env bash
# verify-restoration.sh — Deterministic validation of biosciences-* skill restoration
# Replaces LLM-based validation with machine-verifiable checks.
#
# Usage:  bash verify-restoration.sh
# Exit:   0 if all checks pass, 1 if any check fails
# Safe:   Idempotent, read-only, no side effects

set -uo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ANSI colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

# Counters
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Results accumulator for summary table
declare -a RESULTS=()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

pass() {
    local msg="$1"
    PASS_COUNT=$((PASS_COUNT + 1))
    RESULTS+=("PASS|${msg}")
    printf "  ${GREEN}PASS${RESET}  %s\n" "$msg"
}

fail() {
    local msg="$1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    RESULTS+=("FAIL|${msg}")
    printf "  ${RED}FAIL${RESET}  %s\n" "$msg"
}

warn() {
    local msg="$1"
    WARN_COUNT=$((WARN_COUNT + 1))
    RESULTS+=("WARN|${msg}")
    printf "  ${YELLOW}WARN${RESET}  %s\n" "$msg"
}

section() {
    printf "\n${BOLD}━━━ %s ━━━${RESET}\n" "$1"
}

# ---------------------------------------------------------------------------
# Skill pairs to verify (lifesciences source -> biosciences target)
# ---------------------------------------------------------------------------

PAIRS=(
    "graph-builder"
    "genomics"
    "proteomics"
    "pharmacology"
    "clinical"
    "reporting"
    "reporting-quality-review"
    "publication-pipeline"
)

# All 9 biosciences-* directories that must exist
ALL_BIO_SKILLS=(
    "biosciences-clinical"
    "biosciences-crispr"
    "biosciences-genomics"
    "biosciences-graph-builder"
    "biosciences-pharmacology"
    "biosciences-proteomics"
    "biosciences-publication-pipeline"
    "biosciences-reporting"
    "biosciences-reporting-quality-review"
)

# MCP gateway tools expected per skill (pipe-delimited within each entry)
declare -A MCP_TOOLS
MCP_TOOLS[graph-builder]="hgnc_search_genes|hgnc_get_gene|uniprot_get_protein|chembl_search_compounds|string_search_proteins|string_get_interactions|opentargets_get_target|opentargets_get_associations|clinicaltrials_search_trials|clinicaltrials_get_trial|wikipathways_get_pathways_for_gene|chembl_get_compound"
MCP_TOOLS[genomics]="hgnc_search_genes|hgnc_get_gene|ensembl_search_genes|ensembl_get_gene|ensembl_get_transcript|entrez_search_genes|entrez_get_gene|entrez_get_pubmed_links"
MCP_TOOLS[proteomics]="uniprot_search_proteins|uniprot_get_protein|string_search_proteins|string_get_interactions|string_get_network_image_url|biogrid_search_genes|biogrid_get_interactions"
MCP_TOOLS[pharmacology]="chembl_search_compounds|chembl_get_compound|opentargets_get_target|pubchem_search_compounds|pubchem_get_compound|iuphar_search_ligands|iuphar_get_ligand"
MCP_TOOLS[clinical]="opentargets_search_targets|opentargets_get_target|opentargets_get_associations|clinicaltrials_search_trials|clinicaltrials_get_trial|clinicaltrials_get_trial_locations"

# ===========================================================================
# CHECK 1: File Existence
# ===========================================================================

section "1. File Existence Check"

for skill in "${ALL_BIO_SKILLS[@]}"; do
    skill_md="${SKILLS_DIR}/${skill}/SKILL.md"
    if [[ -f "$skill_md" ]]; then
        pass "${skill}/SKILL.md exists"
    else
        fail "${skill}/SKILL.md MISSING"
    fi
done

# Additional file: publication-pipeline/references/agent-prompts.md
agent_prompts="${SKILLS_DIR}/biosciences-publication-pipeline/references/agent-prompts.md"
if [[ -f "$agent_prompts" ]]; then
    pass "biosciences-publication-pipeline/references/agent-prompts.md exists"
else
    fail "biosciences-publication-pipeline/references/agent-prompts.md MISSING"
fi

# ===========================================================================
# CHECK 2: Line Count Verification (biosciences >= lifesciences)
# ===========================================================================

section "2. Line Count Verification (biosciences >= lifesciences)"

for pair in "${PAIRS[@]}"; do
    ls_file="${SKILLS_DIR}/lifesciences-${pair}/SKILL.md"
    bs_file="${SKILLS_DIR}/biosciences-${pair}/SKILL.md"

    if [[ ! -f "$ls_file" ]]; then
        warn "lifesciences-${pair}/SKILL.md not found (legacy already cleaned up?) — skipping line count"
        continue
    fi
    if [[ ! -f "$bs_file" ]]; then
        fail "biosciences-${pair}/SKILL.md not found — cannot compare line counts"
        continue
    fi

    ls_lines=$(wc -l < "$ls_file")
    bs_lines=$(wc -l < "$bs_file")

    if [[ "$bs_lines" -ge "$ls_lines" ]]; then
        pass "biosciences-${pair} line count: ${bs_lines} >= ${ls_lines} (lifesciences)"
    else
        fail "biosciences-${pair} line count: ${bs_lines} < ${ls_lines} (lifesciences) — content may be truncated"
    fi
done

# ===========================================================================
# CHECK 3: Stale Reference Check (no "lifesciences" in biosciences-* files)
# ===========================================================================

section "3. Stale Reference Check (zero 'lifesciences' in biosciences-* files)"

stale_total=0
for skill in "${ALL_BIO_SKILLS[@]}"; do
    skill_dir="${SKILLS_DIR}/${skill}"
    if [[ ! -d "$skill_dir" ]]; then
        continue
    fi
    # Search all files in the biosciences skill directory for "lifesciences"
    stale_count=$(grep -r -c "lifesciences" "$skill_dir" 2>/dev/null | awk -F: '{s+=$NF} END {print s+0}')
    if [[ "$stale_count" -eq 0 ]]; then
        pass "${skill}: zero 'lifesciences' references"
    else
        fail "${skill}: ${stale_count} stale 'lifesciences' reference(s) found"
        # Show the offending lines for debugging
        grep -rn "lifesciences" "$skill_dir" 2>/dev/null | head -5 | while IFS= read -r line; do
            printf "        %s\n" "$line"
        done
        stale_total=$((stale_total + stale_count))
    fi
done

if [[ "$stale_total" -eq 0 ]]; then
    pass "Global: zero stale references across all biosciences-* skills"
else
    fail "Global: ${stale_total} total stale 'lifesciences' references"
fi

# ===========================================================================
# CHECK 4: MCP Gateway Check (mcp__biosciences-mcp__ present in 5 skills)
# ===========================================================================

section "4. MCP Gateway Tool References"

for skill_key in graph-builder genomics proteomics pharmacology clinical; do
    bs_file="${SKILLS_DIR}/biosciences-${skill_key}/SKILL.md"
    if [[ ! -f "$bs_file" ]]; then
        fail "biosciences-${skill_key}/SKILL.md not found — cannot check MCP refs"
        continue
    fi

    # Check for the gateway prefix
    gateway_count=$(grep -c "mcp__biosciences-mcp__" "$bs_file" 2>/dev/null || true)
    if [[ "$gateway_count" -gt 0 ]]; then
        pass "biosciences-${skill_key}: ${gateway_count} mcp__biosciences-mcp__ references"
    else
        fail "biosciences-${skill_key}: zero mcp__biosciences-mcp__ references — gateway migration incomplete"
    fi

    # Check each expected tool
    IFS='|' read -ra expected_tools <<< "${MCP_TOOLS[$skill_key]}"
    missing_tools=()
    for tool in "${expected_tools[@]}"; do
        if ! grep -q "mcp__biosciences-mcp__${tool}" "$bs_file" 2>/dev/null; then
            missing_tools+=("$tool")
        fi
    done

    expected_count=${#expected_tools[@]}
    found_count=$((expected_count - ${#missing_tools[@]}))

    if [[ ${#missing_tools[@]} -eq 0 ]]; then
        pass "biosciences-${skill_key}: all ${expected_count} expected gateway tools present"
    else
        fail "biosciences-${skill_key}: ${found_count}/${expected_count} tools found, missing: ${missing_tools[*]}"
    fi
done

# ===========================================================================
# CHECK 5: Section Heading Preservation (## headings from lifesciences in biosciences)
# ===========================================================================

section "5. Section Heading Preservation"

for pair in "${PAIRS[@]}"; do
    ls_file="${SKILLS_DIR}/lifesciences-${pair}/SKILL.md"
    bs_file="${SKILLS_DIR}/biosciences-${pair}/SKILL.md"

    if [[ ! -f "$ls_file" ]]; then
        warn "lifesciences-${pair}/SKILL.md not found — skipping heading check"
        continue
    fi
    if [[ ! -f "$bs_file" ]]; then
        fail "biosciences-${pair}/SKILL.md not found — cannot check headings"
        continue
    fi

    # Extract ## headings, normalize whitespace, sort
    ls_headings=$(grep -E '^##\s' "$ls_file" | sed 's/^##\s*//' | sort)
    bs_headings=$(grep -E '^##\s' "$bs_file" | sed 's/^##\s*//' | sort)

    missing_headings=()
    while IFS= read -r heading; do
        [[ -z "$heading" ]] && continue
        if ! echo "$bs_headings" | grep -qF "$heading"; then
            missing_headings+=("$heading")
        fi
    done <<< "$ls_headings"

    total_headings=$(echo "$ls_headings" | grep -c . || true)

    if [[ ${#missing_headings[@]} -eq 0 ]]; then
        pass "biosciences-${pair}: all ${total_headings} section headings preserved"
    else
        fail "biosciences-${pair}: missing headings: ${missing_headings[*]}"
    fi
done

# ===========================================================================
# CHECK 6: Cross-Skill Reference Check (graph-builder -> reporting, publication-pipeline)
# ===========================================================================

section "6. Cross-Skill Reference Check"

gb_file="${SKILLS_DIR}/biosciences-graph-builder/SKILL.md"
if [[ -f "$gb_file" ]]; then
    if grep -q "biosciences-reporting" "$gb_file" 2>/dev/null; then
        pass "biosciences-graph-builder references biosciences-reporting"
    else
        fail "biosciences-graph-builder does NOT reference biosciences-reporting"
    fi

    if grep -q "biosciences-publication-pipeline" "$gb_file" 2>/dev/null; then
        pass "biosciences-graph-builder references biosciences-publication-pipeline"
    else
        fail "biosciences-graph-builder does NOT reference biosciences-publication-pipeline"
    fi
else
    fail "biosciences-graph-builder/SKILL.md not found — cannot check cross-references"
fi

# ===========================================================================
# CHECK 7: Legacy Cleanup Check (lifesciences-* should not exist)
# ===========================================================================

section "7. Legacy Cleanup Check"

legacy_dirs=()
for pair in "${PAIRS[@]}"; do
    ls_dir="${SKILLS_DIR}/lifesciences-${pair}"
    if [[ -d "$ls_dir" ]]; then
        legacy_dirs+=("lifesciences-${pair}")
    fi
done

# Also check lifesciences-crispr
if [[ -d "${SKILLS_DIR}/lifesciences-crispr" ]]; then
    legacy_dirs+=("lifesciences-crispr")
fi

if [[ ${#legacy_dirs[@]} -eq 0 ]]; then
    pass "All lifesciences-* directories have been removed"
else
    warn "Legacy directories still present (${#legacy_dirs[@]}): ${legacy_dirs[*]}"
    printf "        (This is a warning, not a failure — remove when ready)\n"
fi

# ===========================================================================
# CHECK 8: biosciences-crispr integrity (preserved as-is, no lifesciences refs)
# ===========================================================================

section "8. biosciences-crispr Integrity"

crispr_file="${SKILLS_DIR}/biosciences-crispr/SKILL.md"
if [[ -f "$crispr_file" ]]; then
    crispr_stale=$(grep -c "lifesciences" "$crispr_file" 2>/dev/null || true)
    if [[ "$crispr_stale" -eq 0 ]]; then
        pass "biosciences-crispr/SKILL.md: zero 'lifesciences' references"
    else
        fail "biosciences-crispr/SKILL.md: ${crispr_stale} stale 'lifesciences' reference(s)"
    fi
else
    fail "biosciences-crispr/SKILL.md MISSING"
fi

# ===========================================================================
# CHECK 9: agent-prompts.md stale reference check
# ===========================================================================

section "9. Publication Pipeline — agent-prompts.md"

if [[ -f "$agent_prompts" ]]; then
    ap_stale=$(grep -c "lifesciences" "$agent_prompts" 2>/dev/null || true)
    if [[ "$ap_stale" -eq 0 ]]; then
        pass "agent-prompts.md: zero 'lifesciences' references"
    else
        fail "agent-prompts.md: ${ap_stale} stale 'lifesciences' reference(s)"
        grep -n "lifesciences" "$agent_prompts" 2>/dev/null | head -5 | while IFS= read -r line; do
            printf "        %s\n" "$line"
        done
    fi
else
    fail "agent-prompts.md not found"
fi

# ===========================================================================
# Summary
# ===========================================================================

section "SUMMARY"

total=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT))

printf "\n"
printf "  %-8s %s\n" "Total:" "$total checks"
printf "  ${GREEN}%-8s${RESET} %s\n" "Passed:" "$PASS_COUNT"
printf "  ${RED}%-8s${RESET} %s\n" "Failed:" "$FAIL_COUNT"
printf "  ${YELLOW}%-8s${RESET} %s\n" "Warnings:" "$WARN_COUNT"
printf "\n"

# Detailed results table
printf "${BOLD}%-6s  %-70s${RESET}\n" "Status" "Check"
printf "%-6s  %-70s\n" "------" "----------------------------------------------------------------------"
for result in "${RESULTS[@]}"; do
    status="${result%%|*}"
    msg="${result#*|}"
    case "$status" in
        PASS) printf "${GREEN}%-6s${RESET}  %s\n" "$status" "$msg" ;;
        FAIL) printf "${RED}%-6s${RESET}  %s\n" "$status" "$msg" ;;
        WARN) printf "${YELLOW}%-6s${RESET}  %s\n" "$status" "$msg" ;;
    esac
done

printf "\n"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
    printf "${RED}${BOLD}RESULT: %d check(s) FAILED${RESET}\n" "$FAIL_COUNT"
    exit 1
else
    printf "${GREEN}${BOLD}RESULT: ALL CHECKS PASSED${RESET}"
    if [[ "$WARN_COUNT" -gt 0 ]]; then
        printf " ${YELLOW}(%d warning(s))${RESET}" "$WARN_COUNT"
    fi
    printf "\n"
    exit 0
fi
