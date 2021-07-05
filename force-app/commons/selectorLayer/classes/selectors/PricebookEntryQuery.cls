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
 * Selector layer for PricebookEntry SObject.
 */
public inherited sharing class PricebookEntryQuery extends Query {

    public PricebookEntryQuery() {
        super(PricebookEntry.SObjectType);
        selectFields(Query.Fields.STANDARD);
    }


    /**
     * Filters PricebookEntry record with given name or null.
     */
    public PricebookEntryQuery byProductId(Id productId) {
        return byProductId(new Set<Id>{productId});
    }

    /**
     * Filters PricebookEntry records with given productIds.
     */
    public PricebookEntryQuery byProductId(Set<Id> productIds) {
        return (PricebookEntryQuery) byField(PricebookEntry.Product2Id, 'IN', productIds);
    }


    /**
     * Filters PricebookEntry record with given name or null.
     */
    public PricebookEntryQuery byPricebookId(Id pricebookId) {
        return byPricebookId(new Set<Id>{pricebookId});
    }

    /**
     * Filters PricebookEntry records with given pricebookIds.
     */
    public PricebookEntryQuery byPricebookId(Set<Id> pricebookIds) {
        return (PricebookEntryQuery) byField(PricebookEntry.Pricebook2Id, 'IN', pricebookIds);
    }
}