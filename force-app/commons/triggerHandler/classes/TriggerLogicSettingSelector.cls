/**
 * This class is responsible for querying custom metadata (TriggerLogic__mdt)
 * and creating instances of classes defined in ApexClass__c field.
 */
public with sharing class TriggerLogicSettingSelector {
    @TestVisible private static List<TriggerLogic__mdt> mockResponse;

    /**
     * @param customMetadata Type of custom metadata to query TriggerValidationRule__mdt/TriggerLogic__mdt/TriggerFieldDefault__mdt
     * @param tc Current Trigger Context
     * @param instances Empty list of desired result type ex. `new List<TriggerValidationRule> ()`
     *
     * @return New instances of classes defined in ApexClass__c field of the custom metadata.
     * @throws TypeException if Type.newInstance() failed.
     */
    public static List<Object> getInstances(String logicType, TriggerContext tc, List<Object> instances) {
        for (SObject setting : getCustomMetadataRecords(logicType, String.valueOf(tc.sObjectType), tc.operationType.name())) {
            try {
                Type ruleClass = Type.forName((String) setting.get('ApexClass__c'));
                instances.add(ruleClass.newInstance());

            } catch (Exception ex) {
                throw new TypeException('Apex class defined in custom metadata TriggerLogic__mdt.' + setting.get('DeveloperName') + '"'
                        + ' is invalid. Please check if corresponding class is public and implements correct interface.'
                );
            }
        }

        return instances;
    }

    private static List<SObject> getCustomMetadataRecords(String type, String sObjectType, String triggerOperation) {
        if (mockResponse != null) {
            return mockResponse;
        } else {
            return [
                    SELECT ApexClass__c, DeveloperName
                    FROM TriggerLogic__mdt
                    WHERE IsEnabled__c = TRUE
                    AND Type__c = :type
                    AND SObject__c = :sObjectType AND Trigger__c = :triggerOperation
                    ORDER BY Order__c ASC NULLS LAST
            ];
        }
    }
}