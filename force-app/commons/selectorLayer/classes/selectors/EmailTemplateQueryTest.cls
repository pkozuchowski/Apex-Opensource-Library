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
private class EmailTemplateQueryTest {

    @IsTest
    static void testSelectByDeveloperName() {

        try {
            EmailTemplate template = [
                    SELECT Id, Name,DeveloperName, HtmlValue, Body
                    FROM EmailTemplate
                    LIMIT 1
            ];


            EmailTemplate actual = (EmailTemplate) new EmailTemplateQuery()
                    .withHtmlBody()
                    .withTextBody()
                    .byDeveloperName(template.DeveloperName)
                    .getFirstOrNull();

            System.assertNotEquals(null, actual);
            System.assertEquals(template.DeveloperName, actual.DeveloperName);
            System.assertEquals(template.Body, actual.Body);
            System.assertEquals(template.HtmlValue, actual.HtmlValue);
            System.assertEquals(1, new EmailTemplateQuery().byDeveloperName(new Set<String>{template.DeveloperName}).getList().size());
        } catch (QueryException ex) {
            new EmailTemplateQuery()
                    .withHtmlBody()
                    .withTextBody()
                    .byDeveloperName('');
            System.assertEquals(0, new EmailTemplateQuery().byDeveloperName(new Set<String>{''}).getList().size());
        }
    }
}