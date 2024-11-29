# Localization
*Dynamically retrieve Custom Labels, Field and Picklist labels for given locale.*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/tree/master/force-app/commons/localization)

```bash
sf project deploy start \
-d force-app/commons/localization \
-d force-app/commons/dataStructures/BitSet.cls \
-d force-app/commons/dataStructures/BitSetTest.cls \
-d force-app/commons/schema/Picklist.cls \
-d force-app/commons/schema/PicklistTest.cls \
-o sfdxOrg
```

---
# Documentation

Localization is a niche utility that can dynamically fetch translated labels:
- Custom Labels
- Field Labels
- Picklist Options
- Can fetch in bulk
- Can fetch for given locale

The primary targets are Aura, LWC and Remote methods.

**Note!**  
Data is fetched through the VisualForce Page.getContent() method, which counts as callout.  
Consider this when using Localization class in Triggers context.



## Custom Labels
Retrieves translated labels of SObject Fields.

###### Signatures
```apex
public static String getCustomLabel(String labelName);
public static String getCustomLabel(String labelName, String locale);
@AuraEnabled public static Map<String, String> getCustomLabels(String[] labelNames);
@AuraEnabled public static Map<String, String> getCustomLabelsWithLocale(String[] labelNames, String locale);
```
##### Parameters
- `String labelName` - Custom Label API Name.
- `String locale` - Locale key of the translation to retrieve. Same format as User's LocaleSidKey or LanguageLocaleKey (en/en_US/de/de_De/ru etc.)

##### Return Value
- `String` - Translated custom label.
- `Map<String,String>` Map where keys are Custom Label API names and map's value are translated picklist label

##### Usage
<details>
	<summary>Get labels in bulk for given locale</summary>

```apex
Map<String, String> labels = Localization.getCustomLabelsWithLocale(new List<String>{
	'COM_Toast_Success',
	'COM_Toast_Info'
}, 'pl');
```

```json
{
	"COM_Toast_Info": "Info",
	"COM_Toast_Success": "Sukces"
}
```
</details>



## Field Labels
Retrieves translated labels of SObject Fields.

###### Signatures
```apex
public static String getFieldLabel(String field);
public static String getFieldLabel(String field, String locale);
@AuraEnabled public static Map<String, String> getFieldLabels(String[] fields);
@AuraEnabled public static Map<String, String> getFieldLabelsWithLocale(String[] fields, String locale);
```
##### Parameters
- `String fields` - Field API Name with SObject Name in `'SObjectType.SObjectField'` format - `'Account.Type'`.
- `String locale` - Locale key of the translation to retrieve. Same format as User's LocaleSidKey or LanguageLocaleKey (en/en_US/de/de_De/ru etc.)

##### Return Value
- `String` - Translated field label
- `Map<String,String>` Map where keys are field API name and map's value are translated labels.

##### Usage
<details>
	<summary>Get labels in bulk for given locale</summary>

```apex
Map<String, String> labels = Localization.getFieldLabelsWithLocale(new List<String>{
	'Account.Type',
	'Opportunity.StageName'
}, 'pl');
```

```json
{
	"Account.Type": "Typ konta",
	"Opportunity.StageName": "Etap"
}
```
</details>



## Picklist Options Labels
Retrieves translated labels of picklist options for given field and returns them as map `<Value, Label>`.

###### Signatures
```apex
@AuraEnabled public static Map<String, String> getPicklistLabels(String fields, String locale);
@AuraEnabled public static Map<String, Map<String, String>> getPicklistsLabels(String fields[], String locale);
```
##### Parameters
- `String fields` - Field API Name with SObject Name in `'SObjectType.SObjectField'` format - `'Account.Type'`.
- `String locale` (optional) — Locale key of the translation to retrieve. Same format as User's LocaleSidKey or LanguageLocaleKey (en/en_US/de/de_De/ru etc.)

##### Return Value
- `Map<String,String>` Map where keys are picklist API values and map's value are translated picklist label.
- `Map<String, Map<String, String>` - Map of Maps, where first key is SObjectField in `Account.Type` format and second key is Picklist API Value.

##### Usage

<details>
	<summary>Single Picklist</summary>

```apex
Map<String, String> labels = Localization.getPicklistLabels('Opportunity.StageName', 'pl');
```
```json
{
	"Prospecting": "Prospecting",
	"Qualification": "Qualification",
	"Needs Analysis": "Needs Analysis",
	"Value Proposition": "Value Proposition",
	"Id. Decision Makers": "Id. Decision Makers",
	"Perception Analysis": "Perception Analysis",
	"Proposal/Price Quote": "Proposal/Price Quote",
	"Negotiation/Review": "Negotiation/Review",
	"Closed Won": "Closed Won",
	"Closed Lost": "Closed Lost"
}
```
</details>

<details>
	<summary>Bulk</summary>

```apex
Map<String, Map<String, String>> labels = Localization.getPicklistsLabels(new List<String>{
	'Account.Type',
	'Opportunity.StageName'
}, 'pl');
```
```json
{
	"Account.Type": {
		"Prospect": "Prospect",
		"Customer - Direct": "Customer - Direct",
		"Customer - Channel": "Customer - Channel",
		"Channel Partner / Reseller": "Channel Partner / Reseller",
		"Installation Partner": "Installation Partner",
		"Technology Partner": "Technology Partner",
		"Other": "Other"
	},
	"Opportunity.StageName": {
		"Prospecting": "Prospecting",
		"Qualification": "Qualification",
		"Needs Analysis": "Needs Analysis",
		"Value Proposition": "Value Proposition",
		"Id. Decision Makers": "Id. Decision Makers",
		"Perception Analysis": "Perception Analysis",
		"Proposal/Price Quote": "Proposal/Price Quote",
		"Negotiation/Review": "Negotiation/Review",
		"Closed Won": "Closed Won",
		"Closed Lost": "Closed Lost"
	}
}
```
</details>