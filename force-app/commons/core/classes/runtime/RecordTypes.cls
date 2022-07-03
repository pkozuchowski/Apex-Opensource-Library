/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2022 Piotr Kożuchowski
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

/**
 * Accessor class for Record Types.
 * Record Types are lazily evaluated on request.
 */
public with sharing class RecordTypes {

    //Add new record types bellow:
    public static Id ACCOUNT_DEALER     { get { return resolve(Account.SObjectType, 'Dealers');} }
    public static Id LOG_APPLICATION    { get { return resolve(Log__c.SObjectType, 'ApplicationLog');} }
    public static Id LOG_CALLOUT        { get { return resolve(Log__c.SObjectType, 'CalloutLog');} }


    private static Map<SObjectType, Map<String, RecordTypeInfo>> recordTypeCache = new Map<SObjectType, Map<String, RecordTypeInfo>>();

    /**
     * Resolves Id of the Record Type on given SObjectType
     */
    private static Id resolve(SObjectType sObjectType, String developerName) {
        if (!recordTypeCache.containsKey(sObjectType)) {
            recordTypeCache.put(sObjectType, sObjectType.getDescribe().getRecordTypeInfosByDeveloperName());
        }

        return recordTypeCache.get(sObjectType).get(developerName)?.getRecordTypeId();
    }
}