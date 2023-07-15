# Custom Metadata Service
[Source](../force-app/commons/schema/CustomMetadataService.cls)

Simple utility class that can be used to deploy custom metadata from apex code or from asynchronous apex.  
It's so small, that it can be used straight from the Anonymous Apex without deploying the class.

### Usage:
```apex
CustomMetadataService.deploy(new List<Country__mdt>{
    new Country__mdt(DeveloperName = 'USA', Active__c = true),
    new Country__mdt(DeveloperName = 'France', Active__c = true),
    new Country__mdt(DeveloperName = 'Poland', Active__c = true)
});
```

To use it without deployment, just copy-paste the [content of class file](../force-app/commons/schema/CustomMetadataService.cls) at the beginning of the script above.
