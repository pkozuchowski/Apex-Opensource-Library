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
public inherited sharing class PermissionSetSelector {
    private static SObjectCache cache = new SObjectCache([
            SELECT Id,Name
            FROM PermissionSet
            WHERE IsOwnedByProfile = FALSE

    ], new List<SObjectField>{
            PermissionSet.Id,
            PermissionSet.Name
    });


    /**
     * @return Permission Set by given Id or null
     */
    public PermissionSet byId(Id permissionSetId) {
        return (PermissionSet) cache.retrieveFirst(PermissionSet.Id, permissionSetId);
    }

    /**
     * @return Permission Sets by given ids (List or Set)
     */
    public PermissionSet[] byIds(Iterable<Id> permissionSetIds) {
        return cache.retrieveAll(PermissionSet.Id, permissionSetIds);
    }

    /**
     * @return Permission Set by given name or null if it does not exist.
     */
    public PermissionSet byName(String name) {
        return (PermissionSet) cache.retrieveFirst(PermissionSet.Name, name);
    }

    /**
     * @return Id of permission set or null.
     */
    public Id idByName(String name) {
        return (Id) cache.retrieveFirstValue(PermissionSet.Name, name, PermissionSet.Id);
    }

    /**
     * @return Permission Sets of given user
     */
    public PermissionSet[] byCurrentUser() {
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

        System.debug('userIds: ' + JSON.serializePretty(userIds));
        System.debug('permissionSetsByUser: ' + JSON.serializePretty(permissionSetsByUser));


        List<PermissionSetAssignment> assignments = Database.query('SELECT AssigneeId,PermissionSetId ' +
                'FROM PermissionSetAssignment WHERE AssigneeId IN :userIds');

        for (PermissionSetAssignment assignment : assignments) {
            PermissionSet permissionSet = (PermissionSet) cache.retrieveFirst(PermissionSet.Id, assignment.PermissionSetId);

            if (permissionSet != null) {
                permissionSetsByUser.get(assignment.AssigneeId).add(permissionSet);
            }
        }

        return permissionSetsByUser;
    }
}