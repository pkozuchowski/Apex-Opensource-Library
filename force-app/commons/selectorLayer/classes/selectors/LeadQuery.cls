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
public inherited sharing class LeadQuery extends QueryObject {

    public override List<String> getFields() {
        return new List<String>{
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
        };
    }

    public override SObjectType getSObjectType() {
        return Lead.SObjectType;
    }


    /**
     * Filters Leads by given name
     */
    public LeadQuery byName(String name) {
        return byName(new List<String>{name});
    }

    /**
     * Filters Leads by given names (List or Set)
     */
    public LeadQuery byName(Iterable<String> names) {
        return (LeadQuery) byField(Lead.Name, 'IN', names);
    }

    /**
     * Filters Leads by given email
     */
    public LeadQuery byEmail(String email) {
        return byEmail(new List<String>{email});
    }

    /**
     * Filters Leads by given emails (List or Set)
     */
    public LeadQuery byEmail(Iterable<String> emails) {
        return (LeadQuery) byField(Lead.Email, 'IN', emails);
    }

    /**
     * Filters Leads by given company
     */
    public LeadQuery byCompany(String company) {
        return byCompany(new List<String>{company});
    }

    /**
     * Filters Leads by given companies (List or Set)
     */
    public LeadQuery byCompany(Iterable<String> companies) {
        return (LeadQuery) byField(Lead.Company, 'IN', companies);
    }


    protected override Set<SObjectField> getFieldsToCacheBy() {
        return new Set<SObjectField>{
                Lead.Id
        };
    }
}