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
private class ContentDocumentQueryTest {

    @TestSetup
    static void testSetup() {
        Account account = new Account(Name = 'Test');
        insert account;

        ContentVersion contentVersionInsert = new ContentVersion(
                Title = 'Test',
                PathOnClient = 'Test.jpg',
                VersionData = Blob.valueOf('Test Data'),
                IsMajorVersion = true
        );
        insert contentVersionInsert;

        ContentDocument document = [SELECT Id FROM ContentDocument];

        insert new ContentDocumentLink(
                LinkedEntityId = account.Id,
                ContentDocumentId = document.Id,
                ShareType = 'I'
        );
    }

    @IsTest
    static void testSelectByLinkedEntityId() {
        Account account = [SELECT Id FROM Account];
        ContentDocument[] documents = new ContentDocumentQuery().byLinkedEntityId(account.Id).getList();

        System.assertEquals(1, documents.size());
        System.assertEquals('Test', documents[0].LatestPublishedVersion.Title);
    }
}