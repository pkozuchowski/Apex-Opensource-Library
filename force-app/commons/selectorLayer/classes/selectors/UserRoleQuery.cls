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
 * Selector Layer class for UserRoles.
 * @see UserRoleQueryTest
 */
public inherited sharing class UserRoleQuery extends Query {

    public UserRoleQuery() {
        super(UserRole.SObjectType);
        selectFields(Query.Fields.STANDARD);
    }


    /**
    * @return UserRole of current user
    */
    public UserRoleQuery byCurrentUser() {
        return (UserRoleQuery) byField(UserRole.Id, '=', UserInfo.getUserRoleId());
    }

    /**
     * @return UserRole record by given name or null
     */
    public UserRoleQuery byDeveloperName(String developerName) {
        return byDeveloperName(new Set<String>{developerName});
    }


    /**
     * @return UserRoles by given developer names
     */
    public UserRoleQuery byDeveloperName(Set<String> developerNames) {
        return (UserRoleQuery) byField(UserRole.DeveloperName, 'IN', developerNames);
    }


    protected override Set<String> getFieldsToCacheBy() {
        return new Set<String>{
            'Id',
            'DeveloperName'
        };
    }

}