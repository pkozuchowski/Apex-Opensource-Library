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

@IsTest
public class BatchSchedulableTest implements Database.Batchable<Integer> {

    public void execute(Database.BatchableContext param1, List<Integer> param2) {
    }

    public void finish(Database.BatchableContext param1) {
    }

    public Iterable<Integer> start(Database.BatchableContext param1) {
        return new List<Integer>{1, 2, 3, 4, 5};
    }


    @IsTest
    static void testSchedulableUsingNameConstructor() {
        BatchSchedulable schedulable = new BatchSchedulable('BatchSchedulableTest');

        Test.startTest();
        System.schedule('Test Batch Schedulable', '0 0 0 ? * * *', schedulable);
        Test.stopTest();
    }

    @IsTest
    static void testSchedulableUsingNameAndBatchSizeConstructor() {
        BatchSchedulable schedulable = new BatchSchedulable('BatchSchedulableTest', 10);

        Test.startTest();
        System.schedule('Test Batch Schedulable', '0 0 0 ? * * *', schedulable);
        Test.stopTest();
    }

    @IsTest
    static void testSchedulableUsingBatchConstructor() {
        BatchSchedulable schedulable = new BatchSchedulable(
                (Database.Batchable<SObject>) new BatchSchedulableTest()
        );

        Test.startTest();
        System.schedule('Test Batch Schedulable', '0 0 0 ? * * *', schedulable);
        Test.stopTest();
    }

    @IsTest
    static void testSchedulableUsingBatchAndBatchSizeConstructor() {
        BatchSchedulable schedulable = new BatchSchedulable(
                (Database.Batchable<SObject>) new BatchSchedulableTest(),
                10
        );

        Test.startTest();
        System.schedule('Test Batch Schedulable', '0 0 0 ? * * *', schedulable);
        Test.stopTest();
    }

    @IsTest
    static void testNotInstanceableClass() {
        try {
            BatchSchedulable schedulable = new BatchSchedulable('__FakeBatchTest');

            Test.startTest();
            System.schedule('Test Batch Schedulable', '0 0 0 ? * * *', schedulable);
            Test.stopTest();

            System.assert(false);
        } catch (Exception ex) {
            System.assert(ex instanceof TypeException);
        }
    }
}