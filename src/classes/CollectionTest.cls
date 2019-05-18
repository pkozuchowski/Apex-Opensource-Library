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
                'FiscalQuarter' => Math.mod(i, 4),
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
        System.assertEquals(opportunities, Collection.of(opportunities).get());
        System.assertEquals(opportunities.get(0), Collection.of(opportunities).get(0));
        System.assertEquals(opportunities.get(0), Collection.of(opportunities).getFirst());
        System.assertEquals(opportunities.get(opportunities.size() - 1), Collection.of(opportunities).getLast());
        System.assertEquals(null, Collection.of(null).getFirst());
        System.assertEquals(null, Collection.of(null).getLast());
        System.assertEquals(null, Collection.of(new List<Opportunity>()).getFirst());
        System.assertEquals(null, Collection.of(new List<Opportunity>()).getLast());
    }


    @IsTest
    static void testReduceFieldToSetByField() {
        Set<Id> expectedIds = new Set<Id>();
        Set<String> expectedStrings = new Set<String>();
        Set<Integer> expectedIntegers = new Set<Integer>();
        Set<Decimal> expectedDecimals = new Set<Decimal>();
        Set<Date> expectedDates = new Set<Date>();
        Set<Datetime> expectedDatetimes = new Set<Datetime>();
        Set<Boolean> expectedBooleans = new Set<Boolean>();

        for (Opportunity opp : opportunities) {
            expectedIds.add(opp.AccountId);
            expectedStrings.add(opp.Name);
            expectedIntegers.add(opp.FiscalQuarter);
            expectedDecimals.add(opp.Probability);
            expectedDates.add(opp.LastActivityDate);
            expectedDatetimes.add(opp.CreatedDate);
            expectedBooleans.add(opp.HasOpenActivity);
        }


        Test.startTest();
        Set<Id> actualIds = (Set<Id>) Collection.of(opportunities).reduce().toSet(Opportunity.AccountId);
        Set<String> actualStrings = (Set<String>) Collection.of(opportunities).reduce().toSet(Opportunity.Name);
        Set<Integer> actualIntegers = (Set<Integer>) Collection.of(opportunities).reduce().toSet(Opportunity.FiscalQuarter);
        Set<Decimal> actualDecimals = (Set<Decimal>) Collection.of(opportunities).reduce().toSet(Opportunity.Probability);
        Set<Date> actualDates = (Set<Date>) Collection.of(opportunities).reduce().toSet(Opportunity.LastActivityDate);
        Set<Datetime> actualDatetimes = (Set<Datetime>) Collection.of(opportunities).reduce().toSet(Opportunity.CreatedDate);
        Set<Boolean> actualBooleans = (Set<Boolean>) Collection.of(opportunities).reduce().toSet(Opportunity.HasOpenActivity);
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
    static void testReduceFieldToSetByMapper() {
        Set<Integer> expected = new Set<Integer>{
                0, 1
        };

        Set<Integer> actual = (Set<Integer>) Collection.of(opportunities).reduce().toSet(new OpportunitiesByYearsHalfMapper());
        System.assertEquals(expected, actual);
    }


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
            expectedIntegers.put(opp.FiscalQuarter, opp);
            expectedDecimals.put(opp.Probability, opp);
            expectedDates.put(opp.LastActivityDate, opp);
            expectedDatetimes.put(opp.CreatedDate, opp);
            expectedBooleans.put(opp.HasOpenActivity, opp);
        }


        Test.startTest();
        Map<Id, Opportunity> actualIds = (Map<Id, Opportunity>) Collection.of(opportunities).reduce().toMap(Opportunity.AccountId);
        Map<String, Opportunity> actualStrings = (Map<String, Opportunity>) Collection.of(opportunities).reduce().toMap(Opportunity.Name);
        Map<Integer, Opportunity> actualIntegers = (Map<Integer, Opportunity>) Collection.of(opportunities).reduce().toMap(Opportunity.FiscalQuarter);
        Map<Decimal, Opportunity> actualDecimals = (Map<Decimal, Opportunity>) Collection.of(opportunities).reduce().toMap(Opportunity.Probability);
        Map<Date, Opportunity> actualDates = (Map<Date, Opportunity>) Collection.of(opportunities).reduce().toMap(Opportunity.LastActivityDate);
        Map<Datetime, Opportunity> actualDatetimes = (Map<Datetime, Opportunity>) Collection.of(opportunities).reduce().toMap(Opportunity.CreatedDate);
        Map<Boolean, Opportunity> actualBooleans = (Map<Boolean, Opportunity>) Collection.of(opportunities).reduce().toMap(Opportunity.HasOpenActivity);
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
        Map<Time, Opportunity> actual = (Map<Time, Opportunity>) Collection.of(opportunities).reduce().toMap(new MapByOpportunityCreateTime());
        Test.stopTest();

        System.assertEquals(expected, actual);
    }

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
        Map<String, Id> expected = new Map<String, Id>();
        for (Opportunity opp : opportunities) {
            expected.put('' + opp.AccountId + opp.FiscalQuarter, opp.Id);
        }

        Test.startTest();
        Map<String, Id> actual = (Map<String, Id>) Collection.of(opportunities).reduce().toMap(
                new MapperByAccountIdAndFiscalQuarter(),
                new Collection.MapByField(Opportunity.Id)
        );
        Test.stopTest();

        System.assertEquals(expected, actual);
    }
    private class MapperByAccountIdAndFiscalQuarter implements Collection.Mapper {
        public Object value(Object item) {
            Opportunity opp = (Opportunity) item;
            return '' + opp.AccountId + opp.FiscalQuarter;
        }

        public Type valueType() {
            return String.class;
        }
    }

    /**
     * CollectionMappers.ByFieldPair can map junction object by both parent Ids.
     */
    @IsTest
    static void testMapByFieldPair() {
        Map<String, Opportunity> expected = new Map<String, Opportunity>();
        for (Opportunity opp : opportunities) {
            expected.put('' + opp.AccountId + opp.OwnerId, opp);
        }

        Map<String, Opportunity> actual = (Map<String, Opportunity>) Collection.of(opportunities)
                .reduce()
                .toMap(new Collection.MapByFieldPair(Opportunity.AccountId, Opportunity.OwnerId));

        System.assertEquals(expected, actual);
    }

    @IsTest
    static void testReduceEmptyListToMapShouldReturnEmptyMap() {
        Map<String, Opportunity> expected = new Map<String, Opportunity>();
        Map<String, Opportunity> actual = (Map<String, Opportunity>) Collection.of(new List<Opportunity>()).reduce().toMap(Opportunity.Name);
        System.assertEquals(expected, actual);
    }


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
            expectedGroupByInteger.put(opportunity.FiscalQuarter, addToGroup(expectedGroupByInteger.get(opportunity.FiscalQuarter), opportunity));
            expectedGroupByDecimal.put(opportunity.Probability, addToGroup(expectedGroupByDecimal.get(opportunity.Probability), opportunity));
            expectedGroupByDate.put(opportunity.LastActivityDate, addToGroup(expectedGroupByDate.get(opportunity.LastActivityDate), opportunity));
            expectedGroupByDatetime.put(opportunity.CreatedDate, addToGroup(expectedGroupByDatetime.get(opportunity.CreatedDate), opportunity));
            expectedGroupByBoolean.put(opportunity.HasOpenActivity, addToGroup(expectedGroupByBoolean.get(opportunity.HasOpenActivity), opportunity));
        }
        Collection opportunityCollection = Collection.of(opportunities);


        Test.startTest();
        Map<Id, List<Opportunity>> actualGroupById = (Map<Id, List<Opportunity>>) opportunityCollection.reduce().toGroup(Opportunity.AccountId);
        Map<String, List<Opportunity>> actualGroupByString = (Map<String, List<Opportunity>>) opportunityCollection.reduce().toGroup(Opportunity.NextStep);
        Map<Integer, List<Opportunity>> actualGroupByInteger = (Map<Integer, List<Opportunity>>) opportunityCollection.reduce().toGroup(Opportunity.FiscalQuarter);
        Map<Decimal, List<Opportunity>> actualGroupByDecimal = (Map<Decimal, List<Opportunity>>) opportunityCollection.reduce().toGroup(Opportunity.Probability);
        Map<Date, List<Opportunity>> actualGroupByDate = (Map<Date, List<Opportunity>>) opportunityCollection.reduce().toGroup(Opportunity.LastActivityDate);
        Map<Datetime, List<Opportunity>> actualGroupByDatetime = (Map<Datetime, List<Opportunity>>) opportunityCollection.reduce().toGroup(Opportunity.CreatedDate);
        Map<Boolean, List<Opportunity>> actualGroupByBoolean = (Map<Boolean, List<Opportunity>>) opportunityCollection.reduce().toGroup(Opportunity.HasOpenActivity);
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
        Map<Integer, List<Opportunity>> expected = new Map<Integer, List<Opportunity>>{
                0 => new List<Opportunity>{
                        opportunities[0], opportunities[1], opportunities[4], opportunities[5], opportunities[8], opportunities[9]
                },
                1 => new List<Opportunity>{
                        opportunities[2], opportunities[3], opportunities[6], opportunities[7]
                }
        };
        Map<Integer, List<Opportunity>> actual = (Map<Integer, List<Opportunity>>) Collection.of(opportunities).reduce().toGroup(new OpportunitiesByYearsHalfMapper());


        System.assertEquals(expected, actual);
    }

    private class OpportunitiesByYearsHalfMapper implements Collection.Mapper {
        public Object value(Object item) {
            Integer quarter = ((Opportunity) item).FiscalQuarter;
            return quarter <= 1 ? 0 : 1;
        }
        public Type valueType() {
            return Integer.class;
        }
    }


    @IsTest
    static void testReduceEmptyListToGroupShouldReturnEmptyMap() {
        Map<String, List<Opportunity>> expected = new Map<String, List<Opportunity>>();
        Map<String, List<Opportunity>> actual = (Map<String, List<Opportunity>>) Collection.of(new List<Opportunity>()).reduce().toGroup(Opportunity.Name);
        System.assertEquals(expected, actual);
    }

//
//
//    /**
//     *@description
//     * Collections.filterByFieldValue filters input records and return only those which field is the same as specified value.
//     */
//    @IsTest
//    static void tesFiltertFilterByFieldValue() {
//        List<Opportunity> hasOpenActivity = new List<Opportunity>();
//        List<Opportunity> hasNotOpenActivity = new List<Opportunity>();
//        List<Opportunity> fiscalQuarterEquals0 = new List<Opportunity>();
//        List<Opportunity> fiscalQuarterNotEquals0 = new List<Opportunity>();
//        List<Opportunity> nextStepAnalysis = new List<Opportunity>();
//        List<Opportunity> nextStepNotAnalysis = new List<Opportunity>();
//
//        for (Opportunity opp : opportunities) {
//            if (opp.HasOpenActivity) {
//                hasOpenActivity.add(opp);
//            } else {
//                hasNotOpenActivity.add(opp);
//            }
//
//            if (opp.FiscalQuarter == 0) {
//                fiscalQuarterEquals0.add(opp);
//            } else {
//                fiscalQuarterNotEquals0.add(opp);
//            }
//
//            if (opp.NextStep == 'Analysis') {
//                nextStepAnalysis.add(opp);
//            } else {
//                nextStepNotAnalysis.add(opp);
//            }
//        }
//
//        System.assertEquals(hasOpenActivity, Collection.of(opportunities).filter(Opportunity.HasOpenActivity, '==', true).toList());
//        System.assertEquals(hasNotOpenActivity, Collection.of(opportunities).filter(Opportunity.HasOpenActivity, '!=', true).toList());
//
//        System.assertEquals(fiscalQuarterEquals0, Collection.of(opportunities).filter(new Collection.FilterByFieldValue(Opportunity.FiscalQuarter, '==', 0)).toList());
//        System.assertEquals(fiscalQuarterNotEquals0, Collection.of(opportunities).filter(new Collection.FilterByFieldValue(Opportunity.FiscalQuarter, '!=', 0)).toList());
//
//        System.assertEquals(nextStepAnalysis, Collection.of(opportunities).filter(Opportunity.NextStep, '==', 'Analysis').toList());
//        System.assertEquals(nextStepNotAnalysis, Collection.of(opportunities).filter(new Collection.FilterByFieldValue(Opportunity.NextStep, '!=', 'Analysis')).toList());
//    }
//
//
//    /**
//     * @description
//     * Collections.filterByFieldValues filters input records and return only those which field is one of specified values.
//     */
//    @IsTest
//    static void tesFiltertFilterByFieldValues() {
//        Set<Object> acceptedStages = new Set<Object>{
//                'Analysis', 'Deal'
//        };
//        List<Opportunity> expectedAcceptedOpps = new List<Opportunity>();
//        List<Opportunity> expectedRejectedOpps = new List<Opportunity>();
//
//        for (Opportunity opportunity : opportunities) {
//            if (acceptedStages.contains(opportunity.StageName)) {
//                expectedAcceptedOpps.add(opportunity);
//            } else {
//                expectedRejectedOpps.add(opportunity);
//            }
//        }
//
//        List<Opportunity> actualAcceptedOpps = (List<Opportunity>) Collection.of(opportunities)
//                .filter(new Collection.FilterByFieldValues(Opportunity.StageName, 'IN', acceptedStages))
//                .toList();
//        List<Opportunity> actualRejectedOpps = (List<Opportunity>) Collection.of(opportunities)
//                .filter(new Collection.FilterByFieldValues(Opportunity.StageName, 'NOT IN', acceptedStages))
//                .toList();
//
//        System.assertEquals(expectedAcceptedOpps, actualAcceptedOpps);
//        System.assertEquals(expectedRejectedOpps, actualRejectedOpps);
//    }
//
//
//    /**
//     * @description
//     * Collections.filter(UpdateFilter) takes list of Trigger.new records, trigger oldmap and UpdateFilter implementation
//     * and return only these records that are accepted by Filter
//     */
//    @IsTest
//    static void testFilterByUpdateFilter() {
//        List<Opportunity> opportunities = opportunities;
//        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>(opportunities.deepClone(true));
//
//        oldMap.get(opportunities[0].Id).Name += '_CHANGED';
//        oldMap.get(opportunities[1].Id).Name += '_CHANGED';
//        oldMap.get(opportunities[2].Id).Name += '_CHANGED';
//
//        List<Opportunity> expected = new List<Opportunity>{
//                opportunities[0],
//                opportunities[1],
//                opportunities[2]
//        };
//
//        List<Opportunity> actual = (List<Opportunity>) Collection.of(opportunities).filter(oldMap, new OpportunityChangedNameFilter()).toList();
//        System.assertEquals(expected, actual);
//    }
//
//    @IsTest
//    static void testFilterByUpdateFilterInstance() {
//        List<Opportunity> opportunities = opportunities;
//        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>(opportunities.deepClone(true));
//
//        oldMap.get(opportunities[0].Id).Name += '_CHANGED';
//        oldMap.get(opportunities[1].Id).Name += '_CHANGED';
//        oldMap.get(opportunities[2].Id).Name += '_CHANGED';
//
//        List<Opportunity> expected = new List<Opportunity>{
//                opportunities[0],
//                opportunities[1],
//                opportunities[2]
//        };
//
//        List<Opportunity> actual = (List<Opportunity>) Collection.of(opportunities)
//                .filter(oldMap, new OpportunityChangedNameFilter())
//                .toList();
//        System.assertEquals(expected, actual);
//    }
//
//    private class OpportunityChangedNameFilter implements Collection.UpdateFilter {
//        public Boolean accepts(Object record, Object oldRecord) {
//            return ((Opportunity) record).Name != ((Opportunity) oldRecord).Name;
//        }
//    }
//
//    /**
//     *@description
//     *
//     */
//    @IsTest
//    static void testFilterFieldChanged() {
//        List<Opportunity> opps = opportunities;
//        List<Opportunity> oldOpps = opps.deepClone(true);
//        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>(oldOpps);
//
//        opps[0].Name = opps[1].Name = 'Henry';
//        opps[2].Name = opps[3].Name = 'John';
//
//        oldOpps[0].Name = 'Hen';
//        oldOpps[1].Name = oldOpps[2].Name = 'Ken';
//
//
//        System.assertEquals(new List<Opportunity>{
//                opps[0], opps[1], opps[2], opps[3]
//        },
//                Collection.of(opps).
//                        filter(oldMap, new Collection.FilterByFieldChanged(Opportunity.Name))
//                        .toList()
//        );
//
//        System.assertEquals(new List<Opportunity>{
//                opps[2], opps[3]
//        },
//                Collection.of(opps).
//                        filter(oldMap, new Collection.FilterByFieldChanged(Opportunity.Name, Collection.ANY_VALUE, 'John'))
//                        .toList()
//        );
//
//        System.assertEquals(new List<Opportunity>{
//                opps[1], opps[2]
//        }, Collection.of(opps).
//                filter(oldMap, new Collection.FilterByFieldChanged(Opportunity.Name, 'Ken', Collection.ANY_VALUE))
//                .toList()
//        );
//
//        System.assertEquals(new List<Opportunity>{
//                opps[0]
//        }, Collection.of(opps).
//                filter(oldMap, new Collection.FilterByFieldChanged(Opportunity.Name, 'Hen', 'Henry'))
//                .toList()
//        );
//    }
//
//
//    /**
//     *@description
//     * CollectionsFilter.RelatedTo returns records related to given parents.
//     */
//    @IsTest
//    static void testFilterByRelatedTo() {
//        List<Account> accounts = new List<Account>{
//                new Account(Id = '001000000000000'),
//                new Account(Id = '001000000000001')
//        };
//
//        Set<Id> expected = new Map<Id, Opportunity>(new List<Opportunity>{
//                opportunities[0], opportunities[3], opportunities[6], opportunities[9],
//                opportunities[1], opportunities[4], opportunities[7]
//        }).keySet();
//
//        Set<Id> actual = (Set<Id>)
//                Collection.of(opportunities)
//                        .filter(new Collection.FilterRelatedTo(accounts, Opportunity.AccountId))
//                        .getUniqueValues(Opportunity.Id);
//
//        System.assertEquals(expected, actual);
//    }
//
//
//    /**
//     *@description
//     * Returns Opportunities that have the same field values as prototype
//     */
//    @IsTest
//    static void testFilterByPrototype() {
//        Opportunity prototype = new Opportunity(
//                AccountId = '001000000000000'
//        );
//
//        List<Opportunity> expected = new List<Opportunity>();
//        for (Opportunity opportunity : opportunities) {
//            if (opportunity.AccountId == prototype.AccountId) {
//                expected.add(opportunity);
//            }
//        }
//
//
//        List<Opportunity> actual = (List<Opportunity>) Collection.of(opportunities).filter(prototype).toList();
//        System.assertEquals(expected, actual);
//    }
//
//
//    /**
//     *@description
//     * Collections.reduce() reduces collection to one object or other collection using Reducer implementation.
//     */
//    @IsTest
//    static void testReduceToIds() {
////        Set<Id> expected = new Set<Id>();
////        for (Opportunity opportunity : opportunities) {
////            expected.add(opportunity.Id);
////            expected.add(opportunity.AccountId);
////        }
////        Set<Id> actual = Collection.of(opportunities)
////                .reduce(new List<SObjectField>{
////                        Opportunity.Id,
////                        Opportunity.AccountId
////                })
////                .toSetOfIds();
////
////        System.assertEquals(expected, actual);
//    }
//
//
//    /**
//     *@description
//     * List of Opportunities is reduced to total of Amounts
//     */
//    @IsTest
//    static void testReduceToSum() {
//        Decimal expected = 0;
//        for (Opportunity opportunity : opportunities) {
//            expected += opportunity.Amount;
//        }
//
//        Decimal actual = Collection.of(opportunities)
//                .reduce(Opportunity.Amount)
//                .toSum();
//
//        System.assertEquals(expected, actual);
//    }
//
//    /**
//     *@description
//     * List of Opportunities is reduced to max Amount
//     */
//    @IsTest
//    static void testReduceToMax() {
//        Decimal max = -9999;
//        for (Opportunity opportunity : opportunities) {
//            max = Math.max(max, opportunity.Amount);
//        }
//
//        Decimal actual = Collection.of(opportunities)
//                .reduce(Opportunity.Amount)
//                .toMax();
//
//        System.assertEquals(max, actual);
//        System.assertNotEquals(null, actual);
//    }
//
//
//    /**
//     * @description
//     * Collections.sort takes list of objects and comparator implementation.
//     * Sorted list is returned as result.
//     */
//    @IsTest
//    static void testSortByComparator() {
//        List<Opportunity> expected = new List<Opportunity>();
//        for (Integer i = opportunities.size() - 1; i >= 0; --i) {
//            expected.add(opportunities[i]);
//        }
//
//        List<Opportunity> actual = (List<Opportunity>) Collection.of(opportunities)
//                .orderBy(new ReverseProbabilityComparator())
//                .toList();
//
//        System.assertEquals(actual, expected);
//    }
//    private class ReverseProbabilityComparator implements Collection.Comparator {
//        public Integer compare(Object thisItem, Object otherItem) {
//            Opportunity thisOpp = (Opportunity) thisItem;
//            Opportunity otherOpp = (Opportunity) otherItem;
//
//            if (thisOpp.Probability < otherOpp.Probability) {
//                return 1;
//
//            } else if (thisOpp.Probability > otherOpp.Probability) {
//                return -1;
//
//            } else {
//                return 0;
//            }
//        }
//    }
//
//
//    /**
//     * @description
//     * Collections.sort sorts list of records by given field and order.
//     */
//    @IsTest
//    static void testSortByField() {
//        Opportunity previous;
//
//        List<Opportunity> sortedOpportunities = (List<Opportunity>) Collection.of(opportunities).orderBy(Opportunity.CreatedDate, true).toList();
//        for (Opportunity opportunity : sortedOpportunities) {
//            if (previous != null) {
//                System.assert(opportunity.CreatedDate >= previous.CreatedDate);
//            }
//            previous = opportunity;
//        }
//        previous = null;
//
//
//        sortedOpportunities = (List<Opportunity>) Collection.of(opportunities).orderBy(Opportunity.Name, false).toList();
//        for (Opportunity opportunity : sortedOpportunities) {
//            if (previous != null) {
//                System.assertEquals(-1, opportunity.Name.compareTo(previous.Name));
//            }
//            previous = opportunity;
//        }
//        previous = null;
//
//
//        sortedOpportunities = (List<Opportunity>) Collection.of(opportunities)
//                .orderBy(Opportunity.FiscalQuarter, true)
//                .toList();
//        for (Opportunity opportunity : sortedOpportunities) {
//            if (previous != null) {
//                System.assert(opportunity.FiscalQuarter >= previous.FiscalQuarter);
//            }
//            previous = opportunity;
//        }
//        previous = null;
//    }
//
//
//    /**
//     * @description
//     * Instance wrap method wraps Collection member list with custom Wrapper class (implementing Collection.Wrapper).
//     * This method can be chained with other Collection methods ex.
//     * <pre>
//     * Map<Id,OpportunityWrapper> ... = Collection.of(opportunities)
//     *      .filter(Opportunity.StageName,'==','Analysis')
//     *      .wrap(OpportunityWrapper.class)
//     *      .mapBy(new WrapperByOpportunityIdMapper());
//     * </pre>
//     */
//    @IsTest
//    static void testWrap() {
//        List<OpportunityWrapper2> wrappers = (List<OpportunityWrapper2>)
//                Collection.of(opportunities)
//                        .filter(Opportunity.NextStep, '==', 'Analysis')
//                        .wrap(OpportunityWrapper2.class)
//                        .toList();
//
//        System.assertEquals(wrappers.size(), 4);
//        for (Integer i = 0; i < wrappers.size(); i++) {
//            System.assertEquals(wrappers[i].opportunity, opportunities[i]);
//        }
//    }
//
//    public class OpportunityWrapper2 implements Collection.Wrapper {
//        public Opportunity opportunity;
//
//        public void wrap(Object item) {
//            this.opportunity = (Opportunity) item;
//        }
//
//        public String getName() {
//            return opportunity.Name;
//        }
//    }
//
//
//    /**
//     *@description
//     * Fills in the list with number of clones of provided prototype record.
//     */
//    @IsTest
//    static void testFill() {
//        Contact contact = new Contact(LastName = 'Test');
//
//        List<Account> accounts = (List<Account>)
//                Collection.of(new List<Account>())
//                        .fill(10, new Account(Name = 'Test Account', Contact__r = contact))
//                        .fill(10, new Account(Name = 'Other Account', Contact__r = contact), new Collection.CloneOptions(false, false, false, false))
//                        .toList();
//
//
//        System.assertEquals(20, accounts.size());
//
//        /*Test if clone is deep*/
//        accounts[0].Name += '0';
//        contact.LastName += '0';
//
//        for (Account account : accounts) {
//            System.debug(account.Contact__r.LastName);
//        }
//
//        for (Integer i = 1; i < 20; i++) {
//            if (i < 10) {
//                System.assertEquals('Test Account', accounts[i].Name);
//                System.assertEquals('Test', accounts[i].Contact__r.LastName);
//
//            } else {
//                System.assertEquals('Other Account', accounts[i].Name);
//                System.assertEquals('Test0', accounts[i].Contact__r.LastName);
//            }
//        }
//    }
//
//
//    /**
//     *@description
//     * ForEach executes action on each element in collection and can be chained using instance methods.
//     */
//    @IsTest
//    static void testForEach() {
//        List<Opportunity> opportunities = (List<Opportunity>) Collection.of(opportunities)
//                .forEach(new AppendIndexToOpportunityNameWorker())
//                .toList();
//
//        for (Integer i = 0; i < opportunities.size(); i++) {
//            System.assert(opportunities[i].Name.contains('' + i));
//        }
//    }
//
//    private class AppendIndexToOpportunityNameWorker implements Collection.Worker {
//        public void forEach(Object item, Integer index) {
//            ((Opportunity) item).Name += index;
//        }
//    }
//
//
//    /**
//     *@description
//     * find() returns first item accepted by ByFieldValue filter.
//     */
//    @IsTest
//    static void testFindReturnsFirstSObjectOfGivenFieldValue() {
//        Opportunity expected = opportunities[3];
//        Opportunity actual = (Opportunity) Collection.of(opportunities).find(Opportunity.FiscalQuarter, '==', 3);
//        System.assertEquals(expected, actual);
//    }
//
//    /**
//     *@description
//     * find() returns null if there's no item accepted by filter.
//     */
//    @IsTest
//    static void testFindReturnsNullWhenThereAreNoItemsAcceptedByFilter() {
//        Opportunity actual = (Opportunity) Collection.of(opportunities).find(Opportunity.Probability, '==', 1.5);
//        System.assertEquals(null, actual);
//    }
//
//
//    @IsTest
//    static void testFindByFilter() {
//        Opportunity expected = opportunities[5];
//        Opportunity actual = (Opportunity) Collection.of(opportunities).find(new OpportunityNameContainsFilter('5'));
//
//        System.assertEquals(expected, actual);
//    }
//
//    private class OpportunityNameContainsFilter implements Collection.Filter {
//        private String expr;
//
//        public OpportunityNameContainsFilter(String expr) {
//            this.expr = expr;
//        }
//
//        public Boolean accepts(Object item) {
//            return ((Opportunity) item).Name.contains(expr);
//        }
//    }
//
//
//    @IsTest
//    static void testMethodChaining() {
//        Map<Boolean, List<OpportunityWrapper2>> expected = new Map<Boolean, List<CollectionTest.OpportunityWrapper2>>{
//                true => new List<OpportunityWrapper2>(),
//                false => new List<OpportunityWrapper2>()
//        };
//
//        for (Integer i = 0; i < opportunities.size(); i++) {
//            Opportunity opp = opportunities[i];
//
//            if (opp.CreatedDate >= Date.today().addDays(-3)) {
//                opp.Name += i;
//
//                OpportunityWrapper2 wrapper = new OpportunityWrapper2();
//                wrapper.wrap(opp);
//
//                expected.get(opp.HasOpenActivity).add(wrapper);
//            }
//        }
//
//
//        Map<Boolean, List<OpportunityWrapper2>> actual = (Map<Boolean, List<OpportunityWrapper2>>)
//                Collection.of(opportunities)
//                        .filter(Opportunity.CreatedDate, '>=', Date.today().addDays(-3))
//                        .forEach(new AppendIndexToOpportunityNameWorker())
//                        .wrap(OpportunityWrapper2.class)
//                        .groupBy(new WrapperByOpenActivityMapper());
//
//
//        System.assertEquals(JSON.serialize(expected), JSON.serialize(actual));
//    }
//
//    private class WrapperByOpenActivityMapper implements Collection.KeyMapper {
//        public Object key(Object item) {
//            return ((OpportunityWrapper2) item).opportunity.HasOpenActivity;
//        }
//
//        public Type keyType() {
//            return Boolean.class;
//        }
//    }
}