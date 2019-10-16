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
 * Selector Layer class for UserRoles. Records are queried only once and cached to minimize SOQL limits usage.
 * @see UserRoleSelectorTest
 */
public inherited sharing class UserRoleSelector {
    private static SObjectCache cache = new SObjectCache([
            SELECT Id,
                    Name,
                    DeveloperName
            FROM UserRole

    ], new List<SObjectField>{
            UserRole.Id,
            UserRole.DeveloperName
    });


    /**
     * @return UserRole record by given name or null
     */
    public UserRole selectByDeveloperName(String developerName) {
        return (UserRole) cache.retrieveFirst(UserRole.DeveloperName, developerName);
    }


    /**
     * @return UserRoles by given developer names
     */
    public UserRole[] selectByDeveloperNames(Set<String> developerNames) {
        return cache.retrieve(UserRole.DeveloperName, new List<String>(developerNames));
    }


    /**
     * @return UserRole record by given Id or null
     */
    public UserRole selectById(Id userRoleId) {
        return (UserRole) cache.retrieveFirst(UserRole.Id, userRoleId);
    }


    /**
     * @return UserRoles by given ids
     */
    public UserRole[] selectByIds(Set<Id> userRoleIds) {
        return cache.retrieve(UserRole.Id, (List<Object>) new List<Id>(userRoleIds));
    }
}