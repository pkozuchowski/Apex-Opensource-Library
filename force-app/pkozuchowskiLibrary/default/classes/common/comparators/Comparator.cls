/**
 * Compares 2 objects to determine their order.
 * The implementation of this method should return the following values:
 * 0 if thisItem and otherItem are equal
 * > 0 if thisItem is greater than otherItem
 * < 0 if thisItem is less than otherItem
 */
public interface Comparator {
    Integer compare(Object thisItem, Object otherItem);
}