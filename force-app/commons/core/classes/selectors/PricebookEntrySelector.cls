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
 * Selector layer for PricebookEntry SObject.
 * @see PricebookSelectorTest
 */
public inherited sharing class PricebookEntrySelector extends Selector {
    public final static List<SObjectField> QUERIED_FIELDS = new List<SObjectField>{
            PricebookEntry.Id,
            PricebookEntry.IsActive,
            PricebookEntry.Name,
            PricebookEntry.Pricebook2Id,
            PricebookEntry.Product2Id,
            PricebookEntry.UnitPrice,
            PricebookEntry.UseStandardPrice
    };

    public PricebookEntrySelector() {
        super(QUERIED_FIELDS, PricebookEntry.SObjectType);
        this.query.addParentFields(ProductSelector.QUERIED_FIELDS, PricebookEntry.Product2Id);
    }


    /**
     * @return PricebookEntry record with given name or null.
     */
    public PricebookEntry[] byProductId(Id productId) {
        return byField(PricebookEntry.Product2Id, '=', productId);
    }

    /**
     * @return PricebookEntry records with given productIds.
     */
    public PricebookEntry[] byProductId(Iterable<Id> productIds) {
        return byField(PricebookEntry.Product2Id, 'IN', productIds);
    }


    /**
     * @return PricebookEntry record with given name or null.
     */
    public PricebookEntry[] byPricebookId(Id pricebookId) {
        return byField(PricebookEntry.Pricebook2Id, '=', pricebookId);
    }

    /**
     * @return PricebookEntry records with given pricebookIds.
     */
    public PricebookEntry[] byPricebookId(Iterable<Id> pricebookIds) {
        return byField(PricebookEntry.Pricebook2Id, 'IN', pricebookIds);
    }
}