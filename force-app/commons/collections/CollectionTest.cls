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
private class CollectionTest {

    private static List<Opportunity> opportunities = new List<Opportunity>{
        newOpportunity(0, new Map<String, Object>{
            'NextStep' => 'Analysis'
        }),
        newOpportunity(1, new Map<String, Object>{
            'NextStep' => 'Analysis'
        }),
        newOpportunity(2, new Map<String, Object>{
            'NextStep' => 'Analysis'
        }),
        newOpportunity(3, new Map<String, Object>{
            'NextStep' => 'Analysis'
        }),
        newOpportunity(4, new Map<String, Object>{
            'NextStep' => 'Deal'
        }),
        newOpportunity(5, new Map<String, Object>{
            'NextStep' => 'Deal'
        }),
        newOpportunity(6, new Map<String, Object>{
            'NextStep' => 'Deal'
        }),
        newOpportunity(7, new Map<String, Object>{
            'NextStep' => 'Support'
        }),
        newOpportunity(8, new Map<String, Object>{
            'NextStep' => 'Support'
        }),
        newOpportunity(9, new Map<String, Object>{
            'NextStep' => 'Support'
        })
    };

    /**
     * Creates new Opportunity with fields prefilled for testing Collections.
     * Opportunity is created through JSON.deserialize, because some fields are not writable through constructor.
     */
    private static Opportunity newOpportunity(Integer i, Map<String, Object> opp) {
        Map<String, Object> oppMap = new Map<String, Object>{
            'Id' => '006' + ('' + i).leftPad(12, '0') + 'AAA',
            'AccountId' => '001' + ('' + Math.mod(i, 3)).leftPad(12, '0') + 'AAA',
            'OwnerId' => '005' + ('' + Math.mod(i, 5)).leftPad(12, '0') + 'AAA',
            'Name' => 'Test Opportunity ' + i,
            'CreatedDate' => Datetime.now().addDays(-i),
            'HasOpenActivity' => Math.mod(i, 2) == 0,
            'LastActivityDate' => Date.today().addDays(-i),
            'Probability' => 1.0 * i / 10,
            'Amount' => i * 100
        };
        oppMap.putAll(opp);

        return (Opportunity) JSON.deserialize(JSON.serialize(oppMap), Opportunity.class);
    }


    /**
     *@description
     * Collections.isNotEmpty() returns "true" when there's any element in the list
     * and "false" when list is null or empty.
     */
    @IsTest
    static void testIsNotEmpty() {
        System.assertEquals(false, Collection.of(null).isNotEmpty());
        System.assertEquals(false, Collection.of(new List<String>()).isNotEmpty());
    }


    /**
     *@description
     * Collections.isEmpty() returns "true" when list is empty or when it's null.
     */
    @IsTest
    static void testIsEmpty() {
        System.assertEquals(true, Collection.of(null).isEmpty());
        System.assertEquals(true, Collection.of(new List<String>()).isEmpty());
    }


    /**
     *@description
     * size() should return the actual size of the collection and 0 if collection is null.
     */
    @IsTest
    static void testSize() {
        System.assertEquals(0, Collection.of(null).size());
        System.assertEquals(0, Collection.of(new List<String>()).size());
        System.assertEquals(opportunities.size(), Collection.of(opportunities).size());
    }


    @IsTest
    static void testGetters() {
        System.assertEquals(opportunities, Collection.of(opportunities).getList());
        System.assertEquals(opportunities.get(0), Collection.of(opportunities).get(0));
        System.assertEquals(opportunities.get(0), Collection.of(opportunities).getFirst());
        System.assertEquals(opportunities.get(opportunities.size() - 1), Collection.of(opportunities).getLast());
        System.assertEquals(null, Collection.of(null).getFirst());
        System.assertEquals(null, Collection.of(null).getLast());
        System.assertEquals(null, Collection.of(null).getRandom());
        System.assertEquals(null, Collection.of(new List<Opportunity>()).getFirst());
        System.assertEquals(null, Collection.of(new List<Opportunity>()).getLast());
        System.assertEquals(0, Collection.of(opportunities).clear().size());
    }

