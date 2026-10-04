public with sharing class Accounts {

    public class FieldSetter implements TriggerHandler.Action {

        public void execute(List<SObject> records, TriggerContext ctx) {
            for (Account record : (List<Account>) records) {
                record.Name = UserInfo.getName() + record.Name;
                record
            }
        }
    }
}