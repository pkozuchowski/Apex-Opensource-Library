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
 * General selector for History records (AccountHistory, CustomObject__History etc).
 */
public inherited sharing class HistoryQuery extends Query {
    private SObjectField parentField;

    /**
     * @param historySObjectType History SObjectType ex. AccountHistory
     */
    public HistoryQuery(SObjectType historySObjectType) {
        super(historySObjectType);
        this.parentField = getParentField();
        this.selectFields(Query.Fields.STANDARD);
    }


    /**
     * @return Share records for given records
     */
    public HistoryQuery byParentId(Set<Id> parentIds) {
        return (HistoryQuery) byField(parentField, 'IN', parentIds);
    }


    /**
     * History fields do not have consistent naming convention.
     * This method checks for ParentId field.
     */
    private SObjectField getParentField() {
        Map<String, SObjectField> fields = sObjectType.getDescribe().fields.getMap();

        if (fields.containsKey('ParentId')) {
            return fields.get('ParentId');

        } else {
            Set<String> excluded = new Set<String>{'id', 'lastmodifiedbyid', 'createdbyid'};

            for (String field : fields.keySet()) {
                if (!excluded.contains(field) && field.endsWith('id')) {
                    return fields.get(field);
                }
            }
        }

        return null;
    }
}