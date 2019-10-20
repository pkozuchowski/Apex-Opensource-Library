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
 * Validates records with a set of specified rules.
 */
public with sharing class SObjectValidator {
    @TestVisible private static ValidationRuleSelector settingsSelector = new ValidationRuleSelector();

    /**
     * Validates triggered records with a set of validation rules specified in Custom Metadata.
     */
    public static void validate(List<SObject> records, TriggerContext tc) {
        validate(records, tc, getConfiguredValidationRules(tc));
    }


    /**
     * Validates triggered records with a set of specified rules (ValidationRule implementations).
     */
    public static void validate(List<SObject> records, TriggerContext tc, List<ValidationRule> validationRules) {
        for (ValidationRule validationRule : validationRules) {
            validationRule.prepare(records, tc);

            for (SObject record : records) {
                validationRule.validate(record, tc);
            }
        }
    }


    /**
     * @return ValidationRules defined in custom metadata.
     */
    private static List<ValidationRule> getConfiguredValidationRules(TriggerContext tc) {
        List<ValidationRule> validationRules = new List<ValidationRule>();

        for (TriggerValidationRule__mdt setting : settingsSelector.getSettings(tc)) {
            try {
                Type ruleClass = Type.forName(setting.ApexClass__c);
                ValidationRule validationRule = (ValidationRule) ruleClass.newInstance();
                validationRules.add(validationRule);

            } catch (Exception ex) {
                throw new TypeException('Validation Rule "' + setting.DeveloperName + '" is invalid. ' +
                        'Please check if corresponding class is public and implements ValidationRule interface.');
            }
        }
        return validationRules;
    }


    /**
     * Selector for custom metadata defined field defaults.
     */
    @TestVisible
    private virtual class ValidationRuleSelector {
        public virtual List<TriggerValidationRule__mdt> getSettings(TriggerContext tc) {
            return [
                    SELECT ApexClass__c, DeveloperName
                    FROM TriggerValidationRule__mdt
                    WHERE IsEnabled__c = TRUE
                    AND SObject__c = :String.valueOf(tc.sObjectType)
                    AND Trigger__c = :tc.operationType.name()
                    ORDER BY Order__c NULLS LAST
            ];
        }
    }
}