    @IsTest
    static void testSliceRange() {
        List<Integer> ints = new List<Integer>{0, 1, 2, 3, 4, 5, 6};
        List<Integer> slice = (List<Integer>) Collection.of(ints).slice(1, 3).getList();
        List<Integer> expected = new List<Integer>{1, 2, 3};

        System.assertEquals(expected, slice);
    }

    @IsTest
    static void testSliceIndexes() {
        List<Integer> ints = new List<Integer>{0, 1, 2, 3, 4, 5, 6};
        List<Integer> slice = (List<Integer>) Collection.of(ints).slice(new List<Integer>{0, 1, 3, 5}).getList();
        List<Integer> expected = new List<Integer>{0, 1, 3, 5};

        System.assertEquals(expected, slice);
    }

    @IsTest
    static void testAddRemove() {
        Collection.of(new List<Opportunity>())
            .addAll(opportunities)
            .add(newOpportunity(10, new Map<String, Object>()))
            .add(5, newOpportunity(10, new Map<String, Object>()))
            .remove(0)
            .removeLast();

        Collection.of(new List<Integer>{1, 2, 3})
            .addAll(new Set<Object>{4, 5, 6});
    }


    /**
     * Reduce to Set takes field value from SObjects and put's them in a Set.
     * Set has the same type as SObject field.
     */
    @IsTest
    static void testReduceFieldToSetByField() {
        Set<Id> expectedIds = new Set<Id>();
        Set<String> expectedStrings = new Set<String>();
        Set<Decimal> expectedDecimals = new Set<Decimal>();
        Set<Date> expectedDates = new Set<Date>();
        Set<Datetime> expectedDatetimes = new Set<Datetime>();
        Set<Boolean> expectedBooleans = new Set<Boolean>();

        for (Opportunity opp : opportunities) {
            expectedIds.add(opp.AccountId);
            expectedStrings.add(opp.Name);
            expectedDecimals.add(opp.Probability);
            expectedDates.add(opp.LastActivityDate);
            expectedDatetimes.add(opp.CreatedDate);
            expectedBooleans.add(opp.HasOpenActivity);
        }


        Test.startTest();
        Set<Id> actualIds = (Set<Id>) Collection.of(opportunities).collect(Opportunity.AccountId).getSet();
        Set<String> actualStrings = (Set<String>) Collection.of(opportunities).collect(Opportunity.Name).getSet();
        Set<Decimal> actualDecimals = (Set<Decimal>) Collection.of(opportunities).collect(Opportunity.Probability).getSet();
        Set<Date> actualDates = (Set<Date>) Collection.of(opportunities).collect(Opportunity.LastActivityDate).getSet();
        Set<Datetime> actualDatetimes = (Set<Datetime>) Collection.of(opportunities).collect(Opportunity.CreatedDate).getSet();
        Set<Boolean> actualBooleans = (Set<Boolean>) Collection.of(opportunities).collect(Opportunity.HasOpenActivity).getSet();
        Test.stopTest();


        System.assertEquals(expectedIds, actualIds);
        System.assertEquals(expectedStrings, actualStrings);
        System.assertEquals(expectedDecimals, actualDecimals);
        System.assertEquals(expectedDates, actualDates);
        System.assertEquals(expectedDatetimes, actualDatetimes);
        System.assertEquals(expectedBooleans, actualBooleans);
    }


    @IsTest
    static void testReduceFieldToSetByMapper() {
        Set<Integer> expected = new Set<Integer>();
        for (Opportunity opportunity : opportunities) {
            expected.add(opportunity.CreatedDate.day());
        }

        Set<Integer> actual = (Set<Integer>) Collection.of(opportunities).collect(new MapperByCreatedDay()).getSet();
        System.assertEquals(expected, actual);
    }

