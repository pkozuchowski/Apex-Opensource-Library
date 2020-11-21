@IsTest(IsParallel=true)
private class SchemaDescriptionsTest {

    @IsTest
    static void shouldReturnSObjectTypeForName() {
        System.assertEquals(
                Account.SObjectType,
                SchemaDescriptions.getSObjectType('Account')
        );
    }

    @IsTest
    static void shouldReturnSObjectDescribeForName() {
        System.assertEquals(
                Account.SObjectType.getDescribe(),
                SchemaDescriptions.getSObjectDescribe('Account')
        );
    }

    @IsTest
    static void shouldReturnSObjectFieldForName() {
        System.assertEquals(
                Account.Name,
                SchemaDescriptions.getSObjectField('Account.Name')
        );
    }

    @IsTest
    static void shouldReturnSObjectFieldDescribeForName() {
        System.assertEquals(
                Account.Name.getDescribe(),
                SchemaDescriptions.getSObjectFieldDescribe('Account.Name')
        );
    }

    @IsTest
    static void shouldCheckValidityOfSObject() {
        Exception ex;

        try {
            SchemaDescriptions.getSObjectDescribe('AccountFake');
        } catch (SchemaDescriptions.SchemaException e) {
            ex = e;
        }

        System.assertNotEquals(ex, null);
        System.assertEquals(ex.getMessage(), 'Invalid SObject: AccountFake');
    }

    @IsTest
    static void shouldCheckValidityOfField() {
        Exception ex;

        try {
            SchemaDescriptions.getSObjectFieldDescribe('Account.NameFake');
        } catch (SchemaDescriptions.SchemaException e) {
            ex = e;
        }

        System.assertNotEquals(ex, null);
        System.assertEquals(ex.getMessage(), 'Invalid SObjectField: Account.NameFake');
    }

    @IsTest
    static void shouldReturnAllSObjectFields() {
        System.assertEquals(
                Account.SObjectType.getDescribe().fields.getMap(),
                SchemaDescriptions.getFieldsMap(Account.SObjectType)
        );
    }

    @IsTest
    static void cacheCoverage() {
        SchemaDescriptions.getSObjectFieldDescribe('Account.Name');
        SchemaDescriptions.getSObjectFieldDescribe('Account.Name');
        SchemaDescriptions.getSObjectDescribe('Account');
        SchemaDescriptions.getSObjectField('Account.Name');
        SchemaDescriptions.getFieldsMap('Account');
    }
}