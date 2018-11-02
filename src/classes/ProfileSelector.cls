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
 */
public inherited sharing class ProfileSelector {
    private final static Map<String, Profile> cachedProfiles = new Map<String, Profile>();
    static {
        List<Profile> profiles = [
                SELECT Id,
                        Name
                FROM Profile
        ];

        for (Profile profile : profiles) {
            cachedProfiles.put(profile.Id, profile);
            cachedProfiles.put(profile.Name, profile);
        }
    }


    /**
     * @return Id of profile with given name or null
     */
    public Id selectIdByName(String name) {
        return cachedProfiles.containsKey(name) ? cachedProfiles.get(name).Id : null;
    }


    /**
     * @return Profile record by given name or null
     */
    public Profile selectByName(String name) {
        return cachedProfiles.get(name);
    }


    /**
     * @return Profile records by given names.
     */
    public Profile[] selectByNames(Set<String> names) {
        List<Profile> result = new List<Profile>();

        for (String name : names) {
            result.add(cachedProfiles.get(name));
        }

        return result;
    }


    /**
     * @return Profile record with given Id
     */
    public Profile selectById(Id profileId) {
        return cachedProfiles.get(profileId);
    }


    /**
     * @return Profile records by given ids
     */
    public Profile[] selectByIds(Set<Id> profileIds) {
        List<Profile> result = new List<Profile>();

        for (Id profileId : profileIds) {
            result.add(cachedProfiles.get(profileId));
        }

        return result;
    }


    /**
     * @return Name of profile with given Id.
     */
    public String selectNameById(Id profileId) {
        return cachedProfiles.containsKey(profileId) ? cachedProfiles.get(profileId).Name : null;
    }
}