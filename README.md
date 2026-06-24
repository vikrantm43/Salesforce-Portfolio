# Vikrant Mahantare — Salesforce Portfolio

**Senior Salesforce Technical Consultant & Platform Developer | 7+ Years**

[![Agentforce Specialist](https://img.shields.io/badge/Certified-Agentforce%20Specialist-00A1E0?style=flat-square&logo=salesforce)](https://trailhead.salesforce.com)
[![Platform Developer I](https://img.shields.io/badge/Certified-Platform%20Developer%20I-00A1E0?style=flat-square&logo=salesforce)](https://trailhead.salesforce.com)
[![Service Cloud Consultant](https://img.shields.io/badge/Certified-Service%20Cloud%20Consultant-00A1E0?style=flat-square&logo=salesforce)](https://trailhead.salesforce.com)
[![AI Associate](https://img.shields.io/badge/Certified-AI%20Associate-00A1E0?style=flat-square&logo=salesforce)](https://trailhead.salesforce.com)

---

## About

Senior Salesforce developer and consultant with 7+ years delivering enterprise-grade solutions across **Service Cloud, Sales Cloud, and Experience Cloud**. Currently at Salesforce as a Technical Consultant & Developer Support Engineer.

75%+ of my tenure is programming-focused: Apex, LWC, JavaScript (ES6+), REST/SOAP/Bulk API integrations, and CI/CD automation. Deep expertise in **Einstein AI, Agentforce, Omnichannel routing**, and Data Cloud.

- **Email:** vikrantm43@gmail.com
- **LinkedIn:** [linkedin.com/in/vikrant-mahantare-807779107](https://www.linkedin.com/in/vikrant-mahantare-807779107/)

---

## Portfolio Projects

| # | Project | Tech | Highlights |
|---|---------|------|------------|
| 1 | [Account Health Dashboard LWC](#1-account-health-dashboard-lwc) | LWC, Apex, SOQL | Real-time KPI dashboard with dynamic charts |
| 2 | [Case Timeline Component](#2-case-timeline-component) | LWC, Lightning Message Service | Visual case activity timeline |
| 3 | [Pre-Chat Form — Digital Engagement](#3-pre-chat-form--digital-engagement) | LWC, MIAW | Custom pre-chat improving FCR rates |
| 4 | [Apex Trigger Framework](#4-apex-trigger-framework) | Apex, Design Patterns | Scalable handler-based trigger architecture |
| 5 | [REST API Integration Service](#5-rest-api-integration-service) | Apex, REST API, Named Credentials | Async callout with retry and error handling |
| 6 | [Agentforce Agent Action — Knowledge Curator](#6-agentforce-agent-action--knowledge-curator) | Agentforce, Apex, Einstein | AI-driven knowledge article workflow |
| 7 | [Omnichannel Capacity Utility](#7-omnichannel-capacity-utility) | Apex, Omnichannel | Dynamic capacity threshold management |

---

## 1. Account Health Dashboard LWC

**`force-app/main/default/lwc/accountDashboard`**

A real-time account health dashboard surfacing KPIs — open cases, opportunities, NPS score, and recent activity — using wire adapters and custom Apex controllers. Built for Service Cloud console apps.

**Key techniques:** `@wire`, `lightning/uiRecordApi`, LMS pub/sub, dynamic SOQL, `lightning-chart`

---

## 2. Case Timeline Component

**`force-app/main/default/lwc/caseTimeline`**

Visual timeline of all case activity — emails, calls, chatter, status changes — rendered as an interactive LWC. Uses Lightning Message Service to communicate with sibling components on the console.

**Key techniques:** LMS, `@wire(getRecord)`, Custom Events, CSS custom properties for theming

---

## 3. Pre-Chat Form — Digital Engagement

**`force-app/main/default/lwc/preChatForm`**

Custom pre-chat LWC for MIAW (Messaging for In-App and Web) that captures structured customer data before routing, improving first-contact resolution rates and reducing average handle time.

**Key techniques:** MIAW pre-chat API, `embeddedservice_flowlauncher`, data validation, custom routing attributes

---

## 4. Apex Trigger Framework

**`force-app/main/default/triggers` + `force-app/main/default/classes`**

Enterprise-grade trigger framework using the handler pattern with a custom metadata-driven bypass mechanism. Enforces single-trigger-per-object, separation of concerns, and 90%+ test coverage.

**Key techniques:** `TriggerHandler` base class, `CustomMetadata` bypass, Queueable chaining, bulkification

---

## 5. REST API Integration Service

**`force-app/main/default/classes/RestIntegrationService.cls`**

Generic async REST callout service with Named Credentials, retry logic, error logging to a custom object, and a mock framework for unit testing. Used in production Honda Malaysia integration.

**Key techniques:** `HttpRequest/HttpResponse`, `Queueable`, `Named Credentials`, mock HTTP callouts

---

## 6. Agentforce Agent Action — Knowledge Curator

**`force-app/main/default/agentforce`**

An invocable Apex action that powers an Agentforce agent to automatically draft, tag, and submit Knowledge Articles from resolved cases — reducing manual KB curation effort by 20–30 min per case.

**Key techniques:** `@InvocableMethod`, Einstein Generative AI API, Knowledge object, Prompt Builder

---

## 7. Omnichannel Capacity Utility

**`force-app/main/default/classes/OmnichannelCapacityUtil.cls`**

Utility class to dynamically query and adjust Omnichannel service channel capacity configurations based on real-time queue depth, used to optimize AHT and routing efficiency.

**Key techniques:** `ServiceChannel`, `AgentWork`, dynamic capacity updates, Scheduled Apex

---

## Certifications — 8 Active

| Certification | Status |
|---|---|
| Salesforce Certified Service Cloud Consultant | ✅ Active |
| Salesforce Certified Administrator | ✅ Active |
| Salesforce Certified Advanced Administrator | ✅ Active |
| Salesforce Certified Platform Developer I | ✅ Active |
| Salesforce Certified Platform App Builder | ✅ Active |
| Salesforce Certified Experience Cloud Consultant | ✅ Active |
| Salesforce Certified Agentforce Specialist | ✅ Active |
| Salesforce Certified AI Associate | ✅ Active |
| Salesforce Certified Platform Developer II | 🔄 In Progress |

---

## Tech Stack

```
Languages:      Apex · JavaScript (ES6+) · LWC · Aura · Visualforce · SOQL · SOSL
Platform:       Service Cloud · Sales Cloud · Experience Cloud · Data Cloud
AI:             Agentforce · Einstein Bots · Prompt Builder · Einstein Generative AI
Integration:    REST API · SOAP API · Bulk API · Named Credentials · Connected Apps
DevOps:         Git · Azure DevOps · SFDX · Copado · Flosum · VS Code
Testing:        Apex Test Classes (90%+) · Jest · Debug Logs
```
