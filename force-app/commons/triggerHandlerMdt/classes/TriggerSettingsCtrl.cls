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
    public List<TriggerAction__mdt> actions { get; set; }
    public Map<Id, TriggerAction__mdt> actionsById { get; set; }
    public Boolean edit { get; set; }

    /*Action Parameters*/
    public Id actionId { get; set; }
    public String operation { get; set; }

    public Map<String, String> links { get; set; }
    public List<SelectOption> classOpts { get; set; }
    public List<SelectOption> permissionOpts { get; set; }


    /**
     * Constructor initializes the controller with trigger settings and actions
     * @param stdCtrl Standard controller for the trigger setting page
     */
    public TriggerSettingsCtrl(ApexPages.StandardController stdCtrl) {
        stdCtrl.addFields(new List<String>{'SObjectType__c', 'DeveloperName'});
        this.edit = false;
        this.setting = (TriggerSetting__mdt) stdCtrl.getRecord();
        this.retUrl = 'retURL=%2F' + this.setting.Id;
        this.newUrl = '/'
            + TriggerAction__mdt.SObjectType.getDescribe().getKeyPrefix()
            + '/e?' + retUrl;

        this.links = new Map<String, String>{null => '404'};
        initActions();
        initClasses();
        initPermissions();
    }

    private void initActions() {
        this.operations = new List<String>();
        this.actionsByOp = new Map<String, List<TriggerAction__mdt>>();
        this.actionsById = new Map<Id, TriggerAction__mdt>();
        this.actions = new List<TriggerAction__mdt>();

        for (PicklistEntry entry : TriggerAction__mdt.Operation__c.getDescribe().getPicklistValues()) {
            List<TriggerAction__mdt> actionsMdt = selector.getActions(setting.SObjectType__c, entry.value);
            operations.add(entry.value);
            actionsByOp.put(entry.value, actionsMdt);
            actions.addAll(actionsMdt);

            for (TriggerAction__mdt action : actionsMdt) {
                links.put(action.ApexClass__c, '');
                links.put(action.RequiredPermission__c, '');
                links.put(action.BypassPermission__c, '');
            }
        }
    }

    private void initClasses() {
        this.classOpts = new List<SelectOption>();
        for (ApexTypeImplementor imp : [
            SELECT ApexClassId, ClassName
            FROM ApexTypeImplementor
            WHERE IsConcrete = TRUE
            AND InterfaceName = 'TriggerAction'
        ]) {
            if (!imp.ClassName.containsIgnoreCase('Test')) {
                links.put(imp.ClassName, imp.ApexClassId);
                classOpts.add(new SelectOption(imp.ClassName, imp.ClassName));
            }
        }
    }

    private void initPermissions() {
        this.permissionOpts = new List<SelectOption>{
            new SelectOption('', '--None--')
        };
        for (CustomPermission p : [SELECT Id, DeveloperName FROM CustomPermission]) {
            links.put(p.DeveloperName, p.Id);
            permissionOpts.add(new SelectOption(p.DeveloperName, p.DeveloperName));
        }
    }

    public void addNewAction() {
        this.edit = true;
        TriggerAction__mdt triggerAction = new TriggerAction__mdt(
            Operation__c = operation
        );
        actionsByOp.get(operation).add(triggerAction);
        actions.add(triggerAction);
    }

    public void save() {
        try {
            deploy(this.actions);
            this.edit = false;
        } catch (Exception e) {
            this.edit = true;
            ApexPages.addMessages(e);
        }
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

    private Id deploy(List<TriggerAction__mdt> records) {
        Set<String> excludedFields = new Set<String>{'Id', 'Label', 'DeveloperName', 'Trigger__c'};
        Set<String> requiredFields = new Set<String>{'Order__c', 'DeveloperName', 'ApexClass__c'};
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();

        for (TriggerAction__mdt record : records) {
            Map<String, Object> populatedFields = record.getPopulatedFieldsAsMap();
            Set<String> fields = new Set<String>(populatedFields.keySet());
            fields.removeAll(excludedFields);

            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = ('' + record.getSObjectType()).remove('__mdt') + '.' + record.DeveloperName;
            customMetadata.label = record.Label ?? record.DeveloperName;
            customMetadata.values.add(field('Trigger__c', setting.DeveloperName));

            System.debug('record: ' + JSON.serializePretty(record));
            
            for (String field : fields) {
                Object value = populatedFields.get(field);
                if (requiredFields.contains(field) && value == null) {
                    throw new DmlException('Field Required: ' + field);
                }
                customMetadata.values.add(field(field, value));
            }

            mdContainer.addMetadata(customMetadata);
        }


        Id id = Metadata.Operations.enqueueDeployment(mdContainer, null);
        return id;
    }

    private Metadata.CustomMetadataValue field(String field, Object value) {
        Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
        customField.field = field;
        customField.value = value;
        return customField;
    }
}