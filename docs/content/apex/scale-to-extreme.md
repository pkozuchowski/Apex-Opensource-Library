# Scale to Extreme
*Thought experiment for testing solution's scalability.*

---
# Documentation

*Scale to Extreme* is a thought experiment that is helpful in testing solutions, framework or code.

The premise is simple — take your solution and imagine extreme conditions to test it against and think
if your code is still maintainable in such conditions, does it violate SOLID principles or other best programming practices.  
Then think how you could improve your solution.

## Example 1
Subject: Should I filter records in Trigger Handler before I pass it to the service class?

Experiment:  
Imagine we have 1,000,000 business requirements implemented in the trigger.  
What is easier to manage:
- Trigger Handler with 1,000,000 filtering methods
- or 1,000,000 classes encapsulating each business req.

In this case, Trigger Handler would blow out of proportions and break SRP. The valid solution is leaving only orchestration in Trigger Handler,
but no business logic of any sort.


## Example 2
I'm implementing selector layer. Should I make a service class with simple methods doing queries?

Experiment:
What if this service is used by 1,000 client classes, and each has different set of fields or conditions?  
In the worst case, we will end up with 1,000 very similar methods, where each method is different by fields, conditions, limit or other clauses.

Design is not scalable and query methods won't be reusable. Client code needs an ability to modify the query in some way.