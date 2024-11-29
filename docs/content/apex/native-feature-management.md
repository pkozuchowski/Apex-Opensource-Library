# Native Feature Management
*Model for handling Feature Flags only with native Salesforce*

---
# Documentation
![FeatureManagement.png](/img/FeatureManagement.svg)

A simple model for implementing Feature Management using Custom Permissions, Permission Sets, and Permission Set Groups.

Each Feature Flag will be represented as a separate Custom Permission, which can be natively referenced in Apex, LWC and any declarative tool - Validation
Rules, Flows, Formulas, and Page Builders.

Feature Custom Permission will be first assigned to the **Preview Features** Permission Set.
This permission set contains experimental features, that we want to enable only for QA and UAT users at first.
After deployment to production, we can assign this permission set to the first batch of users for **Partial Rollout**.

When the feature gains traction, and the team gains confidence, Custom Permission can be moved to **Global Features** permission set
(or Persona-specific feature permission set) for **Global Rollout**,

**Global Features** permission set should be assigned to all Permission Set Groups representing personas in your organization — in this example, Dealer and
Dealer Leadership.


### Pros
- Custom Permissions are natively supported in code and declarative tools
- Single source of truth for Feature Flags
- Can be used in DevOps to deploy metadata without cherry-picking feature branches
- Partial & Global Rollout
- Different rollout granularity:
    - Selected users
    - Selected group of users
    - Selected Personas
    - Globally for everyone

### Cons
- It's not possible to designate Feature Flags to work only on test records without additional filtering configuration