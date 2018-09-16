# Salesforce Developer Toolkit
## Introduction


## [Collections](https://github.com/amorek/sfdc-toolkit)
Most of the Salesforce business logic involves some sort of data collection transformations.
List of SObjects are filtered, mapped or grouped in almost every business process implemented in Apex.
This utility class contains methods for these common operations.

#### Features:
##### Gathering values
Family of `Collections.getUniqueValues()` methods return Set of field values from given records.

###### Examples
```java
Set<String> accountNames = Collections.getUniqueStringValues(accounts, Account.Name);
Set<Datetime> accountCreatedDates = Collections.getUniqueDatetimeValues(accounts, Account.Datetime);
Set<Id> parentAccountIds = Collections.getUniqueIdValues(accounts, 'ParentId');
/*...*/
```

##### Mapping
Map list of objects by given field or Mapper implementation.
```java
//Map by field
Map<String, Account> accountByNamesMap = (Map<String, Account>) Collections.mapByStringField(accounts, Account.Name);
Map<Id, Account> accountByParent = (Map<Id, Account>) Collections.mapByStringField(accounts, Account.ParentId);
/*...*/

//Map By KeyMapper
Map<Object,Account> accountsByBrandAndParent = (Map<Object,Account>) Collections.mapBy(accounts, new AccountBrandAndParentKeyMapper());
private class AccountBrandAndParentKeyMapper implements KeyMapper{
    public Object key(Object record){
        Account account = (Account) record;
        return account.Brand__c + account.ParentId;
    }
}
```

###### Examples

##### Grouping
###### Examples

##### Filtering
###### Examples

##### Sorting
###### Examples

##### Reducing
###### Examples

## Datatable
tbc
## XML Parser
tbc


You can use the [editor on GitHub](https://github.com/amorek/sfdc-toolkit/edit/master/README.md) to maintain and preview the content for your website in Markdown files.

Whenever you commit to this repository, GitHub Pages will run [Jekyll](https://jekyllrb.com/) to rebuild the pages in your site, from the content in your Markdown files.



### Markdown

Markdown is a lightweight and easy-to-use syntax for styling your writing. It includes conventions for

```markdown
Syntax highlighted code block

# Header 1
## Header 2
### Header 3

- Bulleted
- List

1. Numbered
2. List

**Bold** and _Italic_ and `Code` text

[Link](url) and ![Image](src)
```

For more details see [GitHub Flavored Markdown](https://guides.github.com/features/mastering-markdown/).

### Jekyll Themes

Your Pages site will use the layout and styles from the Jekyll theme you have selected in your [repository settings](https://github.com/amorek/sfdc-toolkit/settings). The name of this theme is saved in the Jekyll `_config.yml` configuration file.

### Support or Contact

Having trouble with Pages? Check out our [documentation](https://help.github.com/categories/github-pages-basics/) or [contact support](https://github.com/contact) and we’ll help you sort it out.
