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
 * This class is responsible for querying custom metadata (TriggerLogic__mdt)
 * and creating instances of classes defined in ApexClass__c field.
 */
public with sharing class TriggerLogicSettingSelector {
    @TestVisible private static List<TriggerLogic__mdt> mockResponse;

    /**
     * @param customMetadata Type of custom metadata to query TriggerValidationRule__mdt/TriggerLogic__mdt/TriggerFieldDefault__mdt
     * @param tc Current Trigger Context
     * @param instances Empty list of desired result type ex. `new List<TriggerValidationRule> ()`
     *
     * @return New instances of classes defined in ApexClass__c field of the custom metadata.
     * @throws TypeException if Type.newInstance() failed.
     */
    public static List<Object> getInstances(String logicType, TriggerContext tc, List<Object> instances) {
        for (SObject setting : getCustomMetadataRecords(logicType, String.valueOf(tc.sObjectType), tc.operationType.name())) {
            try {
                Type ruleClass = Type.forName((String) setting.get('ApexClass__c'));
                instances.add(ruleClass.newInstance());

            } catch (Exception ex) {
                throw new TypeException('Apex class defined in custom metadata TriggerLogic__mdt.' + setting.get('DeveloperName') + '"'
                        + ' is invalid. Please check if corresponding class is public and implements correct interface.'
                );
            }
        }

        return instances;
    }

    private static List<SObject> getCustomMetadataRecords(String type, String sObjectType, String triggerOperation) {
        if (mockResponse != null) {
            return mockResponse;
        } else {
            return [
                    SELECT ApexClass__c, DeveloperName
                    FROM TriggerLogic__mdt
                    WHERE IsEnabled__c = TRUE
                    AND Type__c = :type
                    AND SObject__c = :sObjectType
                    AND Trigger__c = :triggerOperation
                    ORDER BY Order__c ASC NULLS LAST, ApexClass__c ASC
            ];
        }
    }
}