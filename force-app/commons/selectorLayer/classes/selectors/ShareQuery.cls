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
 * General selector for Share records (AccountShare, Share__History etc).
 */
public inherited sharing class ShareQuery extends QueryObject {
    private SObjectField parentField;

    public ShareQuery(SObjectType shareObjectType) {
        super(new List<SObjectField>{}, shareObjectType);
        this.query.addFields(allFields.values());
        this.parentField = this.getParentField();
    }


    /**
     * @return Share records for given user or group ids (List or Set)
     */
    public ShareQuery byUserOrGroupId(Iterable<Id> userOrGroupIds) {
        return (ShareQuery) byField('UserOrGroupId', 'IN', userOrGroupIds);
    }

    /**
     * @return Share records for given records
     */
    public ShareQuery byParentId(Iterable<Id> parentIds) {
        return (ShareQuery) byField(parentField, 'IN', parentIds);
    }

    /**
     * @return Share records for given records and users/groups (List or cast Set may be supplied as iterable)
     */
    public ShareQuery byParentIdAndUserOrGroupId(Iterable<Id> parentIds, Iterable<Id> userOrGroupIds) {
        this.query.setWhere('' + parentField + ' IN :parentIds AND UserOrGroupId IN :userOrGroupIds')
                .bindVariable('parentIds', parentIds)
                .bindVariable('userOrGroupIds', userOrGroupIds);
        return this;
    }


    /**
     * Share fields do not have consistent naming convention (AccountId, OpportunityId, ParentId)
     * This method checks for ParentId field.
     */
    private SObjectField getParentField() {
        if (allFields.containsKey('ParentId')) {
            return allFields.get('ParentId');

        } else {
            Set<String> excluded = new Set<String>{'id', 'lastmodifiedbyid', 'userorgroupid'};
            for (String field : allFields.keySet()) {
                if (!excluded.contains(field) && field.endsWith('id')) {
                    return allFields.get(field);
                }
            }

            return null;
        }
    }
}