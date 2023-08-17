/*
 * *
 *  MIT License
 *
 *  Copyright (c) 2023 Piotr Kożuchowski
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 * /
 * *
 *  Please find newest source code at https://github.com/amorek/Apex-Opensource-Library
 * /
 */
@IsTest
public with sharing class MockTest {

    @IsTest
    static void testReturnsOriginal() {
        ClientClass c = new ClientClass();
        Account account = c.getAccounts();

        Assert.areEqual('Original Account', account.Name);
    }

    @IsTest
    static void testReturnsMock() {
        ClientClass c = new ClientClass();
        c.accountSelector = (ServiceClass) Mock.response(ServiceClass.class,
            'getAccount', new Account(Name = 'Another'));

        Account account = c.getAccounts();

        Assert.areEqual('Another', account.Name);
    }

    @IsTest
    static void testReturnsMockOnSecond() {
        ClientClass c = new ClientClass();
        c.accountSelector = (ServiceClass) Mock.response(ServiceClass.class, new Map<String, Object>{
            'getAccount' => new Account(Name = 'First Run'),
            'getAccount#2' => new Account(Name = 'Second Run'),
            'getAccount#3' => new Account(Name = 'Third Run')
        });


        Assert.areEqual('First Run', c.getAccounts(). Name);
        Assert.areEqual('Second Run', c.getAccounts().Name);
        Assert.areEqual('Third Run', c.getAccounts().Name);
    }

    @IsTest
    static void testException() {
        ClientClass c = new ClientClass();
        c.accountSelector = (ServiceClass) Mock.response(ServiceClass.class, 'getAccount', new QueryException('Whoops'));

        try {
            c.getAccounts();
            Assert.fail();
        } catch (Exception e) {
            Assert.isInstanceOfType(e, QueryException.class);
            Assert.areEqual('Whoops', e.getMessage());
        }
    }
}