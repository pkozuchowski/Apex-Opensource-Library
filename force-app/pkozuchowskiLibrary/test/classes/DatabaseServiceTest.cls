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
@IsTest(IsParallel=true)
private class DatabaseServiceTest {

    /**
     * Replace the content with TestDataFactory.createAccount() to match
     * your environment needs.
     */
    private static Account getTestAccount() {
        return new Account(
                Name = 'Test'
        );
    }


    @IsTest
    static void coverageTestWithSharing() {
        Account acc = getTestAccount();


        DatabaseService databaseService = new DatabaseService()
                .setSharing(Sharing.WITH_SHARING)
                .setDMLOptions(new DMLOptionsBuilder()
                        .allowDuplicates(true)
                        .build()
                );

        databaseService.doInsert(acc);
        databaseService.doUpdate(acc);
        databaseService.doUpsert(acc, Account.Id);
        databaseService.doDelete(acc);
        databaseService.doUndelete(acc);
        databaseService.query('SELECT ID FROM Account');
    }

    @IsTest
    static void coverageTestWithoutSharing() {
        Account acc = getTestAccount();


        DatabaseService databaseService = new DatabaseService()
                .setSharing(Sharing.WITHOUT_SHARING)
                .setDMLOptions(new DMLOptionsBuilder()
                        .allowDuplicates(true)
                        .build()
                );

        databaseService.doInsert(acc);
        databaseService.doUpdate(acc);
        databaseService.doUpsert(acc, Account.Id);
        databaseService.doDelete(acc);
        databaseService.doUndelete(acc);
        databaseService.query('SELECT ID FROM Account');
    }

    @IsTest
    static void coverageTestWithInheritedSharing() {
        Account acc = getTestAccount();


        DatabaseService databaseService = new DatabaseService()
                .setSharing(Sharing.INHERITED_SHARING)
                .setDMLOptions(new DMLOptionsBuilder()
                        .allowDuplicates(true)
                        .build()
                );

        databaseService.doInsert(acc);
        databaseService.doUpdate(acc);
        databaseService.doUpsert(acc, Account.Id);
        databaseService.doDelete(acc);
        databaseService.doUndelete(acc);
        databaseService.query('SELECT ID FROM Account');
    }
}