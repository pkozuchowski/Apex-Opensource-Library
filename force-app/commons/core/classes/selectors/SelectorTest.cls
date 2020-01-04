@IsTest
public class SelectorTest {
    public static void assertEquals(SObject[] expected, SObject[] actual) {
        System.assertEquals(
                new Map<Id, SObject>(expected).keySet(),
                new Map<Id, SObject>(actual).keySet()
        );
    }
}