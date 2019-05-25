/**
* MIT License
*
* Copyright (c) 2018 Piotr Kożuchowski
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

    ], new List<SObjectField>{
            PermissionSet.Id,
            PermissionSet.Name
    });


    /**
     * @param permissionSetId Id of Permission Set
     * @return Permission Set or null
     */
    public PermissionSet selectById(Id permissionSetId) {
        return (PermissionSet) cache.retrieveFirst(PermissionSet.Id, permissionSetId);
    }

    /**
     * @param name Name of Permission Set
     * @return Permission Set with given name or null if it does not exist.
     */
    public PermissionSet selectByName(String name) {
        return (PermissionSet) cache.retrieveFirst(PermissionSet.Name, name);
    }

    /**
     * @param name Name of Permission Set
     * @return Id of permission set or null.
     */
    public Id selectIdByName(String name) {
        return (Id) cache.retrieveFirstValue(PermissionSet.Name, name, PermissionSet.Id);
    }
}