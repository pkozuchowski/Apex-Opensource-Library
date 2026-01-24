@IsTest(IsParallel=true)
private class RecordFormCtrlTest {

    @IsTest
    static void getRecordTypeShouldReturnRtByDeveloperName() {
        List<RecordType> rt = [SELECT Id, DeveloperName, SobjectType FROM RecordType];

        if (!rt.isEmpty()) {
            List<RecordType> result = RecordFormCtrl.getRecordType(
                rt[0].SobjectType,
                rt[0].DeveloperName
            );
            System.assertEquals(1, result.size());
            System.assertEquals(rt[0].Id, result[0].Id);
        } else {
            List<RecordType> result = RecordFormCtrl.getRecordType(
                'UnknownObject__c',
                'UnknownDeveloperName'
            );
            Assert.isTrue(result.isEmpty());
        }
    }
}