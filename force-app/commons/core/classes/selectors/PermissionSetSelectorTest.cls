@IsTest(IsParallel=true)
private class PermissionSetSelectorTest {
    private final static PermissionSetSelector permissionSetSelector = new PermissionSetSelector();
    private final static PermissionSet[] permissionSets = [SELECT Id, Name FROM PermissionSet];

    @IsTest
    static void testSelectNull() {
        System.assertEquals(null, permissionSetSelector.byName('PermissionSetSelectorTest'));
        System.assertEquals(null, permissionSetSelector.idByName('PermissionSetSelectorTest'));
        System.assertEquals(null, permissionSetSelector.byId('001000000000000'));
    }

    @IsTest
    static void testSelectById() {
        if (!permissionSets.isEmpty()) {
            PermissionSet permissionSet = permissionSets[0];

            System.assertEquals(
                    permissionSet.Id,
                    permissionSetSelector.byId(permissionSet.Id).Id
            );
        }
    }

    @IsTest
    static void testSelectByName() {
        if (!permissionSets.isEmpty()) {
            PermissionSet permissionSet = permissionSets[0];

            System.assertEquals(
                    permissionSet.Id,
                    permissionSetSelector.byName(permissionSet.Name).Id
            );
        }
    }

    @IsTest
    static void testSelectIdByName() {
        if (!permissionSets.isEmpty()) {
            PermissionSet permissionSet = permissionSets[0];

            System.assertEquals(
                    permissionSet.Id,
                    permissionSetSelector.idByName(permissionSet.Name)
            );
        }
    }
}