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
public with sharing class HistorySelector extends Selector {
    private SObjectField parentField;

    /**
     * @param shareObjectType History SObjectType ex. AccountShare, CustomObject__Share
     */
    public HistorySelector(SObjectType shareObjectType) {
        super(
                shareObjectType.getDescribe().fields.getMap().values(),
                shareObjectType
        );

        initializeParentField(shareObjectType);
    }

    /**
     * History fields do not have consistent naming convention.
     * This method checks for ParentId field.
     */
    private void initializeParentField(SObjectType shareObjectType) {
        Map<String, SObjectField> fields = shareObjectType.getDescribe().fields.getMap();

        if (fields.containsKey('ParentId')) {
            parentField = fields.get('ParentId');
        } else {
            Set<String> excluded = new Set<String>{'id', 'lastmodifiedbyid', 'createdbyid'};

            for (String field : fields.keySet()) {
                if (!excluded.contains(field) && field.endsWith('id')) {
                    parentField = fields.get(field);
                }
            }
        }
    }


    /**
     * @param parentIds List<Id> or (Iterable<Id>) Set<Id> of records
     * @return Share records for given records
     */
    public SObject[] byParentIds(Iterable<Id> parentIds) {
        return byField(parentField, parentIds);
    }
}