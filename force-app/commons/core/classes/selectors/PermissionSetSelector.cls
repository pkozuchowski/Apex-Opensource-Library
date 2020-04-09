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
 * Selector Layer class for Permission Sets. Records are queried only once and cached to minimize SOQL limits usage.
 * @see PermissionSetSelectorTest
 */
public inherited sharing class PermissionSetSelector extends Selector {

    public PermissionSetSelector() {
        super(new List<SObjectField>{
                PermissionSet.Id,
                PermissionSet.Name
        }, PermissionSet.SObjectType);
    }

    /**
     * @return Id of permission set or null.
     */
    public Id idByName(String name) {
        PermissionSet permissionSet = byName(name);
        return permissionSet == null ? null : permissionSet.Id;
    }

    /**
     * @return Permission Set by given name or null if it does not exist.
     */
    public PermissionSet byName(String name) {
        return (PermissionSet) firstOrNull(byName(new List<String>{name}));
    }

    /**
     * @return Permission Set by given name or null if it does not exist.
     */
    public PermissionSet[] byName(Iterable<String> names) {
        return byField(PermissionSet.Name, 'IN', names);
    }


    /**
     * @return Permission Sets of given user
     */
    public PermissionSet[] ofCurrentUser() {
        return byAssigneeId(UserInfo.getUserId());
    }

    /**
     * @return Permission Sets of given user
     */
    public PermissionSet[] byAssigneeId(Id userId) {
        return byAssigneeId(new List<Id>{userId}).get(userId);
    }

    /**
     * @return Permission Sets of given user
     */
    public Map<Id, PermissionSet[]> byAssigneeId(Iterable<Id> userIds) {
        Map<Id, PermissionSet[]> permissionSetsByUser = new Map<Id, PermissionSet[]>();

        Iterator<Id> it = userIds.iterator();
        while (it.hasNext()) {
            permissionSetsByUser.put(it.next(), new PermissionSet[]{});
        }

        for (PermissionSetAssignment assignment : [
                SELECT AssigneeId,PermissionSetId
                FROM PermissionSetAssignment
                WHERE AssigneeId IN :permissionSetsByUser.keySet()
                AND PermissionSet.IsOwnedByProfile = FALSE
        ]) {
            PermissionSet permissionSet = (PermissionSet) getCache().get(PermissionSet.Id, assignment.PermissionSetId);

            if (permissionSetsByUser.containsKey(assignment.AssigneeId)) {
                permissionSetsByUser.get(assignment.AssigneeId).add(permissionSet);
            } else {
                permissionSetsByUser.put(assignment.AssigneeId, new List<PermissionSet>{permissionSet});
            }
        }

        return permissionSetsByUser;
    }


    protected override Set<SObjectField> getFieldsToCacheBy() {
        return new Set<SObjectField>{
                PermissionSet.Id,
                PermissionSet.Name
        };
    }

    protected override List<SObject> getRecordsToCache() {
        return byField(PermissionSet.IsOwnedByProfile, '=', false);
    }
}