---
name: contact-intel
description: Contact Intelligence & Strategy — full account intel, contact brief, and outreach drafts from live Salesforce data.
---

# Contact Intelligence & Strategy — /contact-intel

You are running the full account intelligence and outreach strategy workflow for a Salesforce Account Executive. Work through all phases in order. Do not skip ahead.

**Invoked as:** `/contact-intel [Account Name]`

---

## PHASE 0 — Identify Rep & Territory

Before doing anything else, run the following to identify who is running this skill:

Use the `getUserInfo` tool (Salesforce MCP) to retrieve the current user's full name, email, title, and profile.

Then ask:

> *"Hi [Rep First Name]! I see you're logged in as [Full Name] ([Email]). What territory or region are you covering? (e.g., English Speaking Caribbean, Brazil, DACH, Southern Cone, etc.)"*

Wait for the answer. Store the following for use in all subsequent phases:
- **Rep Name**: from getUserInfo
- **Rep Email**: from getUserInfo
- **Rep Title**: from getUserInfo (default to "Named Account Executive" if not found)
- **Territory**: from the rep's answer

If no account name was provided in the invocation, also ask for it now before proceeding.

---

---

## CRITICAL: How to Access Salesforce

**NEVER use the Claude_in_Chrome extension or any browser tool to access Salesforce data.**
**NEVER ask the rep to export a CSV or provide a screenshot.**
**ALWAYS use the Salesforce MCP tools directly via SOQL queries.**

The Salesforce MCP is already connected. Use the available MCP query tool (look for tools named `query`, `salesforce_query`, `soql`, or similar). If the MCP tool is not available, stop and say: *"The Salesforce MCP is not responding — please check that it is active in your Claude Code settings."* Do not fall back to Chrome or manual exports under any circumstances.

---

## PHASE 1 — Find & Confirm Account

```sql
SELECT Id, Name, Industry, NumberOfEmployees, AnnualRevenue,
       BillingCountry, BillingCity, Owner.Name, LastActivityDate
FROM Account
WHERE Name LIKE '%[AccountName]%'
LIMIT 10
```

If multiple records are returned, list them and ask the rep to confirm which one before proceeding. Once confirmed, store the `AccountId` for all subsequent queries.

Then pull open opportunities:

```sql
SELECT Id, Name, StageName, CloseDate, Amount,
       (SELECT Contact.Name, Role FROM OpportunityContactRoles LIMIT 3)
FROM Opportunity
WHERE AccountId = '[AccountId]' AND IsClosed = false
ORDER BY CloseDate ASC
```

---

## PHASE 2 — Pull Contact Intelligence

### Contacts

```sql
SELECT Id, Name, Title, Department, Email, Phone, MobilePhone,
       LastActivityDate, LeadSource, CreatedDate, Owner.Name
FROM Contact
WHERE AccountId = '[AccountId]'
ORDER BY LastActivityDate DESC NULLS LAST
LIMIT 50
```

Store all `ContactId` values and email addresses for the queries below.

### Tasks (last 24 months)

```sql
SELECT Id, Subject, Type, Status, ActivityDate, Description,
       Meaningful_Activity__c, Customer_Sentiment__c,
       Meeting_Outcome__c, Topic__c, Duration__c,
       Who.Name, Who.Id
FROM Task
WHERE WhoId IN ('[ContactId1]', '[ContactId2]', ...)
  AND ActivityDate >= LAST_N_MONTHS:24
ORDER BY ActivityDate DESC
LIMIT 200
```

- Prioritize records where `Meaningful_Activity__c = true`
- Flag `Customer_Sentiment__c` — Positive / Neutral / Negative
- Include `Meeting_Outcome__c` and `Topic__c` if populated
- Include `Duration__c` for calls
- If the account has more than 10 contacts, batch the `WhoId IN` clauses in groups of 10

### Events (last 24 months)

```sql
SELECT Id, Subject, Type, StartDateTime, EndDateTime, Description,
       Meeting_Type__c, Topic__c, Closed_Role__c,
       Who.Name, Who.Id
FROM Event
WHERE WhoId IN ('[ContactId1]', '[ContactId2]', ...)
  AND StartDateTime >= LAST_N_MONTHS:24
ORDER BY StartDateTime DESC
LIMIT 200
```

- Include `Meeting_Type__c` (discovery, demo, QBR, etc.) if populated
- Include `Closed_Role__c` — reveals the buyer role the contact played

### EmailMessage (last 24 months)

Run one query per contact email address:

```sql
SELECT Id, Subject, MessageDate, FromAddress, ToAddress,
       CcAddress, TextBody, Status
FROM EmailMessage
WHERE (ToAddress LIKE '%[contactemail]%' OR FromAddress LIKE '%[contactemail]%')
  AND MessageDate >= LAST_N_MONTHS:24
ORDER BY MessageDate DESC
LIMIT 20
```

- Direction: `FromAddress` matches contact email = Inbound. Otherwise = Outbound.
- Use `TextBody` for a 300-character snippet only — never reproduce the full body
- Check `CcAddress` for other contacts at the same account — note those relationships

### Opportunity Contact Roles

```sql
SELECT ContactId, Contact.Name, Role,
       Opportunity.Name, Opportunity.StageName,
       Opportunity.CloseDate, Opportunity.Amount, Opportunity.IsClosed,
       Opportunity.IsWon
FROM OpportunityContactRole
WHERE ContactId IN ('[ContactId1]', '[ContactId2]', ...)
```

---

## PHASE 3 — ZoomInfo / External Contacts

Before building strategy, ask:

> *"Do you have a ZoomInfo export or external contact list for [Account Name]? If so, paste it now and I'll cross-reference it against Salesforce, flag any new names, and fold them into the strategy."*

**STOP. Do not proceed to Phase 4 until the rep explicitly replies — yes, no, or a paste. Never assume a default answer or advance based on silence.**

If the rep provides a list:
- Cross-reference each name against the Salesforce contact list
- Flag names not already in Salesforce as **New / Not in CRM**
- Include them in the contact hierarchy with whatever data is available
- Note that they should be added to Salesforce before outreach begins

If the rep says no or skip, proceed to Phase 4.

---

## PHASE 4 — Discovery Questions

Ask these questions **one at a time**. After each question, **STOP and wait for the rep's answer before asking the next one.**

1. *What Salesforce products are you positioning? (If unsure, describe the account's challenges and I'll suggest the best fit.)*
2. *What is your current stage with this account? (Cold / Some contacts / Active opportunity)*
3. *Anything specific to factor in? (Recent news, known competitors, active initiatives, regulatory context, open renewal)*

You may skip a question only if the Salesforce data already provides a clear, unambiguous answer. When you skip, say so explicitly — e.g. *"Skipping Q1 — Salesforce shows an open Sales Cloud opportunity at Proposal stage."* Do not skip silently. If all three questions can be answered from Salesforce, state that before proceeding to Phase 5.

---

## PHASE 5 — Intel Summary

Present the following compact brief before building the strategy:

---

### [Account Name] — Contact Intelligence Brief

**Account:** [Industry] | [Employees] employees | [HQ City, Country] | Owner: [Owner Name]
**Open Opportunities:** [Name | Stage | Close Date | Amount — or "None"]
**Contacts found:** [total] | Active: [n] | Fading: [n] | Cold: [n] | Unknown: [n]

#### Active Contacts

> **[Full Name]** | [Title] | [Department]
> Email: [email] | Phone: [phone] | Mobile: [mobile]
> Last Touch: [date] — [type] — [one-sentence summary]
> Sentiment: [value] | Opp Roles: [list or "None"]
> **Reconnect angle:** [one sentence grounded in last interaction topic, outcome, or product discussed]

#### Fading Contacts *(7–12 months — Priority Reconnect)*

Same format as Active. Label each as **Priority Reconnect**.

#### Cold Contacts

> **[Full Name]** | [Title] | [Department]
> Email: [email] | Phone: [phone] | Mobile: [mobile]
> In Salesforce since: [date] | Last logged activity: [date or "never"]
> Opp Roles: [list or "None"]

#### Cautious Contacts *(negative sentiment or Closed Lost involvement)*

List separately. One sentence on what went wrong if known. Approach these last.

#### Missing Personas

Flag roles not present in the contact list — gaps to fill via ZoomInfo or LinkedIn:
- CIO / CTO / CDO
- CFO / VP Finance
- CHRO / Head of HR
- COO / VP Operations
- Procurement / Vendor Management
- IT Architecture or Infrastructure Lead
- Any role relevant to open opportunities

---

## PHASE 6 — Contact Hierarchy

Organize all contacts into three tiers:

- **Tier 1 — Economic Buyers:** Budget authority, C-level, final decision makers
- **Tier 2 — Champions:** Best entry points, highest internal leverage, most likely to sponsor
- **Tier 3 — Influencers & Validators:** Technical evaluators, department leads, gatekeepers

For each contact include:
- Full name and title
- Location (flag if in [Territory] — the rep's direct territory)
- Email and phone
- Product alignment (which Salesforce product maps to their role)
- Why they matter strategically
- Status: **Warm** (active/positive) or **Cold** (no recent touch or unknown)
- Last meaningful touchpoint (date + one-sentence summary) if available

Flag any important personas still missing that the rep should source externally (ZoomInfo, LinkedIn, referral).

---

## PHASE 7 — Contact Selection

Present a prioritized, numbered list of all contacts so the rep can choose who to include in the outreach sequence and drafts.

**Ordering:** Tier 2 (Champions) first — they are the best entry points. Then Tier 1 (Economic Buyers). Then Tier 3 (Influencers). Within each tier, order by status: Active → Fading → Cold. Cautious contacts appear last regardless of tier.

Display as a table:

| # | Name | Title | Tier | Status | Why prioritized |
|---|------|-------|------|--------|-----------------|
| 1 | [Name] | [Title] | Tier 2 | Active | [One sentence: last touch + why they matter strategically] |
| 2 | [Name] | [Title] | Tier 2 | Fading | [One sentence: reconnect angle based on last interaction] |
| 3 | [Name] | [Title] | Tier 1 | Cold | [One sentence: seniority + gap to fill] |
| … | … | … | … | … | … |

Flag contacts located within [Territory] with ★ in the # column.
Flag Cautious contacts with ⚠ and a brief note on what went wrong.

Then ask:

> *"Which contacts do you want to include in your outreach sequence and drafts? Reply with numbers (e.g., 1, 3, 4), a range (e.g., 1–4), or 'all'. I recommend starting with the top 3–4 Tier 2 contacts."*

Wait for the rep's selection before proceeding. All subsequent phases use only the selected contacts.

---

## PHASE 8 — Salesforce Solution Mapping

Based on the account's industry, size, business model, and the selected contacts:
- Suggest Salesforce products beyond what the rep mentioned that are a natural fit
- Map each suggestion to the right contact(s) from the selection
- Briefly explain the business case in the context of this specific account

---

## PHASE 9 — Outreach Sequence

Provide a week-by-week recommended sequence for the selected contacts only:
- Which to approach first and why
- Whether to lead bottom-up (champions first) or top-down (exec first) based on context
- How to use warm contacts as bridges to cold ones
- Any gatekeeper or EA contacts worth engaging first
- For Fading contacts: how to re-open naturally based on the last interaction topic or `Meeting_Outcome__c`

---

## PHASE 10 — Draft Outreach

For each selected contact, produce both:

**Email:**
- Subject line (compelling, role-specific, not generic)
- Body: formal, customer-facing tone
- Warm/Fading contacts: open by acknowledging the prior relationship and last topic discussed — do not treat them as cold outreach
- Cold contacts: open by introducing [Rep Name] as *"a Salesforce Account Executive focused on [industry] across [Territory]"*
- Lead with a relevant industry insight or pain point before mentioning any product
- Close with a soft, specific CTA (20–30 minute call)
- Sign off: **[Rep Name] / [Rep Title] | Salesforce / [Rep Email]**

**LinkedIn InMail:**
- Subject line (punchy, role-relevant)
- 3–4 sentences max
- Same intro positioning as email
- CTA: *"would love to reconnect"* for warm contacts, *"would love to connect"* for cold

### Deliver Drafts

After generating all email drafts, do the following for each selected contact:

**Step 1 — Create Gmail Draft**

Use the Gmail MCP to create a draft with:
- **To:** [contact email]
- **Subject:** [generated subject line]
- **Body:** [full email body as generated above]

If the Gmail MCP is not available, skip this step and note it to the rep.

**Step 2 — Send Slack DM confirmation**

Use `slack_search_users` to find the rep's Slack ID (search "[Rep Name]" or "[Rep Email]"), then send a single DM via `slack_send_message` summarizing all drafts created:

> *"✉️ Gmail drafts ready for [Account Name] — [n] contacts:*
>
> *1. [Contact Name] — [Subject line]*
> *2. [Contact Name] — [Subject line]*
> *...*
>
> *Each draft is pre-addressed and ready to send from your Gmail. Review and hit Send whenever you're ready."*

If Gmail MCP was unavailable, send the full email body for each contact in the DM so the rep can copy-paste directly from Slack.

---

## PHASE 11 — Follow-Up Cadence

Ask two questions and wait for both answers:
1. *"Which of the selected contacts have you sent outreach to? List them so I can schedule the follow-up check."*
2. *"Have you already received any responses or booked any meetings?"*

Once confirmed, do three things. The follow-up check fires in **7 days**.

### 1. Create the scheduled follow-up check

Use `mcp__scheduled-tasks__create_scheduled_task` to schedule a task firing in 7 days. The task runs in a new session with no memory of this conversation, so embed the account name and full contact list directly into the prompt.

Use this prompt template (fill in all bracketed values before creating the task):

---
You are running a 7-day outreach follow-up check for [Rep Name], [Rep Title] at Salesforce covering [Territory].

**Account:** [Account Name]
**Outreach sent to:**
- [Contact Name] | [Title] | [email]
- [Contact Name] | [Title] | [email]

**STEP 1 — Query Salesforce for responses in the last 7 days**

For each contact email, run:
```sql
SELECT Id, Subject, MessageDate, FromAddress, ToAddress, Status
FROM EmailMessage
WHERE (ToAddress LIKE '%[email]%' OR FromAddress LIKE '%[email]%')
  AND MessageDate >= LAST_N_DAYS:7
ORDER BY MessageDate DESC
LIMIT 10
```

Also query Tasks and Events. First look up ContactIds:
```sql
SELECT Id, Name FROM Contact
WHERE Email IN ('[email1]', '[email2]', ...)
```
Then:
```sql
SELECT Id, Subject, Type, ActivityDate, Status, Who.Name
FROM Task
WHERE WhoId IN ('[ContactId1]', '[ContactId2]', ...)
  AND ActivityDate >= LAST_N_DAYS:7
ORDER BY ActivityDate DESC
```
```sql
SELECT Id, Subject, StartDateTime, Who.Name
FROM Event
WHERE WhoId IN ('[ContactId1]', '[ContactId2]', ...)
  AND StartDateTime >= LAST_N_DAYS:7
ORDER BY StartDateTime DESC
```

**Important:** Email results depend on whether messages were manually logged or EAC is active. If no EmailMessage records appear for a contact, flag it as ❓ Unknown — do not assume no response.

**STEP 2 — Classify each contact:**
- ✅ Responded — inbound email found, or new task/event logged after outreach date
- ⏳ No response — no new activity of any kind
- ❓ Unknown — no email logged; EAC may not be active

**STEP 3 — Send a Slack DM to [Rep Name]**

Use `slack_search_users` to find the rep's Slack user ID (search "[Rep Name]" or their email "[Rep Email]"), then send a DM via `slack_send_message` with:
- Account name and a reminder of when outreach was sent
- A summary table: Contact | Status | Last Activity Found
- Recommended next steps per contact: follow up, try a different channel, try a different persona, or escalate
- If ❓ Unknown contacts appear, note that activating EAC would make this check reliable

---

### 2. Send an immediate Slack confirmation to the rep

Use `slack_search_users` to find the rep's Slack ID (search "[Rep Name]" or "[Rep Email]"), then send a DM via `slack_send_message`:

> *"Follow-up check scheduled for [date 7 days from today] for [Account Name]. I'll ping you with a response summary and recommended next steps on that date. Note: response detection relies on emails being logged in Salesforce — if EAC isn't active yet, some results may show as Unknown."*

### 3. Check in on return

Every time the rep returns to this session or mentions this account:
- Ask for status of outreach to each selected contact
- Note any new contacts or relationships surfaced
- Suggest whether to escalate to Tier 1 or open a new product thread

---

## Contact Classification Rules

Assign status based on **meaningful activity** (`Meaningful_Activity__c = true`, or most recent Task/Event if flag is not populated) in the last 12 months:

- **Active** — 1+ meaningful touchpoints in the last 12 months
- **Fading** — last meaningful touchpoint was 7–12 months ago
- **Cold** — no meaningful activity in 12+ months, or never contacted
- **Unknown** — no activity data found in Salesforce

**Relationship Signal** (based on `Customer_Sentiment__c` and activity pattern):
- **Positive** — last sentiment logged was positive, or contact has been inbound/responsive
- **Neutral** — no sentiment data or mixed signals
- **Cautious** — negative sentiment logged, or contact was part of a Closed Lost deal

For Active/Fading contacts, write a one-sentence activity summary:
> *"Last touched [date] via [type] — [Meeting_Outcome__c or Topic__c or email subject]. Sentiment: [value]."*

For Cold contacts: *In Salesforce since [CreatedDate] | last logged activity: [date or "never"].*

---

## Standing Rules

- **Never auto-advance past a phase that requires rep input.** Every question must receive an explicit reply before the next phase begins. Never infer a default from silence, from data already retrieved, or from a plausible assumption. If no reply is received, re-state the question.
- Contacts located within [Territory] are the rep's direct territory — always flag with ★ and prioritize them
- If `Meaningful_Activity__c` is not populated on any records, fall back to all tasks/events by date and note the gap
- If the account has 20+ contacts, surface the top 15 by recency and seniority; note how many were excluded
- Never reproduce full email bodies — 300-character snippets only
- Never use Claude_in_Chrome, browser navigation, or screenshot tools for any part of this skill
- Never ask the rep to export a CSV or share a screenshot as a workaround — if MCP is unavailable, say so explicitly
- If Salesforce returns no contacts, say so clearly and ask the rep to provide a ZoomInfo export or manual contact list before continuing
- Flag data quality issues (duplicate records, non-company emails, missing phone numbers, stale titles)
- If a field is empty, label it `—` rather than omitting it
- Keep all output scannable: bold labels, bullet points, no dense paragraphs
- Highlight the single best recommendation when presenting options
- Be formal in customer-facing drafts, casual in day-to-day conversation with the rep
- Never assume — ask if context is missing
