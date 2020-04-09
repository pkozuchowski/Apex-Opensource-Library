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
public inherited sharing class UserSelector extends Selector {
    public final static List<SObjectField> QUERIED_FIELDS = new List<SObjectField>{
            User.Id,
            User.Name,
            User.FirstName,
            User.LastName,
            User.Username,
            User.Email
    };

    public UserSelector() {
        super(QUERIED_FIELDS, User.SObjectType);
    }


    /**
     * @return User records with given name or null if user does not exist.
     */
    public User byName(String name) {
        return (User) oneRecordByField(User.Name, '=', name);
    }

    /**
     * @return User with given names.
     */
    public User[] byName(List<String> names) {
        return byField(User.Name, 'IN', names);
    }

    /**
     * @return User records with given email or null if user does not exist.
     */
    public User byEmail(String email) {
        return (User) oneRecordByField(User.Email, '=', email);
    }

    /**
     * @return User with given emails.
     */
    public User[] byEmail(List<String> emails) {
        return byField(User.Email, 'IN', emails);
    }

    /**
     * @return User records with given UserName or null if user does not exist.
     */
    public User byUsername(String username) {
        return (User) oneRecordByField(User.Username, '=', username);
    }

    /**
     * @return User with given usernames.
     */
    public User[] byUsername(List<String> usernames) {
        return byField(User.Username, 'IN', usernames);
    }

    /**
     * @return User record identified by UserInfo.getUserId().
     */
    public User currentUser() {
        return (User) byId(UserInfo.getUserId());
    }

    protected override Set<SObjectField> getFieldsToCacheBy() {
        return new Set<SObjectField>{
                User.Id,
                User.Email,
                User.Username
        };
    }

}