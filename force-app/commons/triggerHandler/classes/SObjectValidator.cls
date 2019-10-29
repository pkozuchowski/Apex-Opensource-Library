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

    /**
     * Validates triggered records with a set of validation rules specified in Custom Metadata.
     */
    public static void validate(List<SObject> records, TriggerContext triggerContext) {
        validate(records, triggerContext, (List<TriggerValidationRule>) MetadataDefinedTriggerClasses.getInstances(
                TriggerValidationRule__mdt.SObjectType,
                triggerContext,
                new List<TriggerValidationRule>()
        ));
    }


    /**
     * Validates triggered records with a set of specified rules (ValidationRule implementations).
     */
    public static void validate(List<SObject> records, TriggerContext tc, List<TriggerValidationRule> validationRules) {
        for (TriggerValidationRule validationRule : validationRules) {
            validationRule.prepare(records, tc);

            for (SObject record : records) {
                validationRule.validate(record, tc);
            }
        }
    }
}