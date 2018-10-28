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
    public Id getUserRoleIdByDeveloperName(String developerName) {
        return cachedRoles.containsKey(developerName) ? cachedRoles.get(developerName).Id : null;
    }

    /**
     * @return UserRole record by given name or null
     */
    public UserRole getUserRoleByDeveloperName(String developerName) {
        return cachedRoles.get(developerName);
    }

    /**
     * @return UserRole record by given Id or null
     */
    public UserRole getUserRoleById(Id userRoleId) {
        return cachedRoles.get(userRoleId);
    }

    /**
     * @return DeveloperName of UserRole with given Id
     */
    public String getUserRoleDeveloperNameById(Id userRoleId) {
        return cachedRoles.get(userRoleId).DeveloperName;
    }
}