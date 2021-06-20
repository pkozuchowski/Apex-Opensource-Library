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
 * Selector Layer class for Permission Set Assignments.
 * @see PermissionSetQueryTest
 */
public inherited sharing class PermissionSetAssignmentQuery extends Query {

    public PermissionSetAssignmentQuery() {
        super(new List<String>{
            'AssigneeId',
            'PermissionSetId',
            'PermissionSet.Name'

        }, PermissionSetAssignment.SObjectType);
    }


    /**
     * Filter Permission Sets Assignments to those of current user
     */
    public PermissionSetAssignmentQuery byCurrentUser() {
        return byAssigneeId(UserInfo.getUserId());
    }


    /**
     * Filter Permission Sets Assignments to those of given users
     */
    public PermissionSetAssignmentQuery byAssigneeId(Id assigneeId) {
        return byAssigneeId(new Set<Id>{assigneeId});
    }

    /**
     * Filter Permission Sets Assignments to those of given users
     */
    public PermissionSetAssignmentQuery byAssigneeId(Set<Id> assigneeId) {
        return (PermissionSetAssignmentQuery) byField(PermissionSetAssignment.AssigneeId, 'IN', assigneeId);
    }


    /**
     * Filter Permission Sets Assignments to those associated with given permission set
     */
    public PermissionSetAssignmentQuery byPermissionSetId(Id permissionSetId) {
        return byPermissionSetId(new Set<Id>{permissionSetId});
    }

    /**
     * Filter Permission Sets Assignments to those associated with given permission sets
     */
    public PermissionSetAssignmentQuery byPermissionSetId(Set<Id> permissionSetId) {
        return (PermissionSetAssignmentQuery) byField(PermissionSetAssignment.PermissionSetId, 'IN', permissionSetId);
    }
}