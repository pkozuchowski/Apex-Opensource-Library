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
 */
public class UserRoleSelector {
    private final static Map<String, UserRole> cachedRoles = new Map<String, UserRole>();
    static {
        List<UserRole> userRoles = [
                SELECT Id,
                        Name,
                        DeveloperName
                FROM UserRole
        ];

        for (UserRole role : userRoles) {
            cachedRoles.put(role.Id, role);
            cachedRoles.put(role.DeveloperName, role);
        }
    }


    /**
     * @return Id of UserRole with given developer name or null
     */
    public Id selectIdByDeveloperName(String developerName) {
        return cachedRoles.containsKey(developerName) ? cachedRoles.get(developerName).Id : null;
    }


    /**
     * @return UserRole record by given name or null
     */
    public UserRole selectByDeveloperName(String developerName) {
        return cachedRoles.get(developerName);
    }


    /**
     * @return UserRoles by given developer names
     */
    public UserRole[] selectByDeveloperNames(Set<String> developerNames) {
        List<UserRole> result = new List<UserRole>();

        for (String devName : developerNames) {
            result.add(cachedRoles.get(devName));
        }

        return result;
    }


    /**
     * @return UserRole record by given Id or null
     */
    public UserRole selectById(Id userRoleId) {
        return cachedRoles.get(userRoleId);
    }


    /**
     * @return UserRoles Map (mapped by Id) by given ids
     */
    public Map<Id, UserRole> selectMapByIds(Set<Id> userRoleIds) {
        return new Map<Id, UserRole>(selectByIds(userRoleIds));
    }


    /**
     * @return UserRoles by given ids
     */
    public UserRole[] selectByIds(Set<Id> userRoleIds) {
        List<UserRole> result = new List<UserRole>();

        for (Id userRoleId : userRoleIds) {
            result.add(cachedRoles.get(userRoleId));
        }

        return result;
    }


    /**
     * @return DeveloperName of UserRole with given Id
     */
    public String selectDeveloperNameById(Id userRoleId) {
        return cachedRoles.get(userRoleId).DeveloperName;
    }
}