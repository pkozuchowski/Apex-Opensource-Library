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
public inherited sharing class ShareQuery extends Query {
    private String parentField;

    public ShareQuery(SObjectType shareObjectType) {
        super(shareObjectType);
        this.parentField = getParentField();
        this.selectFields(Query.Fields.STANDARD);
    }


    /**
     * @return Share records for given user or group ids
     */
    public ShareQuery byUserOrGroupId(Set<Id> userOrGroupIds) {
        return (ShareQuery) byField('UserOrGroupId', 'IN', userOrGroupIds);
    }

    /**
     * @return Share records for given records
     */
    public ShareQuery byParentId(Set<Id> parentIds) {
        return (ShareQuery) byField(parentField, 'IN', parentIds);
    }

    /**
     * @return Share records for given records and users/groups
     */
    public ShareQuery byParentIdAndUserOrGroupId(Set<Id> parentIds, Set<Id> userOrGroupIds) {
        wheres(conditionFactory.ANDs(
            conditionFactory.field(parentField).isIn(parentIds),
            conditionFactory.field('UserOrGroupId').isIn(userOrGroupIds)
        ));
        return this;
    }


    /**
     * Share fields do not have consistent naming convention (AccountId, OpportunityId, ParentId)
     * This method checks for ParentId field.
     */
    private String getParentField() {
        Map<String, SObjectField> allFields = sObjectType.getDescribe().fields.getMap();
        String sobjectType = '' + sObjectType;

        if (allFields.containsKey('ParentId')) {
            return '' + allFields.get('ParentId');

        } else {
            return sobjectType.replace('Share', 'Id');
        }
    }
}