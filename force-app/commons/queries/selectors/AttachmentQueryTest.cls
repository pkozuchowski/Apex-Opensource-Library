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
public inherited sharing class AttachmentQueryTest {


    @IsTest
    static void testSelectByParentAndName() {
        AttachmentQuery attachmentQuery = new AttachmentQuery()
            .byParentIdAndName('001000000000000', 'Test');
        String query = attachmentQuery.toSOQL();

        Assert.isTrue(query.containsIgnoreCase('FROM Attachment'));
        Assert.isTrue(query.containsIgnoreCase('WHERE ((ParentId IN :var0) AND (Name = :var1))'));
        Assert.areEqual(new Set<Id>{'001000000000000'}, attachmentQuery.getBinding(':var0'));
        Assert.areEqual('Test', attachmentQuery.getBinding(':var1'));
    }
}