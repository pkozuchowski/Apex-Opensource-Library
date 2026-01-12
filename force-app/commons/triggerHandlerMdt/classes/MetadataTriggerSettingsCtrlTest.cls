@IsTest(IsParallel=true)
private class MetadataTriggerSettingsCtrlTest {

    private static MetadataTriggerSettingsCtrl getController() {
        TriggerSetting__mdt setting = new TriggerSetting__mdt(
            DeveloperName = 'AccountTrigger',
            Label = 'Account Trigger',
            SObjectType__c = 'Account',
            Active__c = true
        );

        MetadataTriggerSettingsCtrl.mockActions = new List<TriggerAction__mdt>{
            new TriggerAction__mdt(
                Order__c = 1,
                DeveloperName = 'Action1',
                Label = 'Action 1',
                ApexClass__c = 'MetadataTriggerHandlerTest.AccountPopulateFields',
                Operation__c = TriggerOperation.BEFORE_UPDATE.name()
            ),
            new TriggerAction__mdt(
                Order__c = 2,
                DeveloperName = 'Action2',
                Label = 'Action 2',
                ApexClass__c = 'MetadataTriggerHandlerTest.AccountValidate',
                Operation__c = TriggerOperation.BEFORE_UPDATE.name()
            ),
            new TriggerAction__mdt(
                Order__c = 3,
                DeveloperName = 'Action3',
                Label = 'Action 3',
                ApexClass__c = 'MetadataTriggerHandlerTest.InvalidAction',
                Operation__c = TriggerOperation.BEFORE_UPDATE.name(),
                BypassPermission__c = 'MetadataTriggerHandlerTestPermission'
            )
        };

        ApexPages.StandardController stdController = new ApexPages.StandardController(setting);
        MetadataTriggerSettingsCtrl controller = new MetadataTriggerSettingsCtrl(stdController);
        return controller;
    }

    @IsTest
    static void testApexOptions() {
        MetadataTriggerSettingsCtrl controller = getController();

        Test.startTest();
        List<SelectOption> classOpts = controller.classOpts;
        Test.stopTest();

        Set<String> classNames = new Set<String>();
        for (SelectOption opt : classOpts) {
            classNames.add(opt.getLabel());
        }

        Assert.isTrue(classNames.contains('MetadataTriggerHandlerTest.AccountPopulateFields'));
        Assert.isTrue(classNames.contains('MetadataTriggerHandlerTest.AccountValidate'));
        Assert.isTrue(classNames.contains('MetadataTriggerHandlerTest.AccountLinkContacts'));
        Assert.isTrue(classNames.contains('MetadataTriggerHandlerTest.AccountPreventMoreThanOneContact'));
        Assert.isTrue(classNames.contains('MetadataTriggerHandlerTest.InvalidAction (!)'));
    }

    @IsTest
    static void testCustomPermissionsOptions() {
        MetadataTriggerSettingsCtrl controller = getController();

        Test.startTest();
        List<SelectOption> permissionOpts = controller.permissionOpts;
        Test.stopTest();

        Set<String> permissionNames = new Set<String>();
        for (SelectOption opt : permissionOpts) {
            permissionNames.add(opt.getLabel());
        }

        Assert.isTrue(permissionNames.contains('MetadataTriggerHandlerTestPermission (!)'));
        for (CustomPermission customPermission : [SELECT DeveloperName, NamespacePrefix FROM CustomPermission]) {
            String name = '' + (customPermission.NamespacePrefix != null ? customPermission.NamespacePrefix + '__' : '')
                + customPermission.DeveloperName;
            Assert.isTrue(permissionNames.contains(name), 'Should contain:' + name);
        }
    }

    @IsTest
    static void testNewAction() {
        MetadataTriggerSettingsCtrl controller = getController();

        Test.startTest();
        String op = TriggerOperation.BEFORE_UPDATE.name();
        controller.selectedOp = op;
        controller.addNewAction();
        MetadataTriggerSettingsCtrl.Operation beforeUpdate = controller.getOperation(op);
        Test.stopTest();

        Assert.areEqual(4, beforeUpdate.actions.size());
        TriggerAction__mdt newAction = beforeUpdate.actions[3];
        Assert.areEqual(true, newAction.Active__c);
        Assert.areEqual(4, newAction.Order__c);
    }

    @IsTest
    static void testCancel() {
        MetadataTriggerSettingsCtrl controller = getController();

        Test.startTest();
        String op = TriggerOperation.BEFORE_UPDATE.name();
        controller.selectedOp = op;
        controller.addNewAction();
        controller.cancel();
        MetadataTriggerSettingsCtrl.Operation beforeUpdate = controller.getOperation(op);
        Test.stopTest();


        Assert.areEqual(3, beforeUpdate.actions.size());
    }

    @IsTest
    static void testDeleteAction() {
        MetadataTriggerSettingsCtrl controller = getController();

        Test.startTest();
        String op = TriggerOperation.BEFORE_UPDATE.name();
        controller.selectedOp = op;
        controller.addNewAction();

        MetadataTriggerSettingsCtrl.Operation beforeUpdate = controller.getOperation(op);
        Assert.areEqual(4, beforeUpdate.actions.size());
        TriggerAction__mdt newAction = beforeUpdate.actions[3];

        controller.selectedActionId = newAction.Id;
        controller.deleteAction();
        Test.stopTest();

        Assert.areEqual(3, beforeUpdate.actions.size());
    }

    @IsTest
    static void testSave() {
        MetadataTriggerSettingsCtrl controller = getController();

        Test.startTest();
        PageReference p = Page.MetadataTriggerSettings;
        Test.setCurrentPage(p);

        controller.selectedOp = TriggerOperation.BEFORE_UPDATE.name();
        controller.save();
        Test.stopTest();


        Assert.isFalse(ApexPages.getMessages().isEmpty());
        Assert.areEqual('Metadata cannot be deployed from within a test', ApexPages.getMessages()[0].getSummary());
    }
}