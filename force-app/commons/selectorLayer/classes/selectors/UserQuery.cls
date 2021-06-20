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
 * @see UserQueryTest
 */
public inherited sharing class UserQuery extends Query {

    public UserQuery() {
        super(new List<String>{
            'Id',
            'Name',
            'FirstName',
            'LastName',
            'Username',
            'Email'
        }, User.SObjectType);
    }


    /**
     * Filters User records with given name or null if user does not exist.
     */
    public UserQuery byName(String name) {
        return byName(new Set<String>{name});
    }

    /**
     * Filters User with given names.
     */
    public UserQuery byName(Set<String> names) {
        return (UserQuery) byField(User.Name, 'IN', names);
    }

    /**
     * Filters User records with given email or null if user does not exist.
     */
    public UserQuery byEmail(String email) {
        return byEmail(new Set<String>{email});
    }

    /**
     * Filters User with given emails.
     */
    public UserQuery byEmail(Set<String> emails) {
        return (UserQuery) byField(User.Email, 'IN', emails);
    }

    /**
     * Filters User records with given UserName or null if user does not exist.
     */
    public UserQuery byUsername(String username) {
        return byUsername(new Set<String>{username});
    }

    /**
     * Filters User with given usernames.
     */
    public UserQuery byUsername(Set<String> usernames) {
        return (UserQuery) byField(User.Username, 'IN', usernames);
    }

    /**
     * Filters User record identified by UserInfo.getUserId().
     */
    public User getCurrentUser() {
        return (User) byId(UserInfo.getUserId()).getFirstOrNull();
    }

    protected override Set<String> getFieldsToCacheBy() {
        return new Set<String>{
            'Id',
            'Username'
        };
    }

}