import {api, LightningElement} from 'lwc';
import {RecordFormComponent} from "c/recordFormComponent";
import defaultLocale from '@salesforce/i18n/locale';

export default class RecordFormAddress extends RecordFormComponent(LightningElement) {
    @api addressLabel;
    @api addressLookupLabel;
    @api addressLookupPlaceholder;
    @api cityLabel;
    @api cityPlaceholder;
    @api countryDisabled;
    @api countryLabel;
    @api countryLookupFilter;
    @api countryOptions;
    @api countryPlaceholder;
    @api disabled;
    @api fieldLevelHelp;
    @api hideProvince;
    @api locale = defaultLocale;
    @api postalCodeLabel;
    @api postalCodePlaceholder;
    @api provinceLabel;
    @api provinceOptions;
    @api provincePlaceholder;
    @api readOnly;
    @api required;
    @api showAddressLookup;
    @api showCompactAddress;
    @api streetLabel;
    @api streetPlaceholder;
    @api validity;
    @api variant = 'standard';

    addressComponents;

    connectField({fieldInfo, objectInfo, recordTypePicklistValues, formParams}) {
        super.connectField(arguments[0]);
        this.getCompoundFields(objectInfo);
        this.getDefaults(fieldInfo);
    }

    getCompoundFields(objectInfo) {
        const addressField = this.field;
        this.addressComponents = {};

        Object.values(objectInfo.fields).forEach(field => {
            if (field.compoundFieldName === addressField) {
                this.addressComponents[field.compoundComponentName] = field;
            }
        });
    }

    getDefaults(fieldInfo) {
        let {Street, City, State, Country, PostalCode} = this.addressComponents;
        this.addressLabel = this.label ?? fieldInfo.label;
        this.streetLabel = this.streetLabel ?? Street?.label;
        this.cityLabel = this.cityLabel ?? City?.label;
        this.countryLabel = this.countryLabel ?? Country?.label;
        this.postalCodeLabel = this.postalCodeLabel ?? PostalCode?.label;
        this.provinceLabel = this.provinceLabel ?? State?.label;
    }

    get values() {
        let {Street, City, State, Country, PostalCode} = this.addressComponents;
        return {
            street    : this.getField(Street.apiName),
            city      : this.getField(City.apiName),
            state     : this.getField(State.apiName),
            country   : this.getField(Country.apiName),
            postalCode: this.getField(PostalCode.apiName),
        }
    }

    getEventValue(event) {
        let {Street, City, State, Country, PostalCode} = this.addressComponents;

        return {
            [Street.apiName]    : event.target.street,
            [City.apiName]      : event.target.city,
            [State.apiName]     : event.target.province,
            [Country.apiName]   : event.target.country,
            [PostalCode.apiName]: event.target.postalCode,
        }
    }
}