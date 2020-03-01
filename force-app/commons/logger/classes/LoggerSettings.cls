/**
* MIT License
*
* Copyright (c) 2019 Piotr Kożuchowski
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

/**
 * Accessor class for custom metadata settings in LoggerSetting__mdt
 */
public with sharing class LoggerSettings {
    @TestVisible
    private static Map<LoggingLevel, LoggerSetting__mdt> settingByLoggingLevel = new Map<LoggingLevel, LoggerSetting__mdt>();
    private static Map<String, LoggingLevel> loggingLevelEnumByName = new Map<String, LoggingLevel>{
            'INFO' => LoggingLevel.INFO,
            'WARN' => LoggingLevel.WARN,
            'ERROR' => LoggingLevel.ERROR
    };

    static {
        for (LoggerSetting__mdt setting : [SELECT Create__c, RetentionDays__c, LoggingLevel__c FROM LoggerSetting__mdt]) {
            LoggingLevel level = loggingLevelEnumByName.get(setting.LoggingLevel__c);
            settingByLoggingLevel.put(level, setting);
        }
    }

    /**
     * @return True if log with given LoggingLevel should be created.
     */
    public static Boolean shouldCreateLog(LoggingLevel level) {
        return settingByLoggingLevel.get(level).Create__c;
    }

    /**
     * @return Date of the last day when log should be retained.
     */
    public static Date getRetentionDate(LoggingLevel level) {
        LoggerSetting__mdt setting = settingByLoggingLevel.get(level);

        if (setting == null || setting.RetentionDays__c == null) {
            return Date.newInstance(1900, 1, 1);

        } else {
            Integer days = Integer.valueOf(setting.RetentionDays__c);
            return Date.today().addDays(-days);
        }
    }
}