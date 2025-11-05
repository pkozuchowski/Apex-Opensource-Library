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

        for (TriggerAction__mdt setting : getMetadata(sObjectType.toString(), operation)) {
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
        if (String.isNotBlank(setting.BypassPermission__c)
            && FeatureManagement.checkPermission(setting.BypassPermission__c)) {
            return false;
        }

        if (String.isNotBlank(setting.RequiredPermission__c)
            && !FeatureManagement.checkPermission(setting.RequiredPermission__c)) {
            return false;
        }

        return true;
    }

    /**
     * @return List of trigger logic metadata for given trigger operation.
     */
    public virtual List<TriggerAction__mdt> getMetadata(String sObjectType, String operation) {
        String qualifiedApiName = '' + sObjectType;
        return [
            SELECT Id, DeveloperName, Order__c, ApexClass__c, Parameters__c, Active__c,
                BypassPermission__c, RequiredPermission__c, Operation__c
            FROM TriggerAction__mdt
            WHERE Trigger__r.SObjectType__c = :qualifiedApiName
            AND Operation__c = :operation
            ORDER BY Order__c ASC NULLS LAST, ApexClass__c ASC
        ];
    }


    /**
     * Implementation of TriggerLogicSelector which returns set of predefined logic
     */
    public class MockSelector extends TriggerLogicSelector {
        private List<TriggerAction__mdt> mockMetadata;

        public MockSelector(List<TriggerAction__mdt> mockMetadata) {
            this.mockMetadata = mockMetadata;
        }

        public override List<TriggerAction__mdt> getMetadata(String sObjectType, String op) {
            return mockMetadata;
        }
    }
}