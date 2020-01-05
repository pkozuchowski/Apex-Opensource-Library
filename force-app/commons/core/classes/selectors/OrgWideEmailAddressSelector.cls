/**
* MIT License
*
* Copyright (c) 2019 Piotr Kożuchowski
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
 * Selector Layer for Org wide email addresses.
 * Cached for limits savings.
 */
public inherited sharing class OrgWideEmailAddressSelector {
    private static SObjectCache cache = new SObjectCache([
            SELECT Id,DisplayName,Address,IsAllowAllProfiles
            FROM OrgWideEmailAddress

    ], new List<SObjectField>{
            OrgWideEmailAddress.Id,
            OrgWideEmailAddress.DisplayName,
            OrgWideEmailAddress.Address
    });


    /**
     * @return OrgWideEmailAddress by given Id or null
     */
    public OrgWideEmailAddress byId(Id orgWideId) {
        return (OrgWideEmailAddress) cache.retrieveFirst(OrgWideEmailAddress.Id, orgWideId);
    }

    /**
     * @return OrgWideEmailAddress by given ids (List or Set)
     */
    public OrgWideEmailAddress[] byId(Iterable<Id> orgWideIds) {
        return cache.retrieveAll(OrgWideEmailAddress.Id, orgWideIds);
    }


    /**
     * @return OrgWideEmailAddress by given Display Names or null
     */
    public OrgWideEmailAddress[] byDisplayName(String name) {
        return byDisplayName(new List<String>{name});
    }

    /**
     * @return OrgWideEmailAddress by given Display Names (List or Set)
     */
    public OrgWideEmailAddress[] byDisplayName(Iterable<String> names) {
        return cache.retrieveAll(OrgWideEmailAddress.DisplayName, names);
    }


    /**
     * @return OrgWideEmailAddress by given Email Address or null
     */
    public OrgWideEmailAddress byAddress(String address) {
        return (OrgWideEmailAddress) cache.retrieveFirst(OrgWideEmailAddress.Address, address);
    }

    /**
     * @return OrgWideEmailAddress by given Email Addresses (List or Set)
     */
    public OrgWideEmailAddress[] byAddress(Iterable<String> names) {
        return cache.retrieveAll(OrgWideEmailAddress.Address, names);
    }
}