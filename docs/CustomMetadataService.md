# Custom Metadata Service
*Deploy Custom Metadata from Apex.*
[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/blob/master/force-app/commons/schema/CustomMetadataService.cls)

```bash
sf project deploy start -m "ApexClass:CustomMetadataService*" -o sfdxOrg
```

---
## Documentation

Simple utility class that can be used to deploy custom metadata from apex code or from asynchronous apex.  
It's so small, that it can be used straight from the Anonymous Apex without deploying the class.

```apex | Usage
CustomMetadataService.deploy(new List<Country__mdt>{
    new Country__mdt(DeveloperName = 'USA', Active__c = true),
    new Country__mdt(DeveloperName = 'France', Active__c = true),
    new Country__mdt(DeveloperName = 'Poland', Active__c = true)
});
```

<details>
    <summary>Deployment from Anonymous Apex</summary>

To use it without deployment in anonymous apex, just copy-paste
the [deploy method of the class](https://github.com/pkozuchowski/Apex-Opensource-Library/blob/master/force-app/commons/schema/CustomMetadataService.cls) at the
end of the script.

```apex
deploy(new List<Country__mdt>{
    new Country__mdt(DeveloperName = 'USA', Active__c = true),
    new Country__mdt(DeveloperName = 'France', Active__c = true),
    new Country__mdt(DeveloperName = 'Poland', Active__c = true)
});


public static Id deploy(List<SObject> customMetadataRecords) {
    Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();

    for (SObject record : customMetadataRecords) {
        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        customMetadata.fullName = ('' + record.getSObjectType()).remove('__mdt') + '.' + record.get('DeveloperName');
        customMetadata.label = (String) record.get('Label');

        Map<String, Object> populatedFields = record.getPopulatedFieldsAsMap().clone();
        populatedFields.remove('Id');
        populatedFields.remove('Label');
        populatedFields.remove('DeveloperName');

        for (String field : populatedFields.keySet()) {
            Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
            customField.field = field;
            customField.value = populatedFields.get(field);

            customMetadata.values.add(customField);
        }

        mdContainer.addMetadata(customMetadata);
    }

    return Metadata.Operations.enqueueDeployment(mdContainer, null);
}
```
</details>