# Visa ↔ Mastercard Field Mapping Quick Reference

Cross-reference of key authorization message fields between Visa (VisaNet ISO 8583) and Mastercard (IPM DE format).

## Transaction Classification Fields

| Concept | Visa Field | Visa GWC Column | MC Field | MC GWC Column |
|---|---|---|---|---|
| PAN Entry Mode | Field 22, pos 1-2 | `pos_entry_mode_pin_capability` (first 2 chars) | DE 22, subfield 1 | `parsed_request__pos_entry_mode` |
| PIN Capability | Field 22, pos 3 | `pos_entry_mode_pin_capability` (3rd char) | DE 22, subfield 2 | — |
| POS Environment (CIT/MIT) | Field 126.13 | `pos_environment` | N/A (use CIT/MIT indicator) | — |
| CIT/MIT Indicator | N/A | N/A | DE 48, SE 22, subfield 5 | `cit_mit_indicator` |
| Network Transaction ID (NTID) | Field 63.1 (single field) | `network_id` | Banknet Ref + Financial Network Code (two fields) | `parsed_response__network_data__banknet_reference_number` + `parsed_response__network_data__financial_network_code` |
| Trace ID | Field 62.2 / Field 125 | — | DE 105 SE 001 (TLID) + SE 002 | `parsed_request__additional_data_private__sub_elements__trace_id__bank_ref` + `...__network_code` |

## PAN Entry Mode Values

| Code | Visa Meaning (Field 22 pos 1-2) | MC Meaning (DE 22 subfield 1) |
|---|---|---|
| 01 | Manual key entry | Manual key entry |
| 05 | Contact chip (VSDC) | Contact chip (EMV) |
| 07 | Contactless chip (qVSDC) | Contactless chip (M/Chip) |
| 09 | N/A | E-commerce with DSRP cryptogram |
| 10 | Credential on file (previously stored) | Credential on file |
| 81 | N/A | E-commerce (no DSRP) |
| 82 | N/A | Contactless debt repayment |
| 90 | Magnetic stripe (CVV possible) | Magnetic stripe |
| 91 | Contactless mag stripe (dCVV) | Contactless mag stripe |

## CIT vs MIT Classification

### Visa: Field 22 (pos 1-2) + Field 126.13 (POS Environment)

| Scenario | Field 22 | Field 126.13 | Notes |
|---|---|---|---|
| CIT – initial storage (ad-hoc) | `01` (key entry) | `C` | First time storing credential |
| CIT – using stored credential | `10` | null (absent) | Consumer-initiated, credential already on file |
| MIT – unscheduled COF | `10` | `C` | Merchant-initiated, not recurring |
| MIT – initial recurring (CIT) | `01` or other | `R` | CIT establishing recurring series; `C`, `I`, or `R` all valid per spec p.744 |
| MIT – subsequent recurring | `10` | `R` | Merchant-initiated periodic billing |
| MIT – subsequent installment | `10` | `I` | Merchant-initiated installment |

Field 126.13 valid values: `C` (credential on file / unscheduled MIT), `R` (recurring), `I` (installment).
Spec: p.744-746 of VisaNet Auth-Only Online Messages.

### Mastercard: DE 22 subfield 1 + DE 48 SE 22 subfield 5 (CIT/MIT indicator)

**CIT indicators (C1xx):**
| Code | Meaning |
|---|---|
| C101 | Credential-on-file, ad hoc |
| C102 | Standing order (variable amount / fixed frequency) |
| C103 | Subscription (fixed amount / fixed frequency) |
| C104 | Installment |

**MIT indicators (M1xx = recurring/installment, M2xx = industry practice):**
| Code | Meaning |
|---|---|
| M101 | Unscheduled credential-on-file |
| M102 | Standing order (variable amount / fixed frequency) |
| M103 | Subscription (fixed amount / fixed frequency) |
| M104 | Installment |
| M205 | Partial shipment |
| M206 | Related / delayed charge |
| M207 | No-show |
| M208 | Resubmission |

**Key difference from Visa:** MC CIT/MIT indicator is explicit and self-describing. When null, DE 22 = `10` alone does NOT distinguish CIT from MIT.

**Fallback signals when CIT/MIT indicator is null:**
| MC Field | Value | Implies |
|---|---|---|
| DE 61 subfield 4 (POS Cardholder Presence) | `4` (Standing order/recurring) | MIT recurring |
| DE 61 subfield 4 | `0`-`3`, `5` (present/mail/phone/e-comm) | Likely CIT |
| DE 61 subfield 1 (POS Terminal Attendance) | `2` (No terminal used) | Leans MIT |
| DE 61 subfield 1 | `0` (Attended) | Leans CIT |

**Initial CIT for recurring (p.184-185):** The spec does NOT require DE 22 = `10` for the initial CIT establishing a recurring series. DE 22 reflects the actual PAN entry method (e.g., `09`, `81`). Only subsequent MITs require DE 22 = `10`.

**CIT indicator is required** in e-commerce when storing a credential (p.296), but **optional** in other environments. So null CIT/MIT indicator is common for non-e-commerce CITs.

Spec: p.183-186, 296-300 of MC Transaction Processing Rules.

## NTID (Network Transaction Identifier)

### Visa
Single field: **Field 63.1** — assigned by VisaNet on the response, must be echoed on subsequent transactions (reversals, recurring).

### Mastercard
Two-part composite: **Banknet Reference Number** + **Financial Network Code** — assigned by Mastercard network on response. For retry linkage, the request-side trace ID fields (`DE 105 SE 001 TLID` + `SE 002`) link back to the original.

## Spec Page References

| Topic | Visa Pages | MC Pages |
|---|---|---|
| PAN Entry Mode values | 187-188 | 280-287 |
| POS Environment / CIT-MIT | 744-746 | 296-300 |
| Credential-on-file rules | 185, 745 | 183-186 |
| Recurring payment rules | 400, 744 | 184-186 |
| NTID / Trace ID | 69 (Field 63.1) | 186 (TLID) |
| Installment payments | 531, 744 | 193, 297 |
| E-commerce identification | 185 | 285-287 |
