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
    public Map<String, List<TriggerAction__mdt>> actionsMap { get; set; }

    /**
     * Constructor initializes the controller with trigger settings and actions
     * @param stdCtrl Standard controller for the trigger setting page
     */
    public TriggerSettingsCtrl(ApexPages.StandardController stdCtrl) {
        stdCtrl.addFields(new List<String>{'SObjectType__c'});
        this.setting = (TriggerSetting__mdt) stdCtrl.getRecord();
        this.retUrl = 'retURL=%2F' + this.setting.Id;
        this.newUrl = '/'
            + TriggerAction__mdt.SObjectType.getDescribe().getKeyPrefix()
            + '/e?' + retUrl;

        this.operations = new List<String>();
        this.actionsMap = new Map<String, List<TriggerAction__mdt>>();
        for (PicklistEntry entry : TriggerAction__mdt.Operation__c.getDescribe().getPicklistValues()) {
            operations.add(entry.value);
            actionsMap.put(entry.value, selector.getMetadata(setting.SObjectType__c, entry.value));
        }
    }

    /**
     * Opens the specified Apex class in a new page
     * @return PageReference URL reference to the Apex class page
     */
    public PageReference openClass() {
        PageReference pageReference = new PageReference(Url.getOrgDomainUrl().toExternalForm() + '/' + [SELECT Id FROM ApexClass WHERE Name = :apexClass].Id);
        return pageReference;
    }
}