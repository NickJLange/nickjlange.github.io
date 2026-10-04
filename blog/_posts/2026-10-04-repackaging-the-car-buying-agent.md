---
title: "Repackaging the Car Buying Agent: From Personal Hack to Pluggable MCP Skill"
date: 2026-10-04
---

Over the summer, I built a set of scripts and agentic tools to negotiate the purchase of a new family vehicle. We just locked in our reservation at our target Out-The-Door (OTD) number. With the deal done, the natural temptation is to let the code rot in a private directory.

Instead, I spent the weekend doing what every engineer knows they *should* do, but rarely has the discipline to complete: **repackaging an ad-hoc personal automation hack into a production-grade, open-source skill that anyone can run.**

Here are the architectural lessons learned while making an AI negotiation agent truly portable across different email backends, model providers, and agent frameworks.

---

## 1. The Trap of Hardcoded Agent Assumptions

When you write scripts for yourself, you take shortcuts:
- My first name (`Nick`) was baked into agent behavioral system prompts.
- My Firefox Relay email mask was hardcoded in negotiation templates.
- Our local Yonkers/Westchester 8.38% sales tax and statutory doc fee caps were embedded in Python calculation functions.
- The outbound drafting client assumed an active Superhuman Mail MCP server, and inbound message triage depended on my private, home-hosted MsgVault server.

To make this usable by anyone who isn’t me, step one was aggressive decoupling:

```json
// config/buyer_profile.json
{
  "first_name": "Jane",
  "full_name": "Jane Doe",
  "email": "buyer@example.com",
  "location": "Hartford, CT area",
  "zip_code": "06103",
  "sales_tax_rate": 0.0635,
  "capped_doc_fee": 325.0,
  "dmv_fee_estimate": 250.0
}
```

By extracting all personal data into a structured `BuyerProfile` dataclass and parameterizing the master outreach template, the agent's behavioral instructions (`AGENTS.md`) transformed from brittle personal rules into **generalized negotiation heuristics**:
1. *Always anchor to the Opening Floor Bid OTD (never MSRP).*
2. *Always back up the bid with a verified competitor benchmark URL.*
3. *Never volunteer internal justifications (travel logistics, personal budgets) to dealerships.*
4. *Sign strictly using the configured first name.*

---

## 2. Pluggable Comms: Superhuman vs. Gmail MCP

Not everyone uses Superhuman. Many people want standard Gmail; others want to test the pipeline in dry-run mode before connecting any credentials.

I refactored the communication layer into an abstract `EmailClient` with pluggable backends:
- **`SuperhumanClient`**: Uses the official Superhuman Mail MCP (`create_or_update_draft`).
- **`GmailMcpClient`**: Interacts with the standard Gmail MCP server (`create_draft`, `list_messages`).
- **`MockEmailClient`**: Prints drafts to the terminal and saves them to local files for testing without external services.

```python
# Automatic transport resolution
backend = os.getenv("EMAIL_BACKEND", "auto")
if backend == "auto":
    if os.getenv("SUPERHUMAN_AUTH"):
        client = SuperhumanClient()
    elif os.getenv("GMAIL_AUTH") or os.getenv("GMAIL_MCP_URL"):
        client = GmailMcpClient()
    else:
        client = MockEmailClient()
```

### Making Inbound Triage Optional
Originally, the triage script crashed if my self-hosted MsgVault server was unreachable. But for a public skill, indexed inbound search is a luxury, not a requirement.

If MsgVault is configured, the pipeline searches historical email threads. If it’s omitted, the pipeline falls back to Gmail MCP search or gracefully skips triage with an informative log. No crashes, no hard dependencies.

---

## 3. Dual-Agent Cross-Compatibility: Antigravity & Hermes

Agent skill standards are still fragmented. Google's Antigravity environment uses `.agents/skills/<name>/SKILL.md` with specific tool bindings, while Nous Research’s [Hermes-Agent](https://github.com/NousResearch/Hermes-Agent) uses `~/.hermes/skills/<name>/SKILL.md` with `${HERMES_SKILL_DIR}` variable interpolation.

Rather than maintaining two parallel implementations, we authored a universal `SKILL.md`:
- YAML frontmatter declaring version, license, and Hermes metadata tags.
- Command execution wrappers that gracefully resolve the active directory:
  ```bash
  python3 "${HERMES_SKILL_DIR:-scripts}/pipeline.py" report
  ```
- A dedicated installer script (`scripts/install_hermes_skill.sh`) that symlinks the repository directly into `~/.hermes/skills/car_deal_pipeline`.

Whether invoked by an Antigravity prompt or a local Hermes terminal session (`hermes "Find top deals on Grand Highlander"`), the underlying engine executes identically.

---

## 4. Cybersecurity & The Human-in-the-Loop Guarantee

When releasing an agent skill that interacts with external third parties (dealership CRMs), you have to think like a security engineer. How do you prevent an autonomous agent from spamming 50 dealerships or agreeing to a bad contract?

We established strict governance boundaries in our `PR_MANIFEST.md`:
1. **Zero Autonomous Sending:** The skill is strictly limited to staging **drafts** via MCP. It has no access to a `send` method. A human must physically review the worksheet and click "Send".
2. **Zero Financial Delegation:** The agent has no access to payment rails, deposit forms, or credit authorization tools.
3. **Deterministic Math:** LLMs are notorious for hallucinating arithmetic. All tax calculations, doc fee caps, and OTD spreads are computed in deterministic Python functions (`pricing.py`), with the LLM acting purely as a summarizer and strategist.

---

## Wrapping Up

Building an AI agent to solve a personal headache is fun. But taking the time to audit the code, eliminate hardcoded paths, isolate sensitive data, and package it into a multi-framework skill is where real software engineering happens.

If you are looking to purchase a car without dealing with dealer games, grab the skill, drop in your numbers, and let the code do the fighting.
