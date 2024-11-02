# IF component
*Reduce the number of LWC getters.*

---
# Documentation
Simple utility to reduce the number of LWC getters, when they are used for lwc:if expressions.

Features the following properties:
- equals - value equals parameter
- notEquals - value does not equal parameter
- isTruthy - value is truthy
- isFalsy - value is falsy
- isOneOf - value is one of values in paramter (array or comma separated string)

```html
<c-if value={account.RecordType.DeveloperName} equals="PersonAccount">
    <!--...-->
</c-if>

<c-if value={account.RecordType.DeveloperName} equals="PersonAccount">
    <!--...-->
    <div slot="else">
        <!--Else-->
    </div>
</c-if>

<c-if value={account.RecordType.DeveloperName} not-equals="PersonAccount">
    <!--...-->
</c-if>

<c-if value={account.RecordType.DeveloperName} is-one-of="PersonAccount,Enterprise">
    <!--...-->
</c-if>

<c-if value={account.Contacts} is-truthy>
    <!--...-->
</c-if>

<c-if value={account.Contacts} is-falsy>
    <!--...-->
</c-if>
```

