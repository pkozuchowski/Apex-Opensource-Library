# Picklist
*Access Picklist metadata*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/blob/master/force-app/commons/schema/Picklist.cls)

```bash
sf project deploy start -m ApexClass:Picklist* -m ApexClass:BitSet* -o sfdxOrg
```

---
## Documentation
This class provides easy access to picklist field values, labels or controlling values.

```apex | Usage
Picklist p = new Picklist(Account.Type);

String default = p.getDefaultValue();
String[] values = p.getValues();
SelectOption[] options = p.getSelectOptions();//(VisualForce)
Picklist.Entry[] entries = p.getEntries();//(Aura Enabled)
```

### Methods

- `Boolean isRestricted();` - returns `true` if picklist is restricted
- `Boolean isDependent();`- returns `true` if picklist is dependent picklist
- `Boolean containsValue(String value);` - returns `true` if picklist contains given value
- `String getDefaultValue();`- returns picklist's default value
- `List<String> getValues();` - returns list of all values
- `List<String> getLabels();` - returns list of all labels
- `String getLabel(String value);` - returns label for given value
- `List<Entry> getEntries();` - returns list of @AuraEnabled entries. Redundant in LWC.
- `List<SelectOption> getSelectOptions();` - returns list of SelectOption for Visualforce
- `Map<String, String> getEntriesMap();` - returns Map<Value, Label>
- `Map<Object, Entry[]> getEntriesByControllingValue();` - returns Picklist entries by controlling values (picklist API value or checkbox true/false)

```apex | Picklist.Entry class
public class Entry {
    @AuraEnabled public String label { get; private set; }
    @AuraEnabled public String value { get; private set; }
    @AuraEnabled public Boolean defaultValue { get; private set; }
    private String validFor;
    private Boolean active;
}
```