    /**
     * Reduce to Map takes field value from SObjects maps record by the value.
     * Map key has the same type as SObject field.
     */
    @IsTest
    static void testReduceToMapByField() {
        Map<Id, Opportunity> expectedIds = new Map<Id, Opportunity>();
        Map<String, Opportunity> expectedStrings = new Map<String, Opportunity>();
        Map<Integer, Opportunity> expectedIntegers = new Map<Integer, Opportunity>();
        Map<Decimal, Opportunity> expectedDecimals = new Map<Decimal, Opportunity>();
        Map<Date, Opportunity> expectedDates = new Map<Date, Opportunity>();
        Map<Datetime, Opportunity> expectedDatetimes = new Map<Datetime, Opportunity>();
        Map<Boolean, Opportunity> expectedBooleans = new Map<Boolean, Opportunity>();

        for (Opportunity opp : opportunities) {
            expectedIds.put(opp.AccountId, opp);
            expectedStrings.put(opp.Name, opp);
            expectedIntegers.put(opp.CreatedDate.day(), opp);
            expectedDecimals.put(opp.Probability, opp);
            expectedDates.put(opp.LastActivityDate, opp);
            expectedDatetimes.put(opp.CreatedDate, opp);
            expectedBooleans.put(opp.HasOpenActivity, opp);
        }


        Test.startTest();
        Map<Id, Opportunity> actualIds = (Map<Id, Opportunity>) Collection.of(opportunities).mapBy(Opportunity.AccountId);
        Map<String, Opportunity> actualStrings = (Map<String, Opportunity>) Collection.of(opportunities).mapBy(Opportunity.Name);
        Map<Integer, Opportunity> actualIntegers = (Map<Integer, Opportunity>) Collection.of(opportunities).mapBy(new MapperByCreatedDay());
        Map<Decimal, Opportunity> actualDecimals = (Map<Decimal, Opportunity>) Collection.of(opportunities).mapBy(Opportunity.Probability);
        Map<Date, Opportunity> actualDates = (Map<Date, Opportunity>) Collection.of(opportunities).mapBy(Opportunity.LastActivityDate);
        Map<Datetime, Opportunity> actualDatetimes = (Map<Datetime, Opportunity>) Collection.of(opportunities).mapBy(Opportunity.CreatedDate);
        Map<Boolean, Opportunity> actualBooleans = (Map<Boolean, Opportunity>) Collection.of(opportunities).mapBy(Opportunity.HasOpenActivity);
        Test.stopTest();


        System.assertEquals(expectedIds, actualIds);
        System.assertEquals(expectedStrings, actualStrings);
        System.assertEquals(expectedIntegers, actualIntegers);
        System.assertEquals(expectedDecimals, actualDecimals);
        System.assertEquals(expectedDates, actualDates);
        System.assertEquals(expectedDatetimes, actualDatetimes);
        System.assertEquals(expectedBooleans, actualBooleans);
    }


    @IsTest
    static void testReduceToMapByKeyMapper() {
        Map<Time, Opportunity> expected = new Map<Time, Opportunity>();
        for (Opportunity opp : opportunities) {
            expected.put(opp.CreatedDate.time(), opp);
        }

        Test.startTest();
        Map<Time, Opportunity> actual = (Map<Time, Opportunity>) Collection.of(opportunities).mapBy(new MapByOpportunityCreateTime());
        Test.stopTest();

        System.assertEquals(expected, actual);
    }

    /**
     * Example Mapper implementation which maps item by created date's time
     */
    private class MapByOpportunityCreateTime implements Collection.Mapper {
        public Object value(Object item) {
            return ((Opportunity) item).CreatedDate.time();
        }

        public Type valueType() {
            return Time.class;
        }
    }


    @IsTest
    static void testReduceToMapByKeyAndValueMapper() {
        Map<Id, OpportunityWrapper> expected = new Map<Id, OpportunityWrapper>();
        for (Opportunity opp : opportunities) {
            expected.put(opp.Id, new OpportunityWrapper(opp));
        }

        Test.startTest();
        Map<Id, OpportunityWrapper> actual = (Map<Id, OpportunityWrapper>) Collection.of(opportunities).mapBy(
            new CollectionImpl.FieldMapper(Opportunity.Id),
            new OpportunityWrapperMapper()
        );
        Test.stopTest();

        System.assertEquals(JSON.serialize(expected), JSON.serialize(actual));
    }

    public class OpportunityWrapperMapper implements Collection.Mapper {

        public Object value(Object item) {
            Opportunity opp = (Opportunity) item;
            return new OpportunityWrapper(opp);
        }

        public Type valueType() {
            return OpportunityWrapper.class;
        }
    }

    public class OpportunityWrapper {
        public Opportunity opportunity;

        public OpportunityWrapper(Opportunity opportunity) {
            this.opportunity = opportunity;
        }
    }


