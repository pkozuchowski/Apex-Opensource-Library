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
 * Selector layer for Product2 SObjects
 * Use through Query facade:
 * Query.Products.byName(...);
 */
public virtual inherited sharing class ProductQuery extends Query {

    public ProductQuery() {
        super(new List<String>{
            'Id',
            'Description',
            'ExternalId',
            'IsActive',
            'Name',
            'ProductCode'
        }, Product2.SObjectType);
    }


    /**
     * Adds pricebook entries to all Pricebooks
     */
    public ProductQuery withPricebookEntries() {
        selectSubquery(new List<String>{
            'Id'
        }, 'PricebookEntries');
        return this;
    }

    /**
     * Adds pricebook entries to given pricebook
     */
    public ProductQuery withPricebookEntries(Id pricebookId) {
        return withPricebookEntries(new Set<Id>{pricebookId});
    }

    /**
     * Adds pricebook entries to given pricebooks
     */
    public ProductQuery withPricebookEntries(Set<Id> pricebookIds) {
        this.selectSubquery(
            Query.fromSObject(PricebookEntry.SObjectType)
                 .selectFields(new List<String>{
                    'Id'
                 })
                 .byField('Pricebook2Id', 'IN', pricebookIds),
            'PricebookEntries');

        return this;
    }


    /**
     * Filters Product2s with given name
     */
    public ProductQuery byName(String name) {
        return byName(new Set<String>{name});
    }

    /**
     * Filters Product2s with given names
     */
    public ProductQuery byName(Set<String> names) {
        return (ProductQuery) byField(Product2.Name, 'IN', names);
    }

    /**
     * Filters Product2s with given name
     */
    public ProductQuery byProductCode(String productCode) {
        return byProductCode(new Set<String>{productCode});
    }

    /**
     * Filters Product2s with given names
     */
    public ProductQuery byProductCode(Set<String> productCodes) {
        return (ProductQuery) byField(Product2.ProductCode, 'IN', productCodes);
    }

    /**
     * Filters Product2s with given name
     */
    public ProductQuery byExternalId(String externalId) {
        return byExternalId(new Set<String>{externalId});
    }

    /**
     * Filters Product2s with given names
     */
    public ProductQuery byExternalId(Set<String> externalIds) {
        return (ProductQuery) byField(Product2.ExternalId, 'IN', externalIds);
    }
}