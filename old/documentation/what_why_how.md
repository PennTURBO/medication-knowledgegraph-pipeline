# When and how would I use the TURBO Medication Mapper?

## I want to identify patients from the Penn Medicine Biobank

(Or some other sub population of UPHS/PennMedicine patients)

Carnival can identify patients with links to medications based on drug roles (analgesic, antidepressant, antihistamine); role-bearing structural classes (statins, 

"Links to medications" means 
- a record in `PATIENT_ENCOUNTER` linking that patient's MRN or EMPI identifier to an encounter
- a record in `R_MEDICATION` defining the medication, especially the FULL_NAME
- a record in `ORDER_ME`D joining the encounter to the `R_MEDICATION`

Do not make the mistake of thinking the TURBO Medication Mapping results link a patient or encounter to the `ORDER_MED`'s `ORDER_NAME`

As of 2019-4-30 10:31, there were 942,089 `R_MEDICATION`s with 838,108 unique `FULL_NAME`s, and 826975 case-insensitive unique `FULL_NAME`s

As of 2019-4-30 10:31, there were 942,089 `R_MEDICATION`s with 838,108 unique `FULL_NAME`s, and 826975 case-insensitive unique `FULL_NAME`s

Whether the `ORDER_MED` entry reflects a medication that was actually administered, just ordered, or self-reported by the patient is not addressed here.  Clarifying that may require scanning additional tables.

### Example:  count religions (as a proxy for encounters) associated with 'VALACYCLOVIR HCL 1 G PO TABS'

```
SELECT
	pe.RELIGION_DESCRIPTION,
	COUNT(1)
FROM
	mdm.ORDER_MED om
JOIN mdm.R_MEDICATION rm ON
	om.FK_MEDICATION_ID = rm.PK_MEDICATION_ID
JOIN mdm.PATIENT_ENCOUNTER pe ON
	FK_PATIENT_ENCOUNTER_ID = pe.PK_PATIENT_ENCOUNTER_ID
WHERE
	rm.FULL_NAME = 'VALACYCLOVIR HCL 1 G PO TABS'
GROUP BY
	pe.RELIGION_DESCRIPTION
ORDER BY
	COUNT(1) DESC
```