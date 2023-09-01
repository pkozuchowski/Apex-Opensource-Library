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
public virtual inherited sharing class TriggerLogicSelector {

    /**
     * @param tc Trigger Context of running trigger
     * @return Trigger Logic for currently executing trigger
     */
    public List<TriggerLogic> getLogic(TriggerContext tc) {
        List<TriggerLogic> classes = new List<TriggerLogic>();

        for (TriggerLogic__mdt setting : getCustomMetadataRecords(tc.sObjectType, tc.operationType)) {
            try {
                if (isPermitted(setting)) {
                    Type ruleClass = Type.forName(setting.ApexClass__c);
                    TriggerLogic logic = (TriggerLogic) ruleClass.newInstance();
                    logic.setParameters(setting.Parameters__c);

                    classes.add(logic);
                }
            } catch (Exception ex) {
                System.debug(ex.getMessage());
                System.debug(ex.getStackTraceString());
                TypeException typeException = new TypeException(
                    'Apex class defined in custom metadata TriggerLogic__mdt.' + setting.DeveloperName
                        + ' (' + setting.ApexClass__c + ') is invalid. ' +
                        'Please check if corresponding class is public and implements correct interface.'
                );
                typeException.initCause(ex);
                throw typeException;
            }
        }

        return classes;
    }

    /**
     * @return True if CustomPermissions is blank or user has defined custom permission.
     */
    private Boolean isPermitted(TriggerLogic__mdt setting) {
        if (String.isBlank(setting.CustomPermission__c)) {
            return true;

        } else {
            return FeatureManagement.checkPermission(setting.CustomPermission__c);
        }
    }

    /**
     * @return List of trigger logic metadata for given trigger operation.
     */
    protected virtual List<TriggerLogic__mdt> getCustomMetadataRecords(SObjectType sObjectType, TriggerOperation op) {
        String qualifiedApiName = '' + sObjectType;
        return [
            SELECT DeveloperName, ApexClass__c, Parameters__c, CustomPermission__c
            FROM TriggerLogic__mdt
            WHERE SObject__r.QualifiedApiName = :qualifiedApiName
            AND Enabled__c = TRUE
            AND Operation__c = :op.name()
            ORDER BY Order__c ASC NULLS LAST, ApexClass__c ASC
        ];
    }


    /**
     * Implementation of TriggerLogicSelector which returns set of predefined logic
     */
    public class MockSelector extends TriggerLogicSelector {
        private List<TriggerLogic__mdt> mockMetadata;

        public MockSelector(List<TriggerLogic__mdt> mockMetadata) {
            this.mockMetadata = mockMetadata;
        }

        protected override List<TriggerLogic__mdt> getCustomMetadataRecords(SObjectType sObjectType, TriggerOperation op) {
            return mockMetadata;
        }
    }
}