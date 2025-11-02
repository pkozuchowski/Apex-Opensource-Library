// SPDX-License-Identifier: MIT
// Copyright 2019 Piotr Kożuchowski

/**
 * This class is responsible for querying custom metadata (TriggerAction__mdt)
 * and creating instances of classes defined in ApexClass__c field.
 */
public virtual inherited sharing class TriggerLogicSelector {

    /**
     * @param ctx Trigger Context of running trigger
     * @return Trigger Actions for currently executing trigger
     */
    public List<TriggerAction> getTriggerActions(SObjectType sObjectType, String operation) {
        List<TriggerAction> classes = new List<TriggerAction>();

        for (TriggerAction__mdt setting : getCustomMetadataRecords(sObjectType, operation)) {
            try {
                if (isPermitted(setting)) {
                    Type ruleClass = Type.forName(setting.ApexClass__c);
                    TriggerAction logic = (TriggerAction) JSON.deserialize(setting.Parameters__c ?? '{}', ruleClass);
                    classes.add(logic);
                }
            } catch (Exception ex) {
                System.debug(ex.getMessage());
                System.debug(ex.getStackTraceString());
                TypeException typeException = new TypeException(
                    'Apex class defined in custom metadata TriggerAction__mdt.' + setting.DeveloperName
                    + ' (' + setting.ApexClass__c + ') is invalid. ' +
                    'Please check if corresponding class is public and implements correct interface.'
                );
                typeException.initCause(ex);
                throw typeException;
            }
        }

        return classes;
    }

    /**
     * @return True if CustomPermissions is blank or user has defined custom permission.
     */
    private Boolean isPermitted(TriggerAction__mdt setting) {


//        if (String.isBlank(setting.CustomPermission__c)) {
            return true;
//
//        } else {
//            return FeatureManagement.checkPermission(setting.CustomPermission__c);
//        }
    }

    /**
     * @return List of trigger logic metadata for given trigger operation.
     */
    protected virtual List<TriggerAction__mdt> getCustomMetadataRecords(SObjectType sObjectType, String operation) {
        String qualifiedApiName = '' + sObjectType;
        return new List<TriggerAction__mdt>();
//        return [
//            SELECT DeveloperName, ApexClass__c, Parameters__c, CustomPermission__c
//            FROM TriggerAction__mdt
//            WHERE SObject__r.QualifiedApiName = :qualifiedApiName
//            AND Enabled__c = TRUE
//            AND Operation__c = :op.name()
//            ORDER BY Order__c ASC NULLS LAST, ApexClass__c ASC
//        ];
    }


    /**
     * Implementation of TriggerLogicSelector which returns set of predefined logic
     */
    public class MockSelector extends TriggerLogicSelector {
        private List<TriggerAction__mdt> mockMetadata;

        public MockSelector(List<TriggerAction__mdt> mockMetadata) {
            this.mockMetadata = mockMetadata;
        }

        protected override List<TriggerAction__mdt> getCustomMetadataRecords(SObjectType sObjectType, String op) {
            return mockMetadata;
        }
    }
}