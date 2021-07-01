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
 * Selector layer for Pricebook2 SObject.
 * @see PricebookQueryTest
 */
public inherited sharing class PricebookQuery extends Query {

    public PricebookQuery() {
        super(Pricebook2.SObjectType);
        selectFields(Query.Fields.STANDARD);
    }


    /**
     * Add Pricebook Entries to query
     */
    public PricebookQuery withEntries() {
        selectSubquery(new List<String>{
            'Id',
            'Product2Id'
        }, 'PricebookEntries');
        return this;
    }

    /**
     * Filters Pricebook2 record with given name or null.
     */
    public PricebookQuery byName(String name) {
        return byName(new Set<String>{name});
    }

    /**
     * Filters Pricebook2 records with given names.
     */
    public PricebookQuery byName(Set<String> names) {
        return (PricebookQuery) byField(Pricebook2.Name, 'IN', names);
    }

    /**
     * Filters Id of Standard Pricebook. In Unit Test context Test.getStandardPricebookId() value is returned.
     */
    public Id getStandardPricebookId() {
        if (Test.isRunningTest()) {
            return Test.getStandardPricebookId();
        } else {
            return byField(Pricebook2.IsStandard, '=', true).getFirstOrEmpty().Id;
        }
    }
}