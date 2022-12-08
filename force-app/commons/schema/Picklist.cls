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
 * This class provides easy access to picklist field values, labels or controlling values.
 * <p/>
 * <pre>
 *     Picklist p = new Picklist(Account.Type);
 *     String default = p.getDefaultValue();
 *     String[] values = p.getValues();
 *     SelectOption[] options = p.getSelectOptions();//(VisualForce)
 *     Picklist.Entry[] entries = p.getEntries();//(Aura Enabled)
 * </pre>
 *
 * Dependencies:
 * @see BitSet
 * @see SchemaDescriptions
 */
public with sharing class Picklist {
    private List<Entry> entries;
    private List<String> values;
    private String defaultValue;
    private Boolean isRestricted;
    private Boolean isDependant;
    private transient Map<String, String> valueToLabel;
    private transient Map<String, String> valueToLabelCaseSensitive;
    private transient DescribeFieldResult picklistDescribe;


    /**
     * Constructs Picklist instance from SObjectField of picklist type.
     *
     * @param sobjectField Picklist sObject field - for example 'Opportunity.StageName'
     */
    public Picklist(String sobjectField) {
        SObjectField field = SchemaDescriptions.getSObjectField(sobjectField);
        init(field);
    }

    /**
     * Constructs Picklist instance from SObjectField of picklist type.
     *
     * @param field Picklist sObject field - for example Opportunity.StageName
     */
    public Picklist(SObjectField field) {
        init(field);
    }

    private void init(SObjectField field) {
        this.picklistDescribe = field.getDescribe();
        this.entries = new List<Entry>();
        this.values = new List<String>();
        this.valueToLabel = new Map<String, String>();
        this.valueToLabelCaseSensitive = new Map<String, String>();
        this.isRestricted = picklistDescribe.isRestrictedPicklist();
        this.isDependant = picklistDescribe.isDependentPicklist();

        List<PicklistEntry> picklistEntries = picklistDescribe.getPicklistValues();
        if (picklistEntries.isEmpty()) {
            throw new PicklistException('Field is not a picklist: ' + field);

        } else {
            List<Entry> allEntries = (List<Entry>) JSON.deserialize(JSON.serialize(picklistEntries), Entry[].class);

            for (Entry entry : allEntries) {
                if (entry.active) {
                    this.values.add(entry.value);
                    this.valueToLabel.put(entry.value.toLowerCase(), entry.label);
                    this.valueToLabelCaseSensitive.put(entry.value, entry.label);

                    this.entries.add(entry);

                    if (entry.defaultValue == true) this.defaultValue = entry.value;
                }
            }
        }
    }


    /**
     * @return True, if picklist is restricted.
     */
    public Boolean isRestricted() {
        return this.isRestricted;
    }

    /**
     * @return True, if picklist is dependant picklist
     */
    public Boolean isDependent() {
        return this.isDependant;
    }

    /**
     * @param value Picklist option's API name / value
     *
     * @return True, if picklist contains given value (case insensitive).
     */
    public Boolean containsValue(String value) {
        return valueToLabel.keySet().contains(value.toLowerCase());
    }

    /**
     * @return Picklist's default value or null.
     */
    public String getDefaultValue() {
        return defaultValue;
    }

    /**
     * @return API Names of all active picklist values.
     */
    public List<String> getValues() {
        return values;
    }

    /**
     * @return Labels of all active picklist values.
     */
    public List<String> getLabels() {
        return valueToLabel.values();
    }

    /**
     * @param value Picklist option's API name / value
     *
     * @return Label corresponding to the given picklist value.
     */
    public String getLabel(String value) {
        return valueToLabel.get(value.toLowerCase());
    }

    /**
     * @return AuraEnabled collection of active picklist entries
     */
    public List<Entry> getEntries() {
        return entries;
    }

    /**
     * @return Visualforce SelectOptions of active picklist entries.
     */
    public List<SelectOption> getSelectOptions() {
        List<SelectOption> selectOptions = new List<SelectOption>();

        for (Entry entry : entries) {
            selectOptions.add(new SelectOption(entry.value, entry.label));
        }

        return selectOptions;
    }

    /**
     * @return Map Values to Labels
     */
    public Map<String, String> getEntriesMap() {
        return valueToLabelCaseSensitive.clone();
    }

    /**
     * @return Picklist entries by controlling values (picklist API value or checkbox true/false)
     */
    public Map<Object, Entry[]> getEntriesByControllingValue() {
        if (isDependant) {
            Map<Object, Entry[]> entriesByControllingEntry = new Map<Object, Entry[]>();
            List<Object> controllingValues = picklistDescribe.getController().getDescribe().getType() == DisplayType.PICKLIST ?
                    new Picklist(picklistDescribe.getController()).getValues() : new List<Object>{false, true};

            for (Entry entry : entries) {
                BitSet bitset = BitSet.valueOfBase64(entry.validFor);

                for (Integer i = 0; i < controllingValues.size(); i++) {
                    if (bitset.get(i) == true) {
                        Object controllingValue = controllingValues.get(i);

                        if (!entriesByControllingEntry.containsKey(controllingValue)) {
                            entriesByControllingEntry.put(controllingValue, new Entry[]{});
                        }

                        entriesByControllingEntry.get(controllingValue).add(entry);
                    }
                }
            }

            return entriesByControllingEntry;
        } else {
            return new Map<Object, Entry[]>{
                    '' => entries
            };
        }
    }


    /**
     * AuraEnabled wrapper for Picklist Entry
     */
    public class Entry {
        @AuraEnabled public String label { get; private set; }
        @AuraEnabled public String value { get; private set; }
        @AuraEnabled public Boolean defaultValue { get; private set; }
        private String validFor;
        private Boolean active;
    }

    public class PicklistException extends Exception {
    }
}