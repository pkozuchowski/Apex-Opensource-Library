@IsTest(IsParallel=true)
private class PermissionSetSelectorTest {
    private final static PermissionSetSelector permissionSetSelector = new PermissionSetSelector();
    private final static PermissionSet[] permissionSets = [SELECT Id, Name FROM PermissionSet];

    @IsTest
    static void testSelectNull() {
        System.assertEquals(null, permissionSetSelector.selectByName('PermissionSetSelectorTest'));
        System.assertEquals(null, permissionSetSelector.selectIdByName('PermissionSetSelectorTest'));
        System.assertEquals(null, permissionSetSelector.selectById('001000000000000'));
    }

    @IsTest
    static void testSelectById() {
        if (!permissionSets.isEmpty()) {
            PermissionSet permissionSet = permissionSets[0];

            System.assertEquals(
                    permissionSet.Id,
                    permissionSetSelector.selectById(permissionSet.Id).Id
            );
        }
    }

    @IsTest
    static void testSelectByName() {
        if (!permissionSets.isEmpty()) {
            PermissionSet permissionSet = permissionSets[0];

            System.assertEquals(
                    permissionSet.Id,
                    permissionSetSelector.selectByName(permissionSet.Name).Id
            );
        }
    }

    @IsTest
    static void testSelectIdByName() {
        if (!permissionSets.isEmpty()) {
            PermissionSet permissionSet = permissionSets[0];

            System.assertEquals(
                    permissionSet.Id,
                    permissionSetSelector.selectIdByName(permissionSet.Name)
            );
        }
    }
}