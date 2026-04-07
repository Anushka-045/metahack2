<<<<<<< HEAD
# 🛡️ Compliance Monitor — OpenEnv Environment

**Team:** RunTimers | Gargi Monga · RunTimers Pandey  
**Hackathon:** Meta × Scaler OpenEnv Round 1  
**Deadline:** 8 April 2026, 11:59 PM IST

---

## Overview

Companies store compliance rules in PDF documents that are rarely read until violations occur. This environment simulates a **real-world AI compliance monitoring agent** that:

- Scans company records (employees, contracts, transactions)
- Detects policy violations against structured compliance rules
- Assigns severity (Low / Medium / High / Critical)
- Generates plain-English violation explanations
- Suggests specific remediation actions
- Flags contradictions between policy rules

**Domain:** Enterprise Legal/Compliance — directly applicable to any data-driven organization managing regulatory risk.

---

## Environment Design

### Action Space (6 actions)

| Action | Parameters | Description |
|--------|-----------|-------------|
| `check_record` | `record_id` | Inspect a record and identify applicable rules |
| `flag_violation` | `record_id`, `rule_id`, `reason` | Flag a record as violating a rule (+0.4 reward if correct) |
| `assign_severity` | `violation_id`, `severity` | Set Low/Medium/High/Critical (+0.2 if correct) |
| `generate_explanation` | `violation_id`, `explanation` | Plain-English violation reason (+0.2 based on quality) |
| `suggest_fix` | `violation_id`, `fix` | Actionable remediation step (+0.2 based on quality) |
| `resolve_conflict` | `rule_id_a`, `rule_id_b`, `resolution` | Resolve contradicting rules (+0.3 if known conflict) |

### Observation Space

```json
{
  "records": [...],            // company records in scope
  "rules": [...],              // active compliance rules
  "violations": [...],         // flagged violations (with severity, explanation, fix)
  "conflicts": [...],          // identified rule conflicts
  "checked_record_ids": [...], // records already inspected
  "episode_step": 0,
  "max_steps": 60,
  "done": false,
  "total_reward": 0.0,
  "task_id": "task_medium"
}
```

### Reward Function

```
R = detection(+0.4) + severity(+0.2) + explanation(+0.2) + fix(+0.2)
  - false_positive_penalty(-0.1 per FP)
  + conflict_resolution(+0.3 per known conflict resolved)
```

- **Shaped reward** — agent gets signal at every sub-action, not just at episode end
- **Partial credit** — adjacent severity level earns 0.1 instead of 0.2
- **Quality scoring** — explanations and fixes are scored on actionability and relevance

---

## Tasks

### Task 1 — Easy: Single Record vs Single Rule
- 1 employee record, 1 rule
- Binary score: 0.0 or 1.0
- Max 10 steps
- Tests: basic violation detection

### Task 2 — Medium: Multi-Record Multi-Rule
- 10 records, 5 rules
- Partial credit scoring
- Max 60 steps
- Tests: scanning, prioritization, severity assignment

### Task 3 — Hard: Full DB + Conflicting Policies
- 30+ records (employees, contracts, transactions), 12 rules (including 2 contradicting)
- Weighted scoring: detection(35%) + severity(25%) + explanation(20%) + fix(10%) + conflict(10%)
- Max 200 steps
- Genuinely challenges frontier models: requires multi-hop reasoning, policy interpretation, conflict resolution

=======
# Compliance Monitor — Data Pipeline
### RunTimers's Component | OpenEnv Compatible

---

## What This Does

This is the **data pipeline half** of the Compliance Monitor project. It:

- Reads uploaded policy PDFs and extracts raw text
- Converts policy text into structured compliance rules using Claude LLM
- Hosts a realistic company database (employees, contracts, transactions) in SQLite
- Scans every record against every rule and detects violations automatically
- Explains each violation in plain English, ranks by severity, and suggests a fix
- Compares two policy PDFs and flags contradictions between them
- Logs compliance scores over time and alerts when scores deteriorate
- Serves a real-time monitoring dashboard

At the **merge point**, Gargi's OpenEnv environment calls `/openenv/records` and `/openenv/rules` from this server, replacing dummy data with real database records — no other code changes needed.

---

## File Structure

```
compliance_runtimers/
│
├── app.py                     ← HuggingFace Spaces entry point (required)
├── runtimers_server.py          ← FastAPI server with all endpoints
├── merge_bridge.py            ← Drop-in integration patch for Gargi's env
├── openenv.yaml               ← OpenEnv spec (tasks, actions, rewards)
├── validate_runtimers.py        ← Pre-submission validation (run before push)
├── Dockerfile                 ← HF Spaces ready (non-root, port 7860)
├── requirements_runtimers.txt   ← Python dependencies
│
├── database/
│   ├── company_db.py          ← SQLite database
│   └── default_rules.py       ← 10 compliance rules matching Gargi's schema
│
├── pipeline/
│   ├── pdf_ingestion.py       ← PDF extractor + LLM rule extractor + explainer
│   ├── scanner.py             ← Rule-based violation detector (no LLM needed)
│   └── trend_tracker.py       ← Score history + deterioration alerts
│
└── static/
    └── dashboard.html         ← Monitoring UI (served at /)
```

>>>>>>> f833466bb1f82a8e9b6048cd6f99075012b7bb25
---

## API Endpoints

<<<<<<< HEAD
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/reset` | Start new episode. Body: `{"task_id": "task_easy", "seed": 42}` |
| `POST` | `/step` | Take action. Body: `{"action": {...}}` |
| `GET` | `/state` | Get current environment state |
| `GET` | `/tasks` | List available tasks |
| `GET` | `/health` | Health check |

---

## Setup & Running

### Local

```bash
pip install -r requirements.txt
python server.py
# Server runs on http://localhost:7860
```

### Docker

```bash
docker build -t compliance-monitor .
docker run -p 7860:7860 compliance-monitor
```

### Inference (baseline agent)

```bash
export API_BASE_URL="https://api.openai.com/v1"
export MODEL_NAME="gpt-4o-mini"
export HF_TOKEN="your-hf-or-openai-key"
export ENV_URL="http://localhost:7860"

python inference.py
```

The inference script:
- Runs all 3 tasks sequentially
- Falls back to deterministic heuristic if LLM is unavailable
- Emits structured `[START]` / `[STEP]` / `[END]` JSON logs to stdout
- Completes in < 5 minutes on a 2vCPU / 8GB machine

---

## Pre-Submission Checklist

- [x] HF Space deploys and responds to `/reset` with HTTP 200
- [x] `openenv.yaml` present with full spec
- [x] Typed Pydantic models for all observations and actions
- [x] `step()` / `reset()` / `state()` endpoints implemented
- [x] 3 tasks with graders producing scores in 0.0–1.0
- [x] Graders are deterministic and reproducible
- [x] Reward function provides shaped (non-sparse) signal
- [x] `inference.py` in root directory, uses OpenAI Client
- [x] `[START]` / `[STEP]` / `[END]` log format implemented
- [x] `API_BASE_URL`, `MODEL_NAME`, `HF_TOKEN` env vars used
- [x] Dockerfile builds and runs
- [x] Runtime < 20 min on 2vCPU / 8GB

---

## Contact

help_openenvhackathon@scaler.com
=======
| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Monitoring dashboard UI |
| GET | `/health` | Health check — always 200 when up |
| GET | `/summary` | Compliance health overview |
| GET | `/records` | All database records |
| GET | `/rules` | All compliance rules |
| POST | `/ingest/pdf` | Upload PDF, extract rules via LLM |
| POST | `/ingest/compare_pdfs` | Compare two PDFs for contradictions |
| POST | `/scan` | Full database scan |
| POST | `/scan/record/{id}` | Scan a single record |
| POST | `/scan/conflicts` | Detect rule conflicts |
| POST | `/explain` | LLM explanation + fix for a violation |
| GET | `/trend` | Compliance score history + alerts |
| GET | `/violations` | All logged violations |
| GET | `/openenv/records` | Records in Gargi's env format |
| GET | `/openenv/rules` | Rules in Gargi's env format |

---

## Ground Truth Violations

| Record | Rule | Severity | Issue |
|--------|------|----------|-------|
| EMP001 | RULE001 | Critical | No background check |
| EMP001 | RULE002 | High | NDA not signed |
| EMP010 | RULE003 | Critical | Age 16 (underage worker) |
| EMP005 | RULE004 | Medium | Training incomplete |
| EMP015 | RULE005 | High | Contractor with access level 5 |
| CON003 | RULE006 | High | $150k contract, no dual approval |
| CON008 | RULE007 | Critical | EU contract, no GDPR clause |
| TXN004 | RULE008 | High | $48k self-approved transaction |
| TXN009 | RULE009 | Medium | $12k transaction, no receipt |
| EMP020 | RULE010 | High | GDPR-scope country, NDA missing |

---

## Observation Space

```json
{
  "records": [{"id": "EMP001", "type": "employee", ...}],
  "rules": [{"id": "RULE001", "category": "HR", "severity_hint": "Critical", ...}],
  "task_id": "task_easy",
  "step": 0,
  "done": false
}
```

## Action Space

| Action | Reward | Parameters |
|--------|--------|------------|
| `check_record` | 0.0 | `record_id` |
| `flag_violation` | +0.4 | `record_id`, `rule_id`, `reason` |
| `assign_severity` | +0.2 | `violation_id`, `severity` |
| `generate_explanation` | +0.2 | `violation_id`, `explanation` |
| `suggest_fix` | +0.2 | `violation_id`, `fix` |
| `resolve_conflict` | +0.2 | `rule_id_a`, `rule_id_b`, `resolution` |

---

## Environment Variables

| Variable | Required For | Description |
|----------|-------------|-------------|
| `ANTHROPIC_API_KEY` | PDF ingestion, LLM explanations | Claude API key |
| `DB_PATH` | Optional | SQLite path (default: `compliance_db.sqlite`) |
| `PIPELINE_URL` | Gargi's merge_bridge | URL of this server |
| `PORT` | Deployment | Port (default 7861 local, 7860 HF Spaces) |

---

## Local Setup

```bash
# 1. Install deps
pip install -r requirements_runtimers.txt

# 2. Set API key (only needed for LLM features)
export ANTHROPIC_API_KEY=sk-ant-...

# 3. Start server
python runtimers_server.py
# → http://localhost:7861

# 4. Run validation (all 12 checks must pass)
python validate_runtimers.py
```

---

## Docker

```bash
docker build -t compliance-pipeline .
docker run -p 7860:7860 -e ANTHROPIC_API_KEY=sk-ant-... compliance-pipeline
```

---

## HuggingFace Spaces Deployment

**Step 1** — Create a new Space at huggingface.co/new-space → choose Docker SDK

**Step 2** — Add secret in Space Settings → Repository secrets:
```
Name: ANTHROPIC_API_KEY   Value: sk-ant-...
```

**Step 3** — Push code:
```bash
git clone https://huggingface.co/spaces/YOUR_USERNAME/YOUR_SPACE_NAME
cd YOUR_SPACE_NAME
cp -r /path/to/compliance_runtimers/* .
git add . && git commit -m "feat: compliance pipeline" && git push
```

**Step 4** — Verify:
```bash
curl https://YOUR_USERNAME-YOUR_SPACE_NAME.hf.space/health
# → {"status": "ok", ...}
```

---

## Merge with Gargi's Environment

Add 3 lines to Gargi's `environment.py`:

```python
from merge_bridge import load_real_data, MERGE_AVAILABLE

def reset(self, task_id="task_easy", seed=42):
    if MERGE_AVAILABLE:
        records, rules = load_real_data(task_id)
    else:
        records, rules = DUMMY_RECORDS, DUMMY_RULES  # existing fallback
    # ... rest unchanged ...
```

Then set:
```bash
export PIPELINE_URL=https://YOUR_USERNAME-YOUR_SPACE_NAME.hf.space
```

Done. No other code changes needed.
>>>>>>> f833466bb1f82a8e9b6048cd6f99075012b7bb25
