import lightningAddress from './lightningAddress.html';
import LOCALE from "@salesforce/i18n/locale";

export default class LightningAddress {

    connectFieldExt({fieldInfo, objectInfo}) {
        const addressField = this.field;
        const addressComponents = {};
        this.fieldInfo = fieldInfo;

        Object.values(objectInfo.fields).forEach(field => {
            if (field.compoundFieldName === addressField) {
                addressComponents[field.compoundComponentName] = field;
            }
        });

        this.street = addressComponents.Street;
        this.city = addressComponents.City;
        this.country = addressComponents.Country;
        this.postalCode = addressComponents.PostalCode;
        this.province = addressComponents.State;
    }

    renderExt() {
        return lightningAddress;
    }

    get attributes() {
        return {
            addressLabel   : this.label,
            locale         : LOCALE,
            street         : this.getField(this.street?.apiName),
            streetLabel    : this.street?.label,
            city           : this.getField(this.city?.apiName),
            cityLabel      : this.city?.label,
            country        : this.getField(this.country?.apiName),
            countryLabel   : this.country?.label,
            postalCode     : this.getField(this.postalCode?.apiName),
            postalCodeLabel: this.postalCode?.label,
            province       : this.getField(this.province?.apiName),
            provinceLabel  : this.province?.label,
            variant        : this.inputVariant,
            ...this.typeAttributes
        };
    }

    getEventValue(event) {
        return {
            [this.street.apiName]    : event.target.street,
            [this.city.apiName]      : event.target.city,
            [this.province.apiName]  : event.target.province,
            [this.country.apiName]   : event.target.country,
            [this.postalCode.apiName]: event.target.postalCode,
        };
    }

    /**
     * Using lwc:else was duplicating address
     */
    get isEditMode() {
        return !this.isReadOnly;
    }
}