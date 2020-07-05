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
public inherited sharing class UserQuery extends QueryObject {

    public override List<SObjectField> getFields() {
        return new List<SObjectField>{
                User.Id,
                User.Name,
                User.FirstName,
                User.LastName,
                User.Username,
                User.Email
        };
    }

    public override SObjectType getSObjectType() {
        return User.SObjectType;
    }


    /**
     * Filters User records with given name or null if user does not exist.
     */
    public UserQuery byName(String name) {
        return byName(new List<String>{name});
    }

    /**
     * Filters User with given names.
     */
    public UserQuery byName(List<String> names) {
        return (UserQuery) byField(User.Name, 'IN', names);
    }

    /**
     * Filters User records with given email or null if user does not exist.
     */
    public UserQuery byEmail(String email) {
        return byEmail(new List<String>{email});
    }

    /**
     * Filters User with given emails.
     */
    public UserQuery byEmail(List<String> emails) {
        return (UserQuery) byField(User.Email, 'IN', emails);
    }

    /**
     * Filters User records with given UserName or null if user does not exist.
     */
    public UserQuery byUsername(String username) {
        return byUsername(new List<String>{username});
    }

    /**
     * Filters User with given usernames.
     */
    public UserQuery byUsername(List<String> usernames) {
        return (UserQuery) byField(User.Username, 'IN', usernames);
    }

    /**
     * Filters User record identified by UserInfo.getUserId().
     */
    public User getCurrentUser() {
        return (User) byId(UserInfo.getUserId()).getFirstOrNull();
    }

    protected override Set<SObjectField> getFieldsToCacheBy() {
        return new Set<SObjectField>{
                User.Id,
                User.Username
        };
    }

}