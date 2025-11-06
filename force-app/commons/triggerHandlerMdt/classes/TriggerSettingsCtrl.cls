// SPDX-License-Identifier: MIT
// Copyright 2019 Piotr Kożuchowski

/**
 * Controller class for managing Trigger Settings custom metadata configuration.
 * Provides functionality to handle trigger settings and associated trigger actions.
 */
public with sharing class TriggerSettingsCtrl {
    /** Selector instance for retrieving trigger logic records */
    @TestVisible static TriggerLogicSelector selector = new TriggerLogicSelector();

    /** Current trigger setting metadata record */
    public TriggerSetting__mdt setting { get; set; }
    /** Return URL to Trigger Settings records */
    public String retUrl { get; set; }
    /** URL for creating new Trigger Actions */
    public String newUrl { get; set; }
    /** Name of the Apex class */
    public String apexClass { get; set; }
    /** List of available trigger operations */
    public List<String> operations { get; set; }
    /** Map of trigger operations to their corresponding actions */
    public Map<String, List<TriggerAction__mdt>> actionsByOp { get; set; }
    public Map<Id, TriggerAction__mdt> actionsById { get; set; }
    public Map<String, CustomPermission> permissionsByName { get; set; }
    public Map<String, ApexTypeImplementor> classesMap { get; set; }
    public Boolean edit { get; set; }
    public Id actionId { get; set; }

    

    /**
     * Constructor initializes the controller with trigger settings and actions
     * @param stdCtrl Standard controller for the trigger setting page
     */
    public TriggerSettingsCtrl(ApexPages.StandardController stdCtrl) {
        stdCtrl.addFields(new List<String>{'SObjectType__c'});
        this.edit = false;
        this.setting = (TriggerSetting__mdt) stdCtrl.getRecord();
        this.retUrl = 'retURL=%2F' + this.setting.Id;
        this.newUrl = '/'
            + TriggerAction__mdt.SObjectType.getDescribe().getKeyPrefix()
            + '/e?' + retUrl;

        this.classesMap = new Map<String, ApexTypeImplementor>();
        for (ApexTypeImplementor imp : [
            SELECT ApexClassId, ClassName
            FROM ApexTypeImplementor
            WHERE IsConcrete = TRUE
            AND InterfaceName = 'TriggerAction'
        ]) {
            classesMap.put(imp.ClassName, imp);
        }

        List<CustomPermission> permissions = [
            SELECT Id, DeveloperName
            FROM CustomPermission
        ];
        this.permissionsByName = new Map<String, CustomPermission>();
        for (CustomPermission permission : permissions) {
            permissionsByName.put(permission.DeveloperName, permission);
        }
        permissionsByName.put(null, new CustomPermission());
        initActions();
    }

    private void initActions() {
        this.operations = new List<String>();
        this.actionsByOp = new Map<String, List<TriggerAction__mdt>>();
        this.actionsById = new Map<Id, TriggerAction__mdt>();
        for (PicklistEntry entry : TriggerAction__mdt.Operation__c.getDescribe().getPicklistValues()) {
            operations.add(entry.value);
            List<TriggerAction__mdt> triggerActions = selector.getMetadata(setting.SObjectType__c, entry.value);
            actionsByOp.put(entry.value, triggerActions);
            actionsById.putAll(triggerActions);
        }
    }

    public void save() {
        deploy(actionsById.values());
        this.edit = false;
    }

    public void cancel() {
        initActions();
        this.edit = false;
    }

    public void toggleEdit() {
        this.edit = !this.edit;
    }

    public void resetOrder() {
        List<TriggerAction__mdt> allRecords = new List<TriggerAction__mdt>();
        for (List<TriggerAction__mdt> records : actionsByOp.values()) {
            Integer i = 1;
            for (TriggerAction__mdt action : records) {
                action.Order__c = i++;
                allRecords.add(action);
            }
        }
    }

    private static Id deploy(List<TriggerAction__mdt> records) {
        Set<String> excludedFields = new Set<String>{'Id', 'Label', 'DeveloperName', 'Trigger__c'};
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();

        for (TriggerAction__mdt record : records) {
            Map<String, Object> populatedFields = record.getPopulatedFieldsAsMap();
            Set<String> fields = new Set<String>(populatedFields.keySet());
            fields.removeAll(excludedFields);

            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = ('' + record.getSObjectType()).remove('__mdt') + '.' + record.DeveloperName;
            customMetadata.label = record.Label;

            for (String field : fields) {
                Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
                customField.field = field;
                customField.value = populatedFields.get(field);
                customMetadata.values.add(customField);
            }

            mdContainer.addMetadata(customMetadata);
        }

        Id id = Metadata.Operations.enqueueDeployment(mdContainer, null);
        return id;
    }

    public List<SelectOption> getPermissions() {
        return getRecordOptions(permissionsByName.values(), CustomPermission.DeveloperName);
    }

    public List<SelectOption> getApexClassOptions() {
        return getRecordOptions(classesMap.values(), ApexTypeImplementor.ClassName);
    }

    private List<SelectOption> getRecordOptions(List<SObject> records, SObjectField valueField) {
        List<SelectOption> options = new List<SelectOption>();

        for (SObject record : records) {
            String name = (String) record.get(valueField);
            options.add(new SelectOption(name, name));
        }
        return options;
    }
}