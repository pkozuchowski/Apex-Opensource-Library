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
 * @author Piotr Kozuchowski <piotr.kozuchowski@weare4c.com>
 * @date 2018-08-09
 */
public class UserSelector {

    /**
     * @return Map of Users by Usernames for given usernames
     */
    public Map<String, User> getUsersByUsernamesMap(List<String> usernames) {
        List<User> users = getUsersByUsernames(usernames);

        Map<String, User> userByUsername = new Map<String, User>();
        for (User user : users) {
            userByUsername.put(user.Username, user);
        }

        return userByUsername;
    }

    public User getCurrentUser() {
        return getUserById(UserInfo.getUserId());
    }

    /**
     * @return User records with given Id or null if user does not exist.
     */
    public User getUserById(Id userId) {
        List<User> users = [
                SELECT Id,
                        Name,
                        Username
                FROM User
                WHERE Id = :userId
        ];
        return users.isEmpty() ? null : users.get(0);
    }

    /**
     * @return User records with given UserName or null if user does not exist.
     */
    public User getUserByUsername(String username) {
        List<User> users = getUsersByUsernames(new List<String>{username});
        return users.isEmpty() ? null : users.get(0);
    }

    /**
     * @return User with given usernames.
     */
    public List<User> getUsersByUsernames(List<String> usernames) {
        return [
                SELECT Id,
                        Name,
                        Username
                FROM User
                WHERE Username IN :usernames
        ];
    }
}