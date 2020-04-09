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

    public LeadQuery() {
        super(new List<SObjectField>{
                Lead.Id,
                Lead.FirstName,
                Lead.LastName,
                Lead.Name,
                Lead.Phone,
                Lead.Country,
                Lead.City,
                Lead.Street,
                Lead.PostalCode,
                Lead.Industry
        }, Lead.SObjectType);
    }

    /**
     * @return Leads by given name
     */
    public Lead[] byName(String name) {
        return byField(Lead.Name, '=', name);
    }

    /**
     * @return Leads by given names (List or Set)
     */
    public Lead[] byName(Iterable<String> names) {
        return byField(Lead.Name, 'IN', names);
    }

    /**
     * @return Leads by given email
     */
    public Lead[] byEmail(String email) {
        return byField(Lead.Email, '=', email);
    }

    /**
     * @return Leads by given emails (List or Set)
     */
    public Lead[] byEmail(Iterable<String> emails) {
        return byField(Lead.Email, 'IN', emails);
    }

    /**
     * @return Leads by given company
     */
    public Lead[] byCompany(String company) {
        return byField(Lead.Company, '=', company);
    }

    /**
     * @return Leads by given companies (List or Set)
     */
    public Lead[] byCompany(Iterable<String> companies) {
        return byField(Lead.Company, 'IN', companies);
    }

    protected override Set<SObjectField> getFieldsToCacheBy() {
        return new Set<SObjectField>{
                Lead.Id
        };
    }
}