/**
 * Accessor class for custom metadata settings in LogRetention__mdt
 */
public with sharing class LoggingSettings {
    @TestVisible
    private static Map<LoggingLevel, LogRetention__mdt> settings = new Map<LoggingLevel, LogRetention__mdt>();

    static {
        settings.put(LoggingLevel.INFO, [SELECT Create__c, RetentionDays__c FROM LogRetention__mdt WHERE LoggingLevel__c = 'INFO']);
        settings.put(LoggingLevel.WARN, [SELECT Create__c, RetentionDays__c FROM LogRetention__mdt WHERE LoggingLevel__c = 'WARN']);
        settings.put(LoggingLevel.ERROR, [SELECT Create__c, RetentionDays__c FROM LogRetention__mdt WHERE LoggingLevel__c = 'ERROR']);
    }

    /**
     * @return True if log with given LoggingLevel should be created.
     */
    public static Boolean shouldCreateLog(LoggingLevel level) {
        return settings.get(level).Create__c;
    }

    /**
     * @return Date of the last day when log should be retained.
     */
    public static Date getRetentionDate(LoggingLevel level) {
        LogRetention__mdt setting = settings.get(level);

        if (setting == null || setting.RetentionDays__c == null) {
            return Date.newInstance(1900, 1, 1);

        } else {
            Integer days = Integer.valueOf(setting.RetentionDays__c);
            return Date.today().addDays(-days);
        }
    }
}