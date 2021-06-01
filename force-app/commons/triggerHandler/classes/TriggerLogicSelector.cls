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
    public List<TriggerHandler.Logic> getLogic(TriggerContext tc) {
        return (List<TriggerHandler.Logic>) getInstances(tc, new List<TriggerHandler.Logic>());
    }


    /**
     * @param tc Current Trigger Context
     * @param instances Empty list of desired result type ex. `new List<TriggerValidationRule> ()`
     *
     * @return New instances of classes defined in ApexClass__c field of the custom metadata.
     * @throws TypeException if Type.newInstance() failed.
     */
    private List<Object> getInstances(TriggerContext tc, List<Object> instances) {
        for (TriggerLogic__mdt setting : getCustomMetadataRecords(String.valueOf(tc.sObjectType), tc.operationType)) {
            try {
                Type ruleClass = Type.forName(setting.ApexClass__c);
                Object logic = ruleClass.newInstance();

                if (logic instanceof TriggerHandler.Parameterizable) {
                    ((TriggerHandler.Parameterizable) logic).setParameters(setting.Parameters__c);
                }

                instances.add(logic);

            } catch (Exception ex) {
                TypeException typeException = new TypeException('Apex class defined in custom metadata TriggerLogic__mdt.' + setting.DeveloperName
                        + ' (' + setting.ApexClass__c + ') is invalid. Please check if corresponding class is public and implements correct interface.'
                );
                typeException.initCause(ex);
                throw typeException;
            }
        }

        return instances;
    }

    /**
     * @return List of trigger logic metadata for given trigger operation.
     */
    protected virtual List<TriggerLogic__mdt> getCustomMetadataRecords(String sObjectType, TriggerOperation op) {
        return Database.query(String.escapeSingleQuotes('SELECT ApexClass__c, DeveloperName, Parameters__c'
                + ' FROM TriggerLogic__mdt'
                + ' WHERE Enabled__c = TRUE'
                + ' AND SObject__c = :sObjectType'
                + ' AND ' + getTriggerField(op) + ' = TRUE'
                + ' ORDER BY Package__c ASC NULLS FIRST, Order__c ASC NULLS LAST, ApexClass__c ASC')
        );
    }

    /**
     * @return Checkbox field matching given Trigger Operation
     */
    protected SObjectField getTriggerField(TriggerOperation op) {
        return new Map<TriggerOperation, SObjectField>{
                TriggerOperation.BEFORE_INSERT => TriggerLogic__mdt.BeforeInsert__c,
                TriggerOperation.BEFORE_UPDATE => TriggerLogic__mdt.BeforeUpdate__c,
                TriggerOperation.BEFORE_DELETE => TriggerLogic__mdt.BeforeDelete__c,
                TriggerOperation.AFTER_INSERT => TriggerLogic__mdt.AfterInsert__c,
                TriggerOperation.AFTER_UPDATE => TriggerLogic__mdt.AfterUpdate__c,
                TriggerOperation.AFTER_DELETE => TriggerLogic__mdt.AfterDelete__c,
                TriggerOperation.AFTER_UNDELETE => TriggerLogic__mdt.AfterUndelete__c
        }.get(op);
    }


    /**
     * Implementation of TriggerLogicSelector which returns set of predefined logic
     */
    public class MockSelector extends TriggerLogicSelector {
        private List<TriggerLogic__mdt> mockMetadata;

        /**
         * @param mockedLogic List of metadata to mock
         */
        public MockSelector(List<TriggerLogic__mdt> mockMetadata) {
            this.mockMetadata = mockMetadata;
        }

        /**
         * @return Subset of mocked metadata that should be executed for current trigger sObject and operation
         */
        protected override List<TriggerLogic__mdt> getCustomMetadataRecords(String sObjectType, TriggerOperation op) {
            List<TriggerLogic__mdt> settings = new List<TriggerLogic__mdt>();
            SObjectField triggerField = getTriggerField(op);

            for (TriggerLogic__mdt logic : mockMetadata) {
                if (logic.Enabled__c == true
                        && logic.SObject__c == sObjectType
                        && logic.get(triggerField) == true) {
                    settings.add(logic);
                }
            }

            return settings;
        }
    }
}