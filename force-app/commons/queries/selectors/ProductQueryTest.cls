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
@IsTest(IsParallel=true)
private class ProductQueryTest {

    @IsTest
    static void testWithPricebookEntries() {
        ProductQuery productQuery = new ProductQuery().withPricebookEntries();
        QueryObjectTest.assertSOQLContains(productQuery, 'FROM PricebookEntries )');
    }

    @IsTest
    static void testWitSpecifichPricebookEntries() {
        ProductQuery productQuery = new ProductQuery().withPricebookEntries('01s000000000000');
        QueryObjectTest.assertSOQLContains(productQuery, 'FROM PricebookEntries WHERE (Pricebook2Id IN :var0)');
    }

    @IsTest
    static void testSelectByName() {
        ProductQuery productQuery = new ProductQuery().byName('Product Name');
        QueryObjectTest.assertSOQLContainsFieldInClause(productQuery, Product2.Name, new Set<String>{'Product Name'});
    }

    @IsTest
    static void testSelectByProductCode() {
        ProductQuery productQuery = new ProductQuery().byProductCode('productCode');
        QueryObjectTest.assertSOQLContainsFieldInClause(productQuery, Product2.ProductCode, new Set<String>{'productCode'});
    }

    @IsTest
    static void testSelectByExternalId() {
        ProductQuery productQuery = new ProductQuery().byExternalId('externalId');
        QueryObjectTest.assertSOQLContainsFieldInClause(productQuery, Product2.ExternalId, new Set<String>{'externalId'});
    }
}