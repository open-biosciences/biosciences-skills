# Pre-Commit Security Review Team — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a 4-agent pre-commit security review team available as a standalone skill and integrated into the migration workflow.

**Architecture:** A Coordinator agent identifies repos with staged changes, dispatches 3 specialist agents in parallel (Secrets Scanner, Path Sanitizer, Config Validator), collects findings, and produces a tiered pass/fail verdict. CRITICAL/HIGH findings block commits; MEDIUM/LOW are warnings.

**Tech Stack:** Claude Code skills (SKILL.md), Task tool with general-purpose subagents, Bash (git status, grep patterns)

---

### Task 1: Create the Security Review Skill

**Files:**
- Create: `biosciences-skills/.claude/skills/security-review/SKILL.md`

**Step 1: Write the SKILL.md file**

Create the skill with frontmatter matching the project convention (see `biosciences-clinical/SKILL.md` for format). The skill must contain:

1. **Frontmatter** — name: `security-review`, description triggers on "security scan", "pre-commit check", "review for secrets"

2. **Coordinator logic** — instructions for the orchestrating agent:
   - Scan all repos under `/home/donbr/open-biosciences/` for staged git changes (`git status -s`)
   - Collect the list of changed/new files per repo
   - If no staged changes found, scan all untracked files as well
   - Dispatch 3 specialist agents in parallel via Task tool (subagent_type: general-purpose)
   - Collect results from all 3
   - Produce verdict using severity tiers

3. **Secrets Scanner agent prompt** — detailed instructions:
   - Grep patterns: `api[_-]?key\s*=\s*[^\s]`, `secret\s*=`, `password\s*=`, `token\s*=\s*[^\s]`, `AKIA[A-Z0-9]{16}`, `sk-[a-zA-Z0-9]{20,}`, `ghp_[a-zA-Z0-9]{36}`, `gho_[a-zA-Z0-9]{36}`, `eyJ[a-zA-Z0-9]` (JWT), base64 patterns that look like keys
   - Must distinguish real values from placeholders (`your_*_here`, `placeholder`, `example`)
   - Must distinguish env variable NAME references (`$API_KEY`, `${API_KEY}`) from actual values
   - Severity: CRITICAL for real API keys/tokens, HIGH for real passwords/connection strings
   - Output: list of findings with file:line, severity, and what was found

4. **Path Sanitizer agent prompt** — detailed instructions:
   - Grep patterns: `/home/[a-zA-Z]+/`, hardcoded absolute paths outside repo, internal hostnames, private IP addresses (`10\.\d+`, `192\.168\.`, `172\.(1[6-9]|2[0-9]|3[01])\.`)
   - Check for `.env` files (not `.env.example`) being staged
   - Severity: HIGH for `.env` files staged, MEDIUM for private paths, LOW for stale predecessor references
   - Output: list of findings with file:line, severity, and what was found

5. **Config Validator agent prompt** — detailed instructions:
   - Check `.env.example` files: all values must be placeholders (no real keys)
   - Check `.mcp.json` files: no embedded credentials
   - Check `.gitignore`: must exclude `.env`, `*.env`, `__pycache__`, `.pyc`
   - Check for any config files with production URLs containing auth tokens
   - Severity: HIGH for real values in .env.example, MEDIUM for missing gitignore rules
   - Output: list of findings with file:line, severity, and what was found

6. **Verdict logic**:
   - BLOCK if any CRITICAL or HIGH findings → list all blocking findings, refuse to proceed
   - PASS WITH WARNINGS if only MEDIUM/LOW findings → list warnings, allow commit
   - CLEAN PASS if no findings → confirm safe to commit

7. **Output format** — the standardized report format from the design doc

**Step 2: Verify skill frontmatter is valid**

Run: `head -10 biosciences-skills/.claude/skills/security-review/SKILL.md`
Expected: Starts with `---`, contains `name:` and `description:`, ends with `---`

**Step 3: Commit**

```bash
cd biosciences-skills
git add .claude/skills/security-review/SKILL.md
git commit -m "feat: add pre-commit security review skill"
```

---

### Task 2: Integrate into Migration Team Skill

**Files:**
- Modify: `.claude/skills/migration-team/SKILL.md` (lines 214-220, Step 8)

**Step 1: Insert security review step between Step 7 and Step 8**

Renumber Step 8 → Step 9. Insert new Step 8:

```markdown
### Step 8: Pre-Commit Security Review (Program Director)

Before committing, run the security review team:

1. **Invoke** the `/security-review` skill, OR dispatch the security review agents directly:
   - Launch 3 agents in parallel (Secrets Scanner, Path Sanitizer, Config Validator)
   - Each agent scans all files staged for commit across target repos
2. **Review findings**:
   - CRITICAL/HIGH → STOP. Do not commit. Fix the issue first.
   - MEDIUM/LOW → Report to user as warnings. Proceed with commit.
   - CLEAN → Proceed with commit.
3. **If blocked**: Report the blocking findings and ask user how to proceed.
```

Update the old Step 8 (now Step 9) header to say "Step 9".

**Step 2: Verify the skill reads correctly**

Run: `grep -n "Step [0-9]" .claude/skills/migration-team/SKILL.md`
Expected: Steps 0-9 in order, Step 8 is "Pre-Commit Security Review"

**Step 3: Commit**

```bash
cd /home/donbr/open-biosciences
git add .claude/skills/migration-team/SKILL.md
git commit -m "feat: integrate security review into migration workflow as Step 8"
```

---

### Task 3: Test the Security Review Skill

**Step 1: Run the skill against current repo state**

Invoke `/security-review` or manually dispatch the 3 agents against biosciences-program (which has the known `.env` file and private paths in migration-tracker.md).

Expected findings:
- Secrets Scanner: CLEAN (`.env` is gitignored, not staged)
- Path Sanitizer: MEDIUM — private paths in migration-tracker.md and .mcp.json
- Config Validator: CLEAN — `.env.example` has only placeholders, `.gitignore` excludes `.env`
- Verdict: PASS WITH WARNINGS

**Step 2: Verify blocking behavior**

Create a temporary test file with a fake API key, stage it, run the scan:
```bash
echo "OPENAI_API_KEY=sk-test1234567890abcdef" > /tmp/test-secret.txt
```
Pass this path to the Secrets Scanner agent.
Expected: CRITICAL finding, verdict = BLOCK

**Step 3: Clean up test file**

```bash
rm /tmp/test-secret.txt
```

---

### Task 4: Push All Changes

**Step 1: Push biosciences-skills**

```bash
cd biosciences-skills && git push origin main
```

**Step 2: Push migration-team skill update**

```bash
cd /home/donbr/open-biosciences && git add .claude/skills/migration-team/SKILL.md
# Note: this is in the parent workspace, check if it's in a git repo
# If not, this file lives wherever the skill is stored
```

**Step 3: Verify both repos are clean**

```bash
cd biosciences-skills && git status -s
```
Expected: clean
