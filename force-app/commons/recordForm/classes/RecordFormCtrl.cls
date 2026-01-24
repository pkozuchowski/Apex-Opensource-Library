public with sharing class RecordFormCtrl {

    @AuraEnabled(Cacheable=true)
    public static List<RecordType> getRecordType(String objectApiName, String developerName) {
        String query = 'SELECT Id '
            + (isPersonAccountEnabled() ? ', IsPersonType' : '')
            + ' FROM RecordType '
            + ' WHERE SobjectType = :objectApiName' +
            ' AND DeveloperName = :developerName LIMIT 1';

        return Database.query(query);
    }

    /**
     * @return True if Person Accounts are enabled in the org, false otherwise.
     */
    public static Boolean isPersonAccountEnabled() {
        try {
            RecordType rt = new RecordType();
            rt.get('IsPersonType');
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}