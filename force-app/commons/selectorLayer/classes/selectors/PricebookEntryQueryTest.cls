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
@IsTest
private class PricebookEntryQueryTest {

    @TestSetup
    static void testSetup() {
        List<Product2> product2s = new List<Product2>{
                new Product2(Name = 'Name 1', ProductCode = 'Code 1', ExternalId = 'Code 1', IsActive = true),
                new Product2(Name = 'Name 2', ProductCode = 'Code 2', ExternalId = 'Code 2', IsActive = true),
                new Product2(Name = 'Name 3', ProductCode = 'Code 3', ExternalId = 'Code 3', IsActive = true)
        };
        insert product2s;

        Id std = Test.getStandardPricebookId();
        insert new List<PricebookEntry>{
                new PricebookEntry(Pricebook2Id = std, Product2Id = product2s[0].Id, UnitPrice = 1),
                new PricebookEntry(Pricebook2Id = std, Product2Id = product2s[1].Id, UnitPrice = 2),
                new PricebookEntry(Pricebook2Id = std, Product2Id = product2s[2].Id, UnitPrice = 3)
        };
    }


    @IsTest
    static void testSelectByPricebookId() {
        Id std = Test.getStandardPricebookId();
        QueryObjectTest.assertEquals(
                ([SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :std]),
                new PricebookEntryQuery().byPricebookId(std).getList());
    }

    @IsTest
    static void testSelectByProductId() {
        List<Product2> product2s = [SELECT Id FROM Product2];

        QueryObjectTest.assertEquals(
                ([SELECT Id FROM PricebookEntry WHERE Product2Id = :product2s[0].Id]),
                new PricebookEntryQuery().byProductId(product2s[0].Id).getList());
    }
}