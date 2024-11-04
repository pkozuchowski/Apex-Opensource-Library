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
    public static RecordTypeData ACCOUNT_PERSON { get {return resolve(Account.SObjectType, 'PersonAccount');} }


    private static Map<SObjectType, Map<String, RecordTypeData>> recordTypeCache = new Map<SObjectType, Map<String, RecordTypeData>>();

    /**
     * Resolves Id of the Record Type on given SObjectType
     */
    private static RecordTypeData resolve(SObjectType sObjectType, String developerName) {
        if (!recordTypeCache.containsKey(sObjectType)) {
            Map<String, RecordTypeInfo> recordTypeInfosByDevName = sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
            Map<String, RecordTypeData> recordTypeDataByDevName = new Map<String, RecordTypeData>();

            for (RecordTypeInfo recordTypeInfo : recordTypeInfosByDevName.values()) {
                RecordTypeData rtData = new RecordTypeData(recordTypeInfo);
                recordTypeDataByDevName.put(rtData.DeveloperName, rtData);
            }

            recordTypeCache.put(sObjectType, recordTypeDataByDevName);
        }

        return recordTypeCache.get(sObjectType).get(developerName);
    }
}