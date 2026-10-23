import { LightningElement, wire } from "lwc";
import { gql, graphql } from "lightning/graphql";

const FIRST_OPPORTUNITY_QUERY = gql`
    query FirstOpportunity {
        uiapi {
            query {
                Opportunity(first: 1) {
                    edges {
                        node {
                            Id
                        }
                    }
                }
            }
        }
    }
`;

export default class RecordFormRecordId extends LightningElement {
    recordId;
    errorMessage;

    @wire(graphql, { query: FIRST_OPPORTUNITY_QUERY })
    wiredOpportunity({ data, errors }) {
        if (errors?.length) {
            this.errorMessage = errors.map(({ message }) => message).join("; ");
            return;
        }

        if (data) {
            this.recordId = data.uiapi.query.Opportunity.edges[0]?.node?.Id;
            this.errorMessage = this.recordId ? undefined : "No Opportunity records were found.";
        }
    }
}