    @IsTest
    static void testMapFieldByField() {
        Map<Id, Id> expected = new Map<Id, Id>();
        for (Opportunity opp : opportunities) {
            expected.put(opp.AccountId, opp.OwnerId);
        }

        Map<Id, Id> actual = (Map<Id, Id>) Collection.of(opportunities).mapBy(
            Opportunity.AccountId, Opportunity.OwnerId
        );

        System.assertEquals(
            JSON.serialize(expected),
            JSON.serialize(actual)
        );
    }

    @IsTest
    static void testGroupFieldByField() {
        Map<Id, List<Id>> expected = new Map<Id, List<Id>>();
        for (Opportunity opp : opportunities) {
            if (!expected.containsKey(opp.AccountId)) {
                expected.put(opp.AccountId, new List<Id>());
            }

            expected.get(opp.AccountId).add(opp.OwnerId);
        }

        Map<Id, List<Id>> actual = (Map<Id, List<Id>>) Collection.of(opportunities).groupBy(Opportunity.AccountId, Opportunity.OwnerId);

        System.assertEquals(expected, actual);
    }


    @IsTest
    static void testMapByFieldPair() {
        Map<String, Opportunity> expected = new Map<String, Opportunity>();
        for (Opportunity opp : opportunities) {
            expected.put('' + opp.AccountId + opp.OwnerId, opp);
        }

        Map<String, Opportunity> actual = (Map<String, Opportunity>) Collection.of(opportunities).mapByConcatenation(Opportunity.AccountId, Opportunity.OwnerId);

        System.assertEquals(expected, actual);
    }

    @IsTest
    static void testGroupByFieldPair() {
        Map<String, Opportunity[]> expected = new Map<String, Opportunity[]>();
        for (Opportunity opp : opportunities) {
            String key = '' + opp.AccountId + opp.OwnerId;

            if (expected.containsKey(key)) {
                expected.get(key).add(opp);
            } else {
                expected.put(key, new List<Opportunity>{opp});
            }
        }

        Map<String, Opportunity[]> actual = (Map<String, Opportunity[]>) Collection.of(opportunities).groupByConcatenation(Opportunity.AccountId, Opportunity.OwnerId);

        System.assertEquals(expected, actual);
    }

    @IsTest
    static void testReduceEmptyListToMapShouldReturnEmptyMap() {
        Map<String, Opportunity> expected = new Map<String, Opportunity>();
        Map<String, Opportunity> actual = (Map<String, Opportunity>) Collection.of(new List<Opportunity>()).mapBy(Opportunity.Name);
        System.assertEquals(expected, actual);
    }


