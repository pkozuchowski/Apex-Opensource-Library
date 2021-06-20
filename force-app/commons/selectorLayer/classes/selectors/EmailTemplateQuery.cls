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
 * Selector layer for Email Templates.
 * By default templates are queried without body for saving heap space.
 */
public inherited sharing class EmailTemplateQuery extends Query {

    public EmailTemplateQuery() {
        super(new List<String>{
            'Id',
            'Name',
            'DeveloperName',
            'Subject',
            'IsActive'
        }, EmailTemplate.SObjectType);
    }


    /**
     * Email Templates are queried with Html body.
     * By default, this field is omitted for Heap saving.
     */
    public EmailTemplateQuery withHtmlBody() {
        this.queryBuilder.addField(EmailTemplate.HtmlValue);
        return this;
    }

    /**
     * Email Templates are queried with Text body.
     * By default, this field is omitted for Heap saving.
     */
    public EmailTemplateQuery withTextBody() {
        this.queryBuilder.addField(EmailTemplate.Body);
        return this;
    }


    /**
     * @return Email Template by given name or null
     */
    public EmailTemplateQuery byDeveloperName(String developerName) {
        return byDeveloperName(new Set<String>{developerName});
    }

    /**
     * @return Email Templates By given names
     */
    public EmailTemplateQuery byDeveloperName(Set<String> developerNames) {
        return (EmailTemplateQuery) byField(EmailTemplate.DeveloperName, 'IN', developerNames);
    }
}