@IsTest
private class ApexTest {

    public class ExampleClass {
    }


    /**
     *@description
     * Apex.getRunningType() returns running type of the object instance.
     */
    @IsTest
    static void testGetRunningType() {
        ExampleClass instance = new ExampleClass();
        System.assertEquals(ExampleClass.class, Apex.getRunningType(instance));
    }

    @IsTest
    static void testGetDatesRunningType() {
        Date instance = Date.today();
        System.assertEquals(Date.class, Apex.getRunningType(instance));
    }


    /**
     *@description
     * Apex.getRunningType() returns name of running type of the object instance.
     */
    @IsTest
    static void testGetRunningTypeName() {
        ExampleClass instance = new ExampleClass();
        System.assertEquals('ApexTest.ExampleClass', Apex.getRunningTypeName(instance));
    }

    /**
     *@description
     * Apex.getListItemType() returns type of elements in given list
     */
    @IsTest
    static void testGetListItemType() {
        System.assertEquals(Account.class, Apex.getListItemType(new List<Account>()));

        List<SObject> records = new List<Opportunity>();
        System.assertEquals(Opportunity.class, Apex.getListItemType(records));
    }


    /**
     *@description
     * Apex.newListOfTheSameType returns new list of the same item type as param.
     */
    @IsTest
    static void testNewListOfTheSameType(){
        List<SObject> records = new List<Opportunity>();
        List<Object> result = Apex.newListOfTheSameType(records);

        System.assert(result instanceof List<Opportunity>);
    }

    /**
     *@description
     * Apex.newListOfItemType returns new list with the given item type
     */
    @IsTest
    static void testNewListOfItemType(){
        List<Object> result = Apex.newListOfItemType(Opportunity.class);
        System.assert(result instanceof List<Opportunity>);
    }
}