    /**
     * Reduce to Group should create Map of (Key, List<Value>) where all values in a list had the same key.
     */
    @IsTest
    static void testGroupByField() {
        Map<Id, List<Opportunity>> expectedGroupById = new Map<Id, List<Opportunity>>();
        Map<String, List<Opportunity>> expectedGroupByString = new Map<String, List<Opportunity>>();
        Map<Integer, List<Opportunity>> expectedGroupByInteger = new Map<Integer, List<Opportunity>>();
        Map<Decimal, List<Opportunity>> expectedGroupByDecimal = new Map<Decimal, List<Opportunity>>();
        Map<Date, List<Opportunity>> expectedGroupByDate = new Map<Date, List<Opportunity>>();
        Map<Datetime, List<Opportunity>> expectedGroupByDatetime = new Map<Datetime, List<Opportunity>>();
        Map<Boolean, List<Opportunity>> expectedGroupByBoolean = new Map<Boolean, List<Opportunity>>();

        for (Opportunity opportunity : opportunities) {
            expectedGroupById.put(opportunity.AccountId, addToGroup(expectedGroupById.get(opportunity.AccountId), opportunity));
            expectedGroupByString.put(opportunity.NextStep, addToGroup(expectedGroupByString.get(opportunity.NextStep), opportunity));
            expectedGroupByInteger.put(opportunity.CreatedDate.day(), addToGroup(expectedGroupByInteger.get(opportunity.CreatedDate.day()), opportunity));
            expectedGroupByDecimal.put(opportunity.Probability, addToGroup(expectedGroupByDecimal.get(opportunity.Probability), opportunity));
            expectedGroupByDate.put(opportunity.LastActivityDate, addToGroup(expectedGroupByDate.get(opportunity.LastActivityDate), opportunity));
            expectedGroupByDatetime.put(opportunity.CreatedDate, addToGroup(expectedGroupByDatetime.get(opportunity.CreatedDate), opportunity));
            expectedGroupByBoolean.put(opportunity.HasOpenActivity, addToGroup(expectedGroupByBoolean.get(opportunity.HasOpenActivity), opportunity));
        }
        Collection opportunityCollection = Collection.of(opportunities);


        Test.startTest();
        Map<Id, List<Opportunity>> actualGroupById = (Map<Id, List<Opportunity>>) opportunityCollection.groupBy(Opportunity.AccountId);
        Map<String, List<Opportunity>> actualGroupByString = (Map<String, List<Opportunity>>) opportunityCollection.groupBy(Opportunity.NextStep);
        Map<Integer, List<Opportunity>> actualGroupByInteger = (Map<Integer, List<Opportunity>>) opportunityCollection.groupBy(new MapperByCreatedDay());
        Map<Decimal, List<Opportunity>> actualGroupByDecimal = (Map<Decimal, List<Opportunity>>) opportunityCollection.groupBy(Opportunity.Probability);
        Map<Date, List<Opportunity>> actualGroupByDate = (Map<Date, List<Opportunity>>) opportunityCollection.groupBy(Opportunity.LastActivityDate);
        Map<Datetime, List<Opportunity>> actualGroupByDatetime = (Map<Datetime, List<Opportunity>>) opportunityCollection.groupBy(Opportunity.CreatedDate);
        Map<Boolean, List<Opportunity>> actualGroupByBoolean = (Map<Boolean, List<Opportunity>>) opportunityCollection.groupBy(Opportunity.HasOpenActivity);
        Test.stopTest();


        System.assertEquals(expectedGroupById, actualGroupById);
        System.assertEquals(expectedGroupByString, actualGroupByString);
        System.assertEquals(expectedGroupByInteger, actualGroupByInteger);
        System.assertEquals(expectedGroupByDecimal, actualGroupByDecimal);
        System.assertEquals(expectedGroupByDate, actualGroupByDate);
        System.assertEquals(expectedGroupByDatetime, actualGroupByDatetime);
        System.assertEquals(expectedGroupByBoolean, actualGroupByBoolean);
    }

    private static List<Opportunity> addToGroup(List<Opportunity> opps, Opportunity opportunity) {
        List<Opportunity> grouppedOpps = opps == null ? new List<Opportunity>() : opps;
        grouppedOpps.add(opportunity);

        return grouppedOpps;
    }


    @IsTest
    static void testGroupByFieldByKeyMapper() {
        Map<Integer, List<Opportunity>> expected = new Map<Integer, List<Opportunity>>();
        for (Opportunity opportunity : opportunities) {
            Integer day = opportunity.CreatedDate.day();

            if (expected.containsKey(day)) {
                expected.get(day).add(opportunity);
            } else {
                expected.put(day, new List<Opportunity>{opportunity});
            }
        }


        Map<Integer, List<Opportunity>> actual = (Map<Integer, List<Opportunity>>) Collection.of(opportunities).groupBy(new MapperByCreatedDay());


        System.assertEquals(expected, actual);
    }

    private class MapperByCreatedDay implements Collection.Mapper {
        public Object value(Object item) { return ((Opportunity) item).CreatedDate.day(); }
        public Type valueType() { return Integer.class; }
    }


    @IsTest
    static void testReduceEmptyListToGroupShouldReturnEmptyMap() {
        Map<String, List<Opportunity>> expected = new Map<String, List<Opportunity>>();
        Map<String, List<Opportunity>> actual = (Map<String, List<Opportunity>>) Collection.of(new List<Opportunity>()).groupBy(Opportunity.Name);
        System.assertEquals(expected, actual);
    }


