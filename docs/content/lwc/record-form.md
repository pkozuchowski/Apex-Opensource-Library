# Record Form
*Create customizable record forms easily.*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/tree/master/force-app/commons/recordForm)
[Recipes](https://github.com/pkozuchowski/Apex-Opensource-Library/tree/master/force-app/examples/recordForm)
[Install In Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tJ6000000Lu7IIAS)
[Install In Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tJ6000000Lu7IIAS)

```bash
sf project deploy start -d "force-app/commons/recordForm" -o sfdxOrg
```

---
# Documentation

The `recordForm` provides an easy way to display and edit Salesforce records,
similar to `lightning-record-edit-form`, but the form and the fields are highly customizable and extensible.

The form component operates on a plain record object (`{field: value}`) passed from the parent and emits event with changed fields on field change.

The form fields attributes are defaulted from field definition metadata - label,
record field value, field type, picklist options, requiredness, read-only state, etc.
At the same time, a developer can override any of these attributes by passing custom values.
Developer can control the layout of the form, using HTML markup,
and the type of inputs – for example, to render picklists as radio-buttons.

There is also support for custom components and custom design systems other than Salesforce Lightning Design System.

## Example Usage
```html

<c-record-form object-api-name="Account"
               record-id="001KM00000KlMXkYAN"
               record-type-name="PersonAccount"
               record={account}
               density="compact"
               onchange={onRecordChange}>

    <c-record-form-field read-only field="OwnerId"></c-record-form-field>
    <c-record-form-field field="Name"></c-record-form-field>
    <c-record-form-field field="PersonMailingAddress"></c-record-form-field>
    <c-record-form-field field="Type"></c-record-form-field>

    <c-record-form-field field="MyMultipicklist__c" type="checkbox-group"></c-record-form-field>
    <c-record-form-field field="MyPicklist__c" type="radio-group"></c-record-form-field>
    <lightning-button type="submit" label="Submit"></lightning-button>
</c-record-form>
```

```js
export default class MyAccountForm extends LightningElement {
    @track account = {};

    onRecordChange(ev) {
        Object.assign(this.account, ev.detail.value);
    }
}
```

![recordForm1.png](/img/recordForm1.png)


## Supported Field Types
- Person Name
- Address
- Lookup
- Text
- Text Area
- Rich Text
- Number
- Percent
- Currency
- Date
- DateTime
- Time
- Checkbox
    - as Checkbox
    - as Checkbox Button
    - as Toggle
- Picklist
    - as Select
    - as Radio-Button
    - Record Type Picklist Values support
    - Dependent Picklist Support
- Multipicklist
    - as Dual Listbox
    - as Checkbox Group
- Email
- Phone
- URL

## Record Type Support
Record Form supports `"record-type"` attribute, which accepts Record Type's Developer Name. When specified, the form uses the record type to determine picklist
values, otherwise it uses the default record type.


## Validation

Each record-form-field supports the standard validation methods of `lightning-input`:
- `reportValidity()`
- `setCustomValidity(message)`
- `checkValidity()`

Additionally, Record Form has a number of methods which can be used in validation:
- `reportValidityForField(fieldName)` - reports validity of a specific field.
- `checkValidityForField(fieldName)` - checks validity of a specific field.
- `setCustomValidityForField(fieldName)` - sets custom validity for a specific field.

Bulk Methods:
- `reportValidity()` - reports validity of all fields.
- `checkValidity()` - reports validity of all fields.

Bulk methods return an object with a validity state of all fields:
```js
const result = {
    valid : boolean,
    fields: {
        FieldApiName: boolean
    }
}
```

## Submitting Form
Form can be submitted by calling `submit()` method on the form component or by using `lightning-button` with `type="submit"` inside the form.

Submit uses uiApi to create or update the createable/updateable fields on the record.
On successful submitting, the form emits a change event with the updated/created record or throws an error.

## Field Anatomy and Extensions

![recordFormField.png](/img/recordFormField.png)

Each form field extends base `c-record-form-component` component:
```js
import RecordFormComponent from "c/recordFormComponent";

export default class RecordFormField extends RecordFormComponent {

}
```

Base component provides a number of attributes, utility methods, validation methods and
a framework for connecting the field to the form and handling the field value changes.

### Connecting Fields to the Form
When component is connected (`connectedCallback`), it sends an event that bubbles up to the form:
```js
this.dispatchEvent(new CustomEvent('fieldconnected'));
```

Record Form listens to this and saves references to all connected fields and initializes them with the record, form attributes,
field, object description and record type picklist values.

Record Form calls `connectField` method on each field component:
```js
@api
connectField({fieldInfo, objectInfo, recordTypePicklistValues, formAttributes})
{
    this.label = this.label ?? fieldInfo.label;
    this.fieldLevelHelp = fieldInfo.inlineHelpText;
    this.required = this.required ?? fieldInfo.required;
    //...
}
```
Field components and extensions can override `connectField` method to customize initialization.

### Handling Field Value Changes
When field value changes, field component dispatches `change` event with all the fields that changed.
RecordFormComponent has a `handleFieldChange` utlity method that can be used in the HTML.
By default, it dispatches `change` event with `{[this.field]: event.detail.value}` payload,
but we can override this by overriding `getEventValue` method:

Example implementations could look like this:

```js
// text
getEventValue(event)
{
    return {[this.field]: event.detail.value}
}

// checkbox
getEventValue(event)
{
    return {[this.field]: event.detail.checked}
}

//Multi field update:
getEventValue(event)
{
    return {
        Salutation: event.detail.salutation,
        FirstName : event.detail.firstName
    }
}
```

The event bubbles up to the form's parent component, is applied on record and passed down to record-form and form fields.:
```js
export default class MyAccountForm extends LightningElement {
    @track account = {};

    onRecordChange(ev) {
        Object.assign(this.account, ev.detail.value);
    }
}
```

### Extending Field Types
Record Form Field provides a number of field types out of the box, but a new field types
or new variants of existing ones can be easily created.

Record Form Field operates on an Extension-based approach, where the base field contains the bare-bone logic and attributes,
and based on field info and design system, it picks up an Extension class.
Extension class is applied directly onto the Record-Form-Field component, mixing in new methods. One of the methods is `renderExt()`, which returns template for
the field.

Example Extension (TextArea):

```html

<template>
    <!--ReadOnly TextArea-->
    <c-record-form-field-output lwc:if={isReadOnly}
                                label={label}
                                density={formAttributes.density}>
        <lightning-formatted-text value={fieldValue}></lightning-formatted-text>
    </c-record-form-field-output>

    <!--Editable TextArea-->
    <lightning-textarea
            lwc:else
            lwc:spread={attributes}
            lwc:ref="input"
            class={classes}
            onchange={handleFieldChange}></lightning-textarea>
</template>
```

```js
export class LightningTextAreaExt extends LightningTextExt {
    get attributes() {
        return {
            ...super.attributes,
            myCustomAttribute: "Some Attribute Value"
        };
    }

    renderExt() {
        return lightningTextarea;
    }
}
```

### Creating custom components
To create custom components for a record form, you only need to extend `c-record-form-component`,
override `connectField` method if needed and dispatch `change` event with changed field values.

Then this component can be used in the form:
```html

<c-record-form object-api-name="Account"
               record-type-name="PersonAccount"
               record={account}
               density="compact"
               onchange={onRecordChange}>

    <c-record-form-field field="Name"></c-record-form-field>
    <c-record-form-file-upload field="Id"></c-record-form-file-upload>
</c-record-form>
```

## Considerations
- If record fields are nested in other components, make sure to render the wrapper component in `light` mode.

---
# Specification

## Record Form
### Attributes
| Attribute          | Description                                                                            |
|--------------------|----------------------------------------------------------------------------------------|
| `object-api-name`  | API Name of the object to display.                                                     |
| `record-type-name` | Record Type's Developer Name to use for picklist values.                               |
| `recordId`         | If provided, form will fetch record with fields on the form and fire onchange handler. |
| `record`           | Record object to display.                                                              |
| `density`          | Density of the form – "comfy", "compact".                                              |
| `formClass`        | CSS class to apply to the form.                                                        |
| `labelOverrides`   | Object with field names as keys and custom labels as values.                           |
| `designSystem`     | Design System to use for rendering the form. Defaults to "lightning".                  |
| `readOnly`         | If true, all fields are read-only.                                                     |

### Methods
| Method                                 | Description                                |
|----------------------------------------|--------------------------------------------|
| `submit()`                             | Creates/Updates the record.                |
| `checkValidity()`                      | Checks validity of all fields.             |
| `reportValidity()`                     | Reports validity of all fields.            |
| `reportValidityForField(fieldName)`    | Reports validity of a specific field.      |
| `checkValidityForField(fieldName)`     | Checks validity of a specific field.       |
| `setCustomValidityForField(fieldName)` | sets custom validity for a specific field. |
| `reportValidity()`                     | Reports validity of all fields.            |
| `checkValidity()`                      | Reports validity of all fields.            |

## Record Form Component

### Attributes
| Attribute        | Type      | Description                                                                                                                                         |
|------------------|-----------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| `field`          | `string`  | API name of the field this component represents (e.g. `"Name"`, `"OwnerId"`). Used to read the value from `record` and to build the change payload. |
| `record`         | `object`  | Plain record object in shape `{ [fieldApiName]: value }`. The component reads current value from it. Set by record form.                            |
| `fieldLevelHelp` | `string`  | Help text displayed for the field (typically sourced from the field's inline help text).                                                            |
| `readOnly`       | `boolean` | Forces the component into read-only mode. If not provided, the component can inherit read-only behavior from `formAttributes`.                      |
| `disabled`       | `boolean` | Disables user interaction with the field (visible, but not editable/interactable).                                                                  |
| `required`       | `boolean` | Marks the field as required. If not provided, it can default from field metadata.                                                                   |
| `validity`       | `object`  | Validity state for the underlying input. Shape depends on the input implementation used by the field type/extension.                                |
| `variant`        | `string`  | Label layout variant (commonly `"label-inline"` or `"label-stacked"`). If not provided, it can be derived from `formAttributes.density`.            |
| `designSystem`   | `string`  | Design system selector used to determine rendering behavior (e.g. Lightning vs custom design systems).                                              |
| `formAttributes` | `object`  | Form-level configuration passed down to fields (e.g. `density`, `readOnly`, etc.). Used as defaults when a field-level attribute is not set.        |

### Methods
| Method                       | Description                                |
|------------------------------|--------------------------------------------|
| `reportValidity()`           | Same as standard `lightning-input` method. |
| `setCustomValidity(message)` | Same as standard `lightning-input` method. |
| `checkValidity()`            | Same as standard `lightning-input` method. |

## Record Form Field (extends RecordFormComponent)

### Attributes
All attributes
from [lightning-input](https://developer.salesforce.com/docs/platform/lightning-component-reference/guide/lightning-input.html?type=Specifications)

| Attribute        | Type     | Description                                                                        |
|------------------|----------|------------------------------------------------------------------------------------|
| `typeAttributes` | `object` | Additional attributes to apply to the underlying input element.                    |
| `options`        | `array`  | Array of picklist values to present instead of the ones from the field metadata.   |
| `optionsFilter`  | `array`  | Subset of picklist values to display, from options or record type picklist values. |
