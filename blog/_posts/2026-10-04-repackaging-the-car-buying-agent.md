---
title: "Repackaging the Car Buying Agent: From Personal Hack to Pluggable MCP Skill"
date: 2026-10-04
---

We just locked in a car reservation at our target Out-The-Door (OTD) price using an agentic negotiation pipeline. With the deal done, I spent the weekend turning an ad-hoc personal automation hack into a portable, open-source skill.

Here are the key architectural takeaways:

---

### 1. Decoupling Personal Assumptions

Ad-hoc scripts bake in personal shortcuts: hardcoded email masks, local sales tax rates, and private home servers. 

We decoupled all buyer state into a standalone `config/buyer_profile.json`:

```json
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

Behavioral guidelines now enforce generalized heuristics: anchor to the national floor OTD, cite live competitor URLs, and sign only with `first_name`.

---

### 2. Pluggable MCP Comms

Not everyone uses the same tools. The comms and telemetry layer now abstracts transport:
- **Market Telemetry:** Queries nationwide dealer inventory and comps via the **Visor.vin API / MCP server**.
- **Outbound:** Stages drafts via **Superhuman MCP**, **Gmail MCP**, or an offline **Mock** client.
- **Inbound:** Searches local indexed mail via **MsgVault MCP** if available, falling back gracefully to Gmail search or skipping triage without runtime crashes.

---

### 3. Dual-Agent & Security Guardrails

The skill is cross-compatible across **Google Antigravity** (`.agents/skills/car_deal_pipeline`) and Nous Research's **[Hermes-Agent](https://github.com/NousResearch/hermes-agent)** via a one-step installer:

```bash
./scripts/install_hermes_skill.sh
```

**Guardrails:**
- **Zero Autonomous Sending:** All correspondence is strictly staged as drafts.
- **Zero Financial Delegation:** No payment or deposit access.
- **Deterministic Math:** Tax and OTD calculations live in Python (`pricing.py`), preventing LLM arithmetic hallucination.

Grab the skill at [5L-Labs/agent-skills](https://github.com/5L-Labs/agent-skills).