    @IsTest
    static void testFilterByField() {
        List<Opportunity> expected = new List<Opportunity>();

        for (Opportunity opp : opportunities) {
            Boolean accept = (
                opp.NextStep.contains('Analysis')
                && opp.HasOpenActivity == true
                && opp.LastActivityDate <= Date.today()
                && opp.LastActivityDate > Date.today().addDays(-2)
            ) || opp.NextStep != 'Analysis';

            if (accept) {
                expected.add(opp);
            }
        }


        CollectionConditions c = new CollectionConditions();
        Test.startTest();
        List<Opportunity> actual = (List<Opportunity>) Collection.of(opportunities)
            .filter(
                c.ORs(
                    c.ANDs(
                        c.field(Opportunity.NextStep).contains('Analysis'),
                        c.field(Opportunity.HasOpenActivity).equals(true),
                        c.field(Opportunity.LastActivityDate).lessEqualsThan(Date.today()),
                        c.field(Opportunity.LastActivityDate).greaterThan(Date.today().addDays(-2))
                    ),
                    c.field(Opportunity.NextStep).notEquals('Analysis')
                )
            )
            .getList();

        Test.stopTest();


        System.assertEquals(expected, actual);
    }

    @IsTest
    static void testFilterByField2() {
        List<String> wantedSteps = new List<String>{'Analysis', 'Deal'};
        List<String> unwantedSteps = new List<String>{'Support'};

        List<Opportunity> expected = new List<Opportunity>();
        for (Opportunity opp : opportunities) {
            Boolean accept =
                opp.Name != null
                && wantedSteps.indexOf(opp.NextStep) > -1
                && unwantedSteps.indexOf(opp.NextStep) == -1
                && opp.LastActivityDate < Date.today();

            if (accept) {
                expected.add(opp);
            }
        }

        CollectionConditions c = new CollectionConditions();

        Test.startTest();
        List<Opportunity> actual = (List<Opportunity>) Collection.of(opportunities)
            .filter(
                c.ANDs(
                    c.field(Opportunity.Name).notEquals(null),
                    c.field(Opportunity.NextStep).isIn(wantedSteps),
                    c.field(Opportunity.NextStep).isNotIn(unwantedSteps),
                    c.field(Opportunity.LastActivityDate).lessThan(Date.today())
                )
            )
            .getList();

        Test.stopTest();


        System.assertEquals(expected, actual);
    }

    /**
     * @description
     * Collections.filterByFieldValues filters input records and return only those which field is one of specified values.
     */
    @IsTest
    static void tesFilterByFieldValues() {
        Set<Object> acceptedStages = new Set<Object>{
            'Analysis', 'Deal'
        };
        List<Opportunity> expectedAcceptedOpps = new List<Opportunity>();
        List<Opportunity> expectedRejectedOpps = new List<Opportunity>();

        for (Opportunity opportunity : opportunities) {
            if (acceptedStages.contains(opportunity.StageName)) {
                expectedAcceptedOpps.add(opportunity);
            } else {
                expectedRejectedOpps.add(opportunity);
            }
        }

        List<Opportunity> actualAcceptedOpps = (List<Opportunity>) Collection.of(opportunities).filter(Opportunity.StageName).isIn(acceptedStages).getList();
        List<Opportunity> actualRejectedOpps = (List<Opportunity>) Collection.of(opportunities).filter(Opportunity.StageName).isNotIn(acceptedStages).getList();

        System.assertEquals(expectedAcceptedOpps, actualAcceptedOpps);
        System.assertEquals(expectedRejectedOpps, actualRejectedOpps);
    }


    /**
     *@description
     * CollectionsFilter.RelatedTo returns records related to given parents.
     */
    @IsTest
    static void testFilterByRelatedTo() {
        Map<Id, Account> accounts = new Map<Id, Account>(new List<Account>{
            new Account(Id = '001000000000000'),
            new Account(Id = '001000000000001')
        });

        Set<Id> expected = new Set<Id>();
        for (Opportunity opportunity : opportunities) {
            if (accounts.keySet().contains(opportunity.AccountId)) {
                expected.add(opportunity.Id);
            }
        }


        Test.startTest();
        Set<Id> actual = (Set<Id>) Collection.of(opportunities)
            .filter(Opportunity.AccountId).isIn(accounts.values())
            .collect(Opportunity.Id)
            .getSet();
        Test.stopTest();


        System.assertEquals(expected, actual);
    }


