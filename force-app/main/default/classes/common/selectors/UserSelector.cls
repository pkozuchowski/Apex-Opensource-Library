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
 * Selector layer for User sObject
 * @see UserSelectorTest
 */
public inherited sharing class UserSelector {

    /**
     * @return User records with given UserName or null if user does not exist.
     */
    public User selectByUsername(String username) {
        List<User> users = selectByUsernames(new List<String>{username});
        return users.isEmpty() ? null : users.get(0);
    }

    /**
     * @return User with given usernames.
     */
    public List<User> selectByUsernames(List<String> usernames) {
        return [
                SELECT Id,
                        Name,
                        Username
                FROM User
                WHERE Username IN :usernames
        ];
    }

    /**
     * @return User record identified by UserInfo.getUserId().
     */
    public User selectCurrentUser() {
        return selectById(UserInfo.getUserId());
    }

    /**
     * @return User records with given Id or null if user does not exist.
     */
    public User selectById(Id userId) {
        List<User> users = selectByIds(new Set<Id>{userId});
        return users.isEmpty() ? null : users.get(0);
    }

    /**
     * @return User records with given Id or null if user does not exist.
     */
    public User[] selectByIds(Set<Id> userIds) {
        return [
                SELECT Id,
                        Name,
                        Username
                FROM User
                WHERE Id IN :userIds
        ];
    }
}