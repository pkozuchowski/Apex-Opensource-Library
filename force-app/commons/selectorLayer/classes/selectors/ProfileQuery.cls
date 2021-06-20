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
 * Selector Layer class for Profiles. Records are queried only once and cached to minimize SOQL limits usage.
 * @see ProfileQueryTest
 */
public inherited sharing class ProfileQuery extends Query {

    /**
     * Cache all profiles
     * */
    static {
        new ProfileQuery().getList();
    }

    public ProfileQuery() {
        super(new List<String>{
            'Id',
            'Name'
        }, Profile.SObjectType);
    }


    /**
    * Filters Profile of current user
    */
    public ProfileQuery byCurrentUser() {
        return (ProfileQuery) byField(Profile.Id, '=', UserInfo.getProfileId());
    }

    /**
     * Filters Profile record by given name or null
     */
    public ProfileQuery byName(String name) {
        return byName(new Set<String>{name});
    }


    /**
     * Filters Profile records by given names.
     */
    public ProfileQuery byName(Set<String> names) {
        return (ProfileQuery) byField(Profile.Name, 'IN', names);
    }


    protected override Set<String> getFieldsToCacheBy() {
        return new Set<String>{
            'Id',
            'Name'
        };
    }
}