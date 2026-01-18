import lightningAddress from './lightningAddress.html';
import LOCALE from "@salesforce/i18n/locale";

export default class LightningAddressExt {
    locale = LOCALE;

    connectFieldExt({fieldInfo, objectInfo}) {
        const addressField = this.field;
        const addressComponents = {};
        this.fieldInfo = fieldInfo;

        Object.values(objectInfo.fields).forEach(field => {
            if (field.compoundFieldName === addressField) {
                addressComponents[field.compoundComponentName] = field;
            }
        });

        this.label = this.label ?? fieldInfo.label;
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
            variant        : this.variant ?? this.formVariant,
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
}