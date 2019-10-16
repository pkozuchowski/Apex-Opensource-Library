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
 * @see ProfileSelectorTest
 */
public inherited sharing class ProfileSelector {
    private static SObjectCache cache = new SObjectCache([
            SELECT Id,
                    Name
            FROM Profile

    ], new List<SObjectField>{
            Profile.Id,
            Profile.Name
    });


    /**
     * @return Profile record by given name or null
     */
    public Profile selectByName(String name) {
        return (Profile) cache.retrieveFirst(Profile.Name, name);
    }


    /**
     * @return Profile records by given names.
     */
    public Profile[] selectByNames(Set<String> names) {
        return cache.retrieve(Profile.Name, new List<String>(names));
    }


    /**
     * @return Profile record with given Id
     */
    public Profile selectById(Id profileId) {
        return (Profile) cache.retrieveFirst(Profile.Id, profileId);
    }


    /**
     * @return Profile records by given ids
     */
    public Profile[] selectByIds(Set<Id> profileIds) {
        return cache.retrieve(Profile.Id, new List<Id>(profileIds));
    }
}