# Trigger Handler
*Custom Metadata-driven orchestrator for Apex Trigger Logic*

---
## Documentation
Extension to the standard version of the Trigger Handler Framework. All standard features - such as Logic toggle are available.

Metadata Trigger Handler is a Dependency-Injection oriented pattern that moves orchestration from the code of sObject specific Trigger Handler classes to the
Custom Metadata records.  
Each record defines SObject, Trigger operation, Apex Class name and optional Parameters and Custom Permission.  
Framework initializes and parametrizes each of the defined classes and executes its code.   
![th-mdt-full.png](/img/th-mdt-full.png)

Apex Classes defined in the custom metadata must implement TriggerLogic interface:
```apex
public interface TriggerLogic {
    void setParameters(String parameters);
    void execute(List<SObject> records, TriggerContext ctx);
}
```

Example of a class that copies BillingCountry to ShippingCountry when it's blank.
```apex
public class AccountShippingCountryFiller implements TriggerLogic {

    public void execute(List<Account> records, TriggerContext ctx) {
        for (Account acc : records) {
            if (ctx.isChanged(acc, Account.BillingCountry) && String.isBlank(acc.ShippingCountry)) {
                acc.ShippingCountry = acc.BillingCountry;
            }
        }
    }

    public void setParameters(String parameters) {}
}
```

To run Metadata Trigger Handler, define your trigger as follows:
```apex
trigger AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new MetadataTriggerHandler());
}
```

#### Pros
- No merge conflicts in multi-work-stream environments.
- Ability to enable/disable/reorder logic without deployment.
- Enforces SOLID Principles and unified trigger interfaces.
- Introduces per-class configuration layer which can be enriched with Feature Management, performance profiling, and other features.

#### Cons
- Custom Metadata is an additive deployment, which means that deleting logic from the source of truth does not remove it from the org.
  Depending on the situation, CI/CD pipeline or the lack of it, missed manual steps — it's possible to have unwanted trigger logic running in the org, without
  being aware of it.
- It's harder to navigate through the trigger code. Developers will have to jump between custom metadata page and IDE to check what's executed.
- Static Analysis may report false-positive unused classes, that are only referenced in the custom metadata.

#### Recommendation
Based on my experience, it's easier to work with the code version of the trigger handler, hence why I prefer to use it on small to medium-sized projects.  
However, configuration-based also has a lot of merits-especially on enterprise-tier orgs. If you pick configuration-based trigger handler, make sure to also
read through Cons.


---
### Common Logic
`TriggerCommons` class is a container for generic reusable building blocks of your org.  
Consider your requirements in terms of generic puzzles that can be parameterized to fulfill the requirement:
- if there's a need to copy field from one to another
- or set default value
- or validate if the field is not empty or has a predefined value

We can create a generic class which will fulfill the requirement and parametrize it to our needs.

I've included a few of those generic classes to serve as an example:

##### TriggerCommons.DefaultField
- `sObjectField:value`

Sets the field on record if it's blank.

##### TriggerCommons.CopyField
- `sourceSObjectField:targetSObjectField`

Copies field value from source to the target field.

##### TriggerCommons.ExecuteFlow
- The first line is `namespace__FlowDeveloperName` - or just `FlowDeveloperName` for local namespace
- All subsequent lines are additional flow parameters in `name:value` format.
- Flow should have input SObject variables named `record` and `old`.

Executes Auto-launched flow with `record` and `old` parameters and any additionally defined parameters.
See `Set Capital` custom metadata on the image above for reference.

---
### CLI

Deploy with the following script:
```bash
sf project deploy start -l RunLocalTests -o <sfdxOrgAlias> \
  -d "force-app/commons/triggerHandler" \ 
  -d "force-app/commons/triggerHandlerMdt"
```