    /**
     *@description
     * Returns Opportunities that have the same field values as prototype
     */
    @IsTest
    static void testFilterByPrototype() {
        Opportunity prototype = new Opportunity(
            AccountId = '001000000000000'
        );

        List<Opportunity> expected = new List<Opportunity>();
        for (Opportunity opportunity : opportunities) {
            if (opportunity.AccountId == prototype.AccountId) {
                expected.add(opportunity);
            }
        }


        List<Opportunity> actual = (List<Opportunity>) Collection.of(opportunities)
            .filterAlike(prototype).getList();
        System.assertEquals(expected, actual);
    }


    /**
    * Reduce tests
    * */
    @IsTest
    static void testGetList() {
        List<String> strings = Collection.of(opportunities).collect(Opportunity.Name).getListString();
        List<Id> ids = Collection.of(opportunities).collect(Opportunity.Id).getListId();

        Assert.isFalse(strings.isEmpty());
        Assert.isFalse(ids.isEmpty());
    }

    @IsTest
    static void testReduceToListOfSObjectField() {
        List<Id> expected = new List<Id>();
        for (Opportunity opportunity : opportunities) {
            expected.add(opportunity.AccountId);
        }

        List<Id> actual = (List<Id>) Collection.of(opportunities).collect(Opportunity.AccountId).getListId();
        System.assertEquals(expected, actual);
    }

    @IsTest
    static void testGetSet() {
        Set<String> strings = Collection.of(opportunities).collect(Opportunity.Name).getSetString();
        Set<Id> ids = Collection.of(opportunities).collect(Opportunity.Id).getSetId();

        Assert.isFalse(strings.isEmpty());
        Assert.isFalse(ids.isEmpty());
    }

    @IsTest
    static void testGetIntegerCollections() {
        List<Account> accounts = new List<Account>{
            new Account(NumberOfEmployees = 10),
            new Account(NumberOfEmployees = 20),
            new Account(NumberOfEmployees = 30)
        };

        Assert.areEqual(
            new Set<Integer>{10, 20, 30},
            Collection.of(accounts)
                .collect(Account.NumberOfEmployees)
                .getSetInteger()
        );

        Assert.areEqual(
            new List<Integer>{10, 20, 30},
            Collection.of(accounts)
                .collect(Account.NumberOfEmployees)
                .getListInteger()
        );
    }

    @IsTest
    static void testReduceToSetOfSObjectField() {
        Set<Id> expected = new Set<Id>();
        for (Opportunity opportunity : opportunities) {
            expected.add(opportunity.AccountId);
        }

        Set<Id> actual = (Set<Id>) Collection.of(opportunities).collect(Opportunity.AccountId).getSet();
        System.assertEquals(expected, actual);
    }


    /**
     *@description
     * List of Opportunities is reduced to total of Amounts
     */
    @IsTest
    static void testReduceToSum() {
        Decimal expected = 0;
        opportunities[0].Amount = null;
        for (Opportunity opportunity : opportunities) {
            expected += opportunity.Amount != null ? opportunity.Amount : 0;
        }

        Decimal actual = Collection.of(opportunities).collect(Opportunity.Amount).getSum();
        System.assertEquals(expected, actual);

        Assert.areEqual(15, Collection.of(new List<Integer>{1, 2, 3, 4, 5}).getSum());
    }

    /**
     *@description
     * List of Opportunities is reduced to max Amount
     */
    @IsTest
    static void testReduceToMax() {
        Decimal max = -9999;
        opportunities[0].Amount = null;
        for (Opportunity opportunity : opportunities) {
            if (opportunity.Amount != null) {
                max = Math.max(max, opportunity.Amount);
            }
        }

        Decimal actual = Collection.of(opportunities).collect(Opportunity.Amount).getMax();

        System.assertEquals(max, actual);
        System.assertNotEquals(null, actual);
        Assert.areEqual(5, Collection.of(new List<Integer>{1, 2, 3, 4, 5}).getMax());
    }

    /**
     *@description
     * List of Opportunities is reduced to min Amount
     */
    @IsTest
    static void testReduceToMin() {
        Decimal min = 9999;
        opportunities[0].Amount = null;
        for (Opportunity opportunity : opportunities) {
            if (opportunity.Amount != null) {
                min = Math.min(min, opportunity.Amount);
            }
        }

        Decimal actual = Collection.of(opportunities).collect(Opportunity.Amount).getMin();

        System.assertEquals(min, actual);
        System.assertNotEquals(null, actual);
        Assert.areEqual(1, Collection.of(new List<Integer>{1, 2, 3, 4, 5}).getMin());
    }

    @IsTest
    static void testReduceToAverage() {
        Assert.areEqual(3, Collection.of(new List<Integer>{1, 2, 3, 4, 5}).getAverage());
    }

    /**
     * @description
     * orderBy takes list of objects and comparator implementation.
     * Sorted list is returned as result.
     */
    @IsTest
    static void testSortByComparator() {
        List<Opportunity> expected = new List<Opportunity>();
        for (Integer i = opportunities.size() - 1; i >= 0; --i) {
            expected.add(opportunities[i]);
        }

        List<Opportunity> actual = (List<Opportunity>) Collection.of(opportunities)
            .orderBy((System.Comparator<Object>) new ReverseProbabilityComparator())
            .getList();

        System.assertEquals(actual, expected);
    }

    private class ReverseProbabilityComparator implements System.Comparator<Opportunity> {
        public Integer compare(Opportunity thisOpp, Opportunity otherOpp) {
            if (thisOpp.Probability < otherOpp.Probability) {
                return 1;

            } else if (thisOpp.Probability > otherOpp.Probability) {
                return -1;

            } else {
                return 0;
            }
        }
    }


    @IsTest
    static void testOrderByField() {
        Opportunity previous;

        List<Opportunity> sortedOpportunities = (List<Opportunity>) Collection.of(opportunities).orderAsc(Opportunity.CreatedDate).getList();
        for (Opportunity opportunity : sortedOpportunities) {
            if (previous != null) {
                System.assert(opportunity.CreatedDate >= previous.CreatedDate);
            }
            previous = opportunity;
        }
        previous = null;


        sortedOpportunities = (List<Opportunity>) Collection.of(opportunities).orderDesc(Opportunity.Name).getList();
        for (Opportunity opportunity : sortedOpportunities) {
            if (previous != null) {
                System.assertEquals(-1, opportunity.Name.compareTo(previous.Name));
            }
            previous = opportunity;
        }
        previous = null;


        sortedOpportunities = (List<Opportunity>) Collection.of(opportunities)
            .orderAsc(Opportunity.Probability)
            .getList();
        for (Opportunity opportunity : sortedOpportunities) {
            if (previous != null) {
                System.assert(opportunity.Probability >= previous.Probability);
            }
            previous = opportunity;
        }
        previous = null;
    }


    /**
     *@description
     * find() returns first item accepted by ByFieldValue filter.
     */
    @IsTest
    static void testFindReturnsFirstSObjectOfGivenFieldValue() {
        Opportunity expected = opportunities[1];
        Opportunity actual = (Opportunity) Collection.of(opportunities).filter(Opportunity.Probability).equals(0.1).getFirst();
        System.assertEquals(expected, actual);
    }

    /**
     *@description
     * find() returns null if there's no item accepted by filter.
     */
    @IsTest
    static void testFindReturnsNullWhenThereAreNoItemsAcceptedByFilter() {
        Opportunity actual = (Opportunity) Collection.of(opportunities).filter(Opportunity.Probability).equals(1.5).getFirst();

        System.assertEquals(null, actual);
    }


    @IsTest
    static void testSetField() {
        Collection.of(opportunities)
            .setField(Opportunity.Name, 'Test');

        // Verify that the 'StageName' field has been set correctly for each opportunity
        for (Opportunity opp : opportunities) {
            Assert.areEqual('Test', opp.Name, 'StageName should be set to Prospecting');
        }
    }


    @IsTest
    static void testFindByFilter() {
        Opportunity expected = opportunities[5];
        Opportunity actual = (Opportunity) Collection.of(opportunities).filter(new OpportunityNameContainsFilter('5')).getFirst();

        System.assertEquals(expected, actual);
    }

    private class OpportunityNameContainsFilter implements Condition {
        private String expr;

        public OpportunityNameContainsFilter(String expr) {
            this.expr = expr;
        }

        public Boolean isTrue(Object item) {
            return ((Opportunity) item).Name.contains(expr);
        }
    }
}