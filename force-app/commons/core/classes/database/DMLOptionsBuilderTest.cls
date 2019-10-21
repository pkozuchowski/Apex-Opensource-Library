@IsTest(IsParallel=true)
private class DMLOptionsBuilderTest {

    @IsTest
    static void testBuilder() {
        Database.DMLOptions options = new DMLOptionsBuilder()
                .allOrNone(true)
                .allowDuplicates(true)
                .allowFieldTruncation(true)
                .runDuplicateRulesAsCurrentUser(true)
                .useDefaultAssignmentRule()
                .triggerAutoResponseEmail(true)
                .triggerUserEmail(true)
                .triggerOtherEmail(true)
                .build();

        System.assertEquals(true, options.OptAllOrNone);
        System.assertEquals(true, options.DuplicateRuleHeader.AllowSave);
        System.assertEquals(true, options.DuplicateRuleHeader.RunAsCurrentUser);
        System.assertEquals(true, options.AssignmentRuleHeader.UseDefaultRule);
        System.assertEquals(true, options.AssignmentRuleHeader.UseDefaultRule);
        System.assertEquals(true, options.EmailHeader.TriggerAutoResponseEmail);
        System.assertEquals(true, options.EmailHeader.TriggerOtherEmail);
        System.assertEquals(true, options.EmailHeader.TriggerUserEmail);
    }
}