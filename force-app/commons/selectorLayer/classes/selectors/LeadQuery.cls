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
 * Selector layer for Lead SObjects
 */
public inherited sharing class LeadQuery extends Query {

    public LeadQuery() {
        super(new List<String>{
            'Id',
            'FirstName',
            'LastName',
            'Name',
            'Phone',
            'Country',
            'City',
            'Street',
            'PostalCode',
            'Industry'
        }, Lead.SObjectType);
    }


    /**
     * Filters Leads by given name
     */
    public LeadQuery byName(String name) {
        return byName(new Set<String>{name});
    }

    /**
     * Filters Leads by given names
     */
    public LeadQuery byName(Set<String> names) {
        return (LeadQuery) byField(Lead.Name, 'IN', names);
    }

    /**
     * Filters Leads by given email
     */
    public LeadQuery byEmail(String email) {
        return byEmail(new Set<String>{email});
    }

    /**
     * Filters Leads by given emails
     */
    public LeadQuery byEmail(Set<String> emails) {
        return (LeadQuery) byField(Lead.Email, 'IN', emails);
    }

    /**
     * Filters Leads by given company
     */
    public LeadQuery byCompany(String company) {
        return byCompany(new Set<String>{company});
    }

    /**
     * Filters Leads by given companies
     */
    public LeadQuery byCompany(Set<String> companies) {
        return (LeadQuery) byField(Lead.Company, 'IN', companies);
    }


    protected override Set<String> getFieldsToCacheBy() {
        return new Set<String>{
            'Id'
        };
    }
}