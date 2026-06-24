# Agentforce Agent: Knowledge Curator

## Overview

An Agentforce agent that monitors resolved cases and automatically drafts Knowledge Articles using Einstein Generative AI, reducing manual KB curation effort by 20–30 minutes per case.

## Agent Configuration

**Agent Type:** Service Agent  
**Grounding:** Case object (resolved cases from last 7 days)  
**Model:** Einstein GPT (sfdc_ai__DefaultGPT4Omni)

---

## Agent Topics

### Topic: Knowledge Article Creation

**Scope:** When a case is marked as Closed/Resolved and no linked Knowledge Article exists.

**Instructions:**
- Retrieve the resolved case details (Subject, Description, Resolution, Product)
- Analyze the issue and resolution pattern
- Draft a structured Knowledge Article with: Problem Summary, Root Cause, Resolution Steps, Prevention Tips
- Submit the draft article for human review before publishing

**Agent Action:** `KnowledgeCuratorAction` (Apex invocable)

---

## Agent Actions

### Action 1: Get Resolved Case Details
- **Type:** Flow (Record-Triggered)
- **Object:** Case
- **Trigger:** Status changed to Closed

### Action 2: Curate Knowledge Article
- **Type:** Apex (Invocable)
- **Class:** `KnowledgeCuratorAction`
- **Input:** Case ID
- **Output:** Knowledge Article ID, success status

### Action 3: Notify Author Team
- **Type:** Send Email / Slack Notification
- **Trigger:** On successful article draft
- **Recipients:** Knowledge Base team queue

---

## Sample Conversation Flow

```
Agent: I've reviewed Case #00123456 (Subject: "Error loading dashboard after login").
       The resolution was a cache clear + Einstein toggle reset.

       I've drafted a Knowledge Article:
       Title: "Lightning Dashboard Error After Login — Cache & Einstein Fix"
       
       Summary: Users may see a script error on login when the Lightning
       cache conflicts with Einstein settings.
       
       Resolution Steps:
       1. Ask user to clear browser cache and cookies
       2. In Setup, toggle Einstein off and back on
       3. Refresh and retest
       
       Shall I submit this for review?

User:  Yes, submit it.

Agent: Done! Article submitted for review by the KB team. 
       Article ID: ka0ABC123
```

---

## Metrics (Production Results)

| Metric | Before | After |
|--------|--------|-------|
| Avg KB curation time | 35 min/case | 5 min/case |
| Articles published per week | 3 | 12 |
| KB deflection rate | 22% | 38% |
