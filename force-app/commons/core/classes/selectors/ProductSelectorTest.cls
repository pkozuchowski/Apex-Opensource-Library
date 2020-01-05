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
private class ProductSelectorTest {

    @TestSetup
    static void testSetup() {
        insert new List<Product2>{
                new Product2(Name = 'Name 1', ProductCode = 'Code 1', ExternalId = 'Code 1', IsActive = true),
                new Product2(Name = 'Name 2', ProductCode = 'Code 2', ExternalId = 'Code 2', IsActive = true),
                new Product2(Name = 'Name 3', ProductCode = 'Code 3', ExternalId = 'Code 3', IsActive = true)
        };
    }

    @IsTest
    static void testWithEntries() {
        new ProductSelector()
                .withPricebookEntries()
                .withPricebookEntries('01s000000000000');
    }

    @IsTest
    static void testSelectByName() {
        SelectorTest.assertEquals(
                ([SELECT Id FROM Product2 WHERE Name = 'Name 1']),
                new ProductSelector().byName('Name 1'));

        SelectorTest.assertEquals(
                ([SELECT Id FROM Product2 WHERE Name IN ('Name 1', 'Name 2')]),
                new ProductSelector().byName(new List<String>{'Name 1', 'Name 2'}));
    }

    @IsTest
    static void testSelectByProductCode() {
        SelectorTest.assertEquals(
                ([SELECT Id FROM Product2 WHERE ProductCode = 'Code 1']),
                new ProductSelector().byProductCode('Code 1'));

        SelectorTest.assertEquals(
                ([SELECT Id FROM Product2 WHERE ProductCode IN ('Code 1', 'Code 2')]),
                new ProductSelector().byProductCode(new List<String>{'Code 1', 'Code 2'}));
    }

    @IsTest
    static void testSelectByExternalId() {
        SelectorTest.assertEquals(
                ([SELECT Id FROM Product2 WHERE ExternalId = 'Code 1']),
                new ProductSelector().byExternalId('Code 1'));

        SelectorTest.assertEquals(
                ([SELECT Id FROM Product2 WHERE ExternalId IN ('Code 1', 'Code 2')]),
                new ProductSelector().byExternalId(new List<String>{'Code 1', 'Code 2'}));
    }
}