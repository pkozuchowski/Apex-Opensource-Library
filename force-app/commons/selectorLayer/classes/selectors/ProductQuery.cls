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
public virtual inherited sharing class ProductQuery extends QueryObject {
    public final static List<SObjectField> QUERIED_FIELDS = new List<SObjectField>{
            Product2.Id,
            Product2.Description,
            Product2.ExternalId,
            Product2.IsActive,
            Product2.Name,
            Product2.ProductCode
    };

    public ProductQuery() {
        super(QUERIED_FIELDS, Product2.SObjectType);
    }

    /**
     * Adds pricebook entries to all Pricebooks
     */
    public ProductQuery withPricebookEntries() {
        this.query.addChildFields(PricebookEntryQuery.QUERIED_FIELDS, 'PricebookEntries');
        return this;
    }

    /**
     * Adds pricebook entries to given pricebook
     */
    public ProductQuery withPricebookEntries(Id pricebookId) {
        return withPricebookEntries(new List<Id>{pricebookId});
    }

    /**
     * Adds pricebook entries to given pricebooks
     */
    public ProductQuery withPricebookEntries(Iterable<Id> pricebookIds) {
        this.query.bindVariable('pricebookIds', pricebookIds);
        this.query.addSubquery(new QueryBuilder()
                .addFields(PricebookEntryQuery.QUERIED_FIELDS)
                .fromObject('PricebookEntries')
                .setWhere('Pricebook2Id IN :pricebookIds')
        );
        return this;
    }


    /**
     * @return Product2s with given name
     */
    public Product2[] byName(String name) {
        return byField(Product2.Name, '=', name);
    }

    /**
     * @return Product2s with given names (List or Set)
     */
    public Product2[] byName(Iterable<String> names) {
        return byField(Product2.Name, 'IN', names);
    }

    /**
     * @return Product2s with given name
     */
    public Product2[] byProductCode(String productCode) {
        return byField(Product2.ProductCode, '=', productCode);
    }

    /**
     * @return Product2s with given names (List or Set)
     */
    public Product2[] byProductCode(Iterable<String> productCodes) {
        return byField(Product2.ProductCode, 'IN', productCodes);
    }

    /**
     * @return Product2s with given name
     */
    public Product2[] byExternalId(String externalId) {
        return byField(Product2.ExternalId, '=', externalId);
    }

    /**
     * @return Product2s with given names (List or Set)
     */
    public Product2[] byExternalId(Iterable<String> externalIds) {
        return byField(Product2.ExternalId, 'IN', externalIds);
    }
}