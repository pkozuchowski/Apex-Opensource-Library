// SPDX-License-Identifier: MIT
// Copyright 2025 Piotr Kożuchowski

/**
 * Controller class for managing Trigger Settings custom metadata configuration.
 * Provides functionality to handle trigger settings and associated trigger actions.
 */
public with sharing class MetadataTriggerSettingsCtrl {
    @TestVisible static List<TriggerAction__mdt> mockActions;

    private Integer actionCounter = 0;
    private String actionPrefix = TriggerAction__mdt.SObjectType
        .getDescribe(SObjectDescribeOptions.DEFERRED)
        .getKeyPrefix();

    private Map<String, SelectOption> classOptsMap = new Map<String, SelectOption>();
    private Map<String, SelectOption> permissionOptsMap = new Map<String, SelectOption>();

    /** Current trigger setting metadata record */
    public TriggerSetting__mdt setting { get; set; }
    /** Return URL to Trigger Settings records */
    public String retUrl { get; set; }
    /** List of trigger operations with actions */
    public List<Operation> operations { get; set; }

    public String selectedActionId { get; set; }
    public String selectedOp { get; set; }

    public Map<String, String> links { get; set; }
    public List<SelectOption> classOpts { get; set; }
    public List<SelectOption> permissionOpts { get; set; }

    public Set<Id> newActionIds { get; set; }


    /**
     * Constructor initializes the controller with trigger settings and actions
     * @param stdCtrl Standard controller for the trigger setting page
     */
    public MetadataTriggerSettingsCtrl(ApexPages.StandardController stdCtrl) {
        if (!Test.isRunningTest()) {
            stdCtrl.addFields(new List<String>{'DeveloperName'});
        }
        this.setting = (TriggerSetting__mdt) stdCtrl.getRecord();
        this.retUrl = 'retURL=%2F' + this.setting.Id;
        this.links = new Map<String, String>{null => '404'};
        this.newActionIds = new Set<Id>();
        initActions();
        initClasses();
        initPermissions();
    }

    /**
     * Initializes the list of operations and their associated actions.
     */
    private void initActions() {
        this.operations = new List<Operation>();

        for (PicklistEntry entry : TriggerAction__mdt.Operation__c.getDescribe().getPicklistValues()) {
            List<TriggerAction__mdt> actionsMdt = getActions(entry.value);

            Operation op = new Operation(entry, actionsMdt);
            operations.add(op);

            for (TriggerAction__mdt action : actionsMdt) {
                String className = action.ApexClass__c;
                String reqPerm = action.RequiredPermission__c;
                String bypassPerm = action.BypassPermission__c;
                links.put(className, '404');
                links.put(reqPerm, '404');
                links.put(bypassPerm, '404');

                /*Add options that were defined on metadata, but do not exist in org*/
                classOptsMap.put(className, new SelectOption(className, className + ' (!)', true));

                if (String.isNotBlank(reqPerm)) {
                    permissionOptsMap.put(reqPerm, new SelectOption(reqPerm, reqPerm + ' (!)', true));
                }

                if (String.isNotBlank(bypassPerm)) {
                    permissionOptsMap.put(bypassPerm, new SelectOption(bypassPerm, bypassPerm + ' (!)', true));
                }
            }
        }
    }

    /**
     * Retrieves trigger actions for given operation.
     */
    private List<TriggerAction__mdt> getActions(String operation) {
        return mockActions?.deepClone() ?? [
            SELECT Id, Label, DeveloperName, Order__c, ApexClass__c, Parameters__c, Active__c,
                BypassPermission__c, RequiredPermission__c, Operation__c, Description__c
            FROM TriggerAction__mdt
            WHERE Trigger__c = :setting.Id
            AND Operation__c = :operation
            WITH SYSTEM_MODE
            ORDER BY Order__c ASC, ApexClass__c ASC
        ];
    }

    /**
     * Initializes the list of available Apex classes implementing TriggerAction interface.
     */
    private void initClasses() {
        for (ApexTypeImplementor imp : [
            SELECT ApexClassId, ClassName
            FROM ApexTypeImplementor
            WHERE IsConcrete = TRUE AND InterfaceName = 'TriggerAction'
            WITH SYSTEM_MODE
        ]) {
            if (!imp.ClassName.containsIgnoreCase('Test') || Test.isRunningTest()) {
                links.put(imp.ClassName, imp.ApexClassId);
                classOptsMap.put(imp.ClassName, new SelectOption(imp.ClassName, imp.ClassName));
            }
        }
        this.classOpts = new List<SelectOption>{
            new SelectOption('', '--None--')
        };
        this.classOpts.addAll(classOptsMap.values());
    }

    /**
     * Initializes the list of available custom permissions.
     */
    private void initPermissions() {
        this.permissionOpts = new List<SelectOption>{
            new SelectOption('', '--None--')
        };

        for (CustomPermission p : [
            SELECT Id, DeveloperName, NamespacePrefix
            FROM CustomPermission
            WITH SYSTEM_MODE
        ]) {
            String name = String.join(new List<String>{p.NamespacePrefix, p.DeveloperName}, '__');
            links.put(name, p.Id);
            permissionOptsMap.put(name, new SelectOption(name, name));
        }
        this.permissionOpts.addAll(permissionOptsMap.values());
    }

    /**
     * Adds a new action to the current operation's action list.
     */
    public void addNewAction() {
        Operation op = getOperation(selectedOp);
        op.edit = true;
        TriggerAction__mdt newAction = new TriggerAction__mdt(
            Id = actionPrefix + ('new' + (actionCounter++)).leftPad(12, '0'),
            Operation__c = selectedOp,
            Active__c = true,
            Order__c = op.actions.isEmpty() ? 0 : (op.actions[op.actions.size() - 1].Order__c ?? 0) + 1
        );
        op.actions.add(newAction);
        newActionIds.add(newAction.Id);
    }

    /**
     * Saves the changes made to the actions by deploying the updated metadata records.
     */
    public void save() {
        ApexPages.getMessages().clear();
        Operation op = getOperation(selectedOp);
        try {
            deploy(op.actions);
            op.edit = false;
        } catch (Exception e) {
            op.edit = true;
            ApexPages.addMessages(e);
        }
    }

    /**
     * Cancels the edit mode and reloads actions from the database.
     */
    public void cancel() {
        Operation op = getOperation(selectedOp);
        op.edit = false;
        op.actions = getActions(op.value);
    }

    /**
     * Deletes selected action from the operation's action list.
     * Works only for non-deployed actions, there's no API available for deleting existing metadata.
     */
    public void deleteAction() {
        Operation op = getOperation(selectedOp);
        List<TriggerAction__mdt> newActions = new List<TriggerAction__mdt>();
        TriggerAction__mdt deletedAction;

        for (TriggerAction__mdt action : op.actions) {
            if (action.Id != selectedActionId) {
                newActions.add(action);
            } else {
                deletedAction = action;
            }
        }

        op.actions = newActions;
    }

    /**
     * Deploys metadata records.
     * @param records List of TriggerAction__mdt records to deploy
     */
    private void deploy(List<TriggerAction__mdt> records) {
        Set<String> excludedFields = new Set<String>{'Id', 'Label', 'DeveloperName', '' + TriggerAction__mdt.Trigger__c};
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();

        for (TriggerAction__mdt record : records) {
            Map<String, Object> populatedFields = record.getPopulatedFieldsAsMap();
            Set<String> fields = new Set<String>(populatedFields.keySet());
            fields.removeAll(excludedFields);

            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = ('' + record.getSObjectType()).remove('__mdt') + '.' + record.DeveloperName;
            customMetadata.label = record.Label ?? record.DeveloperName;
            customMetadata.values.add(field('' + TriggerAction__mdt.Trigger__c, setting.DeveloperName));

            for (String field : fields) {
                Object value = populatedFields.get(field);
                customMetadata.values.add(field(field, value));
            }

            mdContainer.addMetadata(customMetadata);
        }


        Metadata.Operations.enqueueDeployment(mdContainer, null);
    }

    private Metadata.CustomMetadataValue field(String field, Object value) {
        Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
        customField.field = field;
        customField.value = value;
        return customField;
    }

    @TestVisible
    private Operation getOperation(String value) {
        for (Operation operation : operations) {
            if (operation.value == value) {
                return operation;
            }
        }
        return null;
    }

    /**
     * Wrapper class for Operation type and all associated actions.
     */
    @SuppressWarnings('PMD')
    public with sharing class Operation {
        public String label { get; set; }
        public String value { get; set; }
        public Boolean edit { get; set; }
        public List<TriggerAction__mdt> actions { get; set; }

        public Operation(PicklistEntry entry, List<TriggerAction__mdt> actions) {
            this.edit = false;
            this.value = entry.value;
            this.label = entry.label;
            this.actions = actions;
        }
    }
}