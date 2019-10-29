/**
 * This class is responsible for querying custom metadata (TriggerValidationRule__mdt, TriggerLogic__mdt or TriggerFieldDefault__mdt)
 * and creating instances of classes defined in ApexClass__c field.
 */
public with sharing class MetadataDefinedTriggerClasses {
    @TestVisible private static List<SObject> mockResponse;

    /**
     * @param customMetadata Type of custom metadata to query TriggerValidationRule__mdt/TriggerLogic__mdt/TriggerFieldDefault__mdt
     * @param tc Current Trigger Context
     * @param instances Empty list of desired result type ex. `new List<TriggerValidationRule> ()`
     *
     * @return New instances of classes defined in ApexClass__c field of the custom metadata.
     * @throws TypeException if Type.newInstance() failed.
     */
    public static List<Object> getInstances(SObjectType customMetadata, TriggerContext tc, List<Object> instances) {
        for (SObject setting : getCustomMetadataRecords(customMetadata, String.valueOf(tc.sObjectType), tc.operationType.name())) {
            try {
                Type ruleClass = Type.forName((String) setting.get('ApexClass__c'));
                instances.add(ruleClass.newInstance());

            } catch (Exception ex) {
                throw new TypeException('Apex class defined in custom metadata "' +
                        customMetadata + '.' + setting.get('DeveloperName') + '"' +
                        ' is invalid. Please check if corresponding class is public and implements correct interface.'
                );
            }
        }

        return instances;
    }

    private static List<SObject> getCustomMetadataRecords(SObjectType customMetadata, String sObjectType, String triggerOperation) {
        if (mockResponse != null) {
            return mockResponse;

        } else {
            return Database.query(
                    'SELECT ApexClass__c, DeveloperName'
                            + ' FROM ' + customMetadata
                            + ' WHERE IsEnabled__c = TRUE'
                            + ' AND SObject__c = :sObjectType'
                            + ' AND Trigger__c = :triggerOperation'
                            + ' ORDER BY Order__c NULLS LAST'
            );
        }
    }
}