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

/**
 * Generic schedulable for all kinds of batch classes which should eliminate
 * all schedules that do not have any other logic, but executing certain batch class.
 *
 * Batches scheduled with this class are not locked for editing.
 * @see BatchSchedulableTest
 */
public class BatchSchedulable implements Schedulable {
    private Database.Batchable<SObject> batchInstance;
    private Integer batchSize;

    public BatchSchedulable(String batchName) {
        this(getInstance(batchName));
    }

    public BatchSchedulable(String batchName, Integer batchSize) {
        this(getInstance(batchName), batchSize);
    }

    public BatchSchedulable(Database.Batchable<SObject> batchInstance) {
        this(batchInstance, 200);
    }

    public BatchSchedulable(Database.Batchable<SObject> batchInstance, Integer batchSize) {
        this.batchInstance = batchInstance;
        this.batchSize = batchSize;
    }

    public void execute(SchedulableContext scx) {
        Database.executeBatch(batchInstance, batchSize);
    }


    private static Database.Batchable<SObject> getInstance(String name) {
        try {
            Type batchType = Type.forName(name);
            return (Database.Batchable<SObject>) batchType.newInstance();
        } catch (Exception ex) {
            throw new TypeException('Failed to create instance of "' + name + '".\n' +
                    'Make sure that class name is correct and class has public accessor and no-args constructor.');
        }
    }
}