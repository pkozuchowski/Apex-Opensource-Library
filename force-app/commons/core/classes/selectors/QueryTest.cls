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
private class QueryTest {

    @IsTest
    static void coverage() {
        Query.Accounts.byId('001000000000000');
        Query.BusinessHours.byId('001000000000000');
        Query.Cases.byId('001000000000000');
        Query.Contacts.byId('001000000000000');
        Query.EmailTemplates.byId('001000000000000');
        Query.Leads.byId('001000000000000');
        Query.Opportunities.byId('001000000000000');
        Query.PermissionSets.byId('001000000000000');
        Query.Pricebooks.byId('001000000000000');
        Query.Profiles.byId('001000000000000');
        Query.Queues.byId('001000000000000');
        Query.UserRoles.byId('001000000000000');
        Query.Users.byId('001000000000000');
        Query.SObjectShares(MacroShare.SObjectType).byId('001000000000000');
        Query.SObjectHistory(MacroShare.SObjectType).byId('001000000000000');
        Query.RecordTypes.byDeveloperName(Account.SObjectType, '');
    }
}