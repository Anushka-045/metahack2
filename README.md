# Compliance Monitor — Data Pipeline
### Anushka's Component | OpenEnv Compatible

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
compliance_anushka/
│
├── app.py                     ← HuggingFace Spaces entry point (required)
├── anushka_server.py          ← FastAPI server with all endpoints
├── merge_bridge.py            ← Drop-in integration patch for Gargi's env
├── openenv.yaml               ← OpenEnv spec (tasks, actions, rewards)
├── validate_anushka.py        ← Pre-submission validation (run before push)
├── Dockerfile                 ← HF Spaces ready (non-root, port 7860)
├── requirements_anushka.txt   ← Python dependencies
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

---

## API Endpoints

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
pip install -r requirements_anushka.txt

# 2. Set API key (only needed for LLM features)
export ANTHROPIC_API_KEY=sk-ant-...

# 3. Start server
python anushka_server.py
# → http://localhost:7861

# 4. Run validation (all 12 checks must pass)
python validate_anushka.py
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
cp -r /path/to/compliance_anushka/* .
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
