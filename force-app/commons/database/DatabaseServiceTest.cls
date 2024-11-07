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
@IsTest(IsParallel=false)
private class DatabaseServiceTest {
    private static final String STR = 'DatabaseServiceTest@test.com';

    private static Integer counter = 0;


    @IsTest
    static void testDML() {
        Account acc = new Account(
            Name = 'Test'
        );

        coverDatabaseServiceMethods(new DatabaseService(), acc);
        coverDatabaseServiceMethods(new DatabaseService().withSharing(), acc);
        coverDatabaseServiceMethods(new DatabaseService().withoutSharing(), acc);
        coverDatabaseServiceMethods(new DatabaseService().asSystem(), acc);
        coverDatabaseServiceMethods(new DatabaseService().asUser(), acc);
    }

    private static void coverDatabaseServiceMethods(DatabaseService databaseService, Account acc) {
        acc.Id = null;
        acc.Name += (counter++);

        databaseService.setDMLOptions(new DMLOptionsBuilder()
            .allowDuplicates(true)
            .build());

        databaseService.insertRecord(acc);
        databaseService.updateRecord(acc);
        databaseService.upsertRecord(acc, Account.Id);
        databaseService.deleteRecord(acc);
        databaseService.undeleteRecord(acc);
        databaseService.query('SELECT ID FROM Account');
        databaseService.getCursor('SELECT ID FROM Account', null);
        databaseService.getQueryLocator('SELECT ID FROM Account');
    }

    @IsTest
    static void testQuery() {
        DatabaseService databaseService = new DatabaseService();

        List<User> expected = [SELECT Id FROM User LIMIT 5];
        databaseService.withSharing();
        List<User> actual = databaseService.query('SELECT ID FROM User WHERE ID IN :users', new Map<String, Object>{'users' => expected});
        Database.QueryLocator queryLocator = databaseService.getQueryLocator('SELECT ID FROM User WHERE ID IN :users', new Map<String, Object>{'users' => expected});

        System.assertEquals(
            new Map<Id, User>(expected).keySet(),
            new Map<Id, User>(actual).keySet()
        );


        databaseService.withoutSharing();
        actual = databaseService.query('SELECT ID FROM User WHERE ID IN :users', new Map<String, Object>{'users' => expected});
        queryLocator = databaseService.getQueryLocator('SELECT ID FROM User WHERE ID IN :users', new Map<String, Object>{'users' => expected});

        System.assertEquals(
            new Map<Id, User>(expected).keySet(),
            new Map<Id, User>(actual).keySet()
        );

        databaseService.asUser();
        actual = databaseService.query('SELECT ID FROM User WHERE ID IN :users', new Map<String, Object>{'users' => expected});
        queryLocator = databaseService.getQueryLocator('SELECT ID FROM User WHERE ID IN :users', new Map<String, Object>{'users' => expected});

        System.assertEquals(
            new Map<Id, User>(expected).keySet(),
            new Map<Id, User>(actual).keySet()
        );

        databaseService.asSystem();
        actual = databaseService.query('SELECT ID FROM User WHERE ID IN :users', new Map<String, Object>{'users' => expected});
        queryLocator = databaseService.getQueryLocator('SELECT ID FROM User WHERE ID IN :users', new Map<String, Object>{'users' => expected});

        System.assertEquals(
            new Map<Id, User>(expected).keySet(),
            new Map<Id, User>(actual).keySet()
        );
    }
}