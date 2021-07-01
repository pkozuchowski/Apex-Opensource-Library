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
public inherited sharing class OrgWideEmailAddressQuery extends Query {

    /**
     * Cache all records on first initialization
     */
    static {
        new OrgWideEmailAddressQuery().getList();
    }

    public OrgWideEmailAddressQuery() {
        super(OrgWideEmailAddress.SObjectType);
        this.selectFields(Query.Fields.STANDARD);
    }


    /**
     * @return OrgWideEmailAddress by given Display Names or null
     */
    public OrgWideEmailAddressQuery byDisplayName(String name) {
        return byDisplayName(new Set<String>{name});
    }

    /**
     * @return OrgWideEmailAddress by given Display Names
     */
    public OrgWideEmailAddressQuery byDisplayName(Set<String> names) {
        return (OrgWideEmailAddressQuery) byField(OrgWideEmailAddress.DisplayName, 'IN', names);
    }


    /**
     * @return OrgWideEmailAddress by given Email Address or null
     */
    public OrgWideEmailAddressQuery byAddress(String address) {
        return byAddress(new Set<String>{address});
    }

    /**
     * @return OrgWideEmailAddress by given Email Addresses
     */
    public OrgWideEmailAddressQuery byAddress(Set<String> names) {
        return (OrgWideEmailAddressQuery) byField(OrgWideEmailAddress.Address, 'IN', names);
    }


    protected override Set<String> getFieldsToCacheBy() {
        return new Set<String>{
            'Id',
            'Address',
            'DisplayName'
        };
    }
}