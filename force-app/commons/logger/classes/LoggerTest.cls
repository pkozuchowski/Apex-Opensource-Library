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
@IsTest
private class LoggerTest {

    /**
     * In immediate mode all logs are saved in database right away.
     */
    @IsTest
    static void testLogMessageInImmediateMode() {
        Logger logger = new Logger();


        Test.startTest();
        logger.info('INFO');
        logger.warn('WARN');
        logger.error('ERROR');

        System.assertEquals(3, Limits.getDmlRows(), 'DML should be issued for each call when in immediate mode');
        System.assertEquals(3, Limits.getDmlStatements(), 'DML should be issued for each call when in immediate mode');
        Test.stopTest();


        Log__c[] logs = [SELECT ApexClass__c,ReferenceId__c, Message__c, LoggingLevel__c FROM Log__c];
        for (Log__c log : logs) {
            System.assertEquals('LoggerTest', log.ApexClass__c);
            System.assertEquals(log.Message__c, log.LoggingLevel__c);
            System.assertEquals(null, log.ReferenceId__c);
        }
    }


    /**
     * In non-immediate mode all logs are saved in database when flush method is called.
     * This mode is especially useful for logging in-between callouts.
     */
    @IsTest
    static void testLogMessageInNonImmediateMode() {
        Logger logger = new Logger(false);


        Test.startTest();
        logger.info('INFO');
        logger.warn('WARN');
        logger.error('ERROR');
        logger.flush();

        System.assertEquals(3, Limits.getDmlRows());
        System.assertEquals(1, Limits.getDmlStatements());
        Test.stopTest();


        Log__c[] logs = [SELECT ApexClass__c,ReferenceId__c, Message__c, LoggingLevel__c FROM Log__c];
        for (Log__c log : logs) {
            System.assertEquals('LoggerTest', log.ApexClass__c);
            System.assertEquals(log.Message__c, log.LoggingLevel__c);
            System.assertEquals(null, log.ReferenceId__c);
        }
    }


    /**
     * Log record can be passed as argument for full details customization
     */
    @IsTest
    static void testLogRecord() {
        Logger logger = new Logger(true);


        Test.startTest();
        logger.info(new Log__c(
                Message__c = 'INFO',
                ReferenceId__c = '12345'
        ));
        logger.warn(new Log__c(
                Message__c = 'WARN',
                ReferenceId__c = '12345'
        ));
        logger.error(new Log__c(
                Message__c = 'ERROR',
                ReferenceId__c = '12345'
        ));
        Test.stopTest();


        Log__c[] logs = [SELECT ApexClass__c,ReferenceId__c, Message__c, LoggingLevel__c FROM Log__c];
        for (Log__c log : logs) {
            System.assertEquals('LoggerTest', log.ApexClass__c);
            System.assertEquals(log.Message__c, log.LoggingLevel__c);
            System.assertEquals('12345', log.ReferenceId__c);
        }
    }


    /**
     *@description
     * Logger.error() method can take exception as argument.
     * Logs message should contain exception's message, stack trace and cause.
     */
    @IsTest
    static void testLogException() {
        Logger logger = new Logger();


        Test.startTest();
        try {
            Date d = (Date) Datetime.now();
        } catch (Exception ex) {
            logger.error(ex);
        }
        Test.stopTest();


        Log__c log = [SELECT ApexClass__c,ReferenceId__c, Message__c, LoggingLevel__c FROM Log__c];
        System.assert(log.Message__c.contains('Invalid conversion from runtime type Datetime to Date'), 'Message should contain exception message');
        System.assert(log.Message__c.contains('LoggerTest.testLogException'), 'Message should contain stack trace');
        System.assertEquals('LoggerTest', log.ApexClass__c);
        System.assertEquals(null, log.ReferenceId__c);
    }
}