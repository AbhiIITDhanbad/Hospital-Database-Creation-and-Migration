# Hospital Database Migration & Automation (MySQL)

A relational database built in MySQL to replace a hospital's Excel-based record keeping. The project designs the schema from the existing spreadsheet data, migrates that data into it, and enforces business rules for scheduling, access control and reporting.

## Problem Statement

The hospital kept patient details, doctor rosters, appointments, prescriptions, lab reports and billing in a single Excel file, which led to duplicate IDs, unlinked records, invalid values, double-booked doctors and no way to report by department. The goal was to solve six problems:

| # | Problem | Solution |
|---|---------|----------|
| 1 | No unique identifiers | `AUTO_INCREMENT` primary keys on every table |
| 2 | Disconnected relationships | Foreign keys between departments, doctors, patients, appointments, prescriptions, bills and lab reports |
| 3 | Invalid / ambiguous data | `CHECK` constraints: gender in `M/F/O`, status in `Scheduled/Completed/Cancelled`; dates converted with `STR_TO_DATE` during migration |
| 4 | Unregulated scheduling | `BEFORE INSERT` trigger rejects past appointments and double-booking of a doctor |
| 5 | Open access to patient data | Stored procedure that authenticates a doctor and returns data based on role |
| 6 | Disconnected reporting | Stored procedure for monthly revenue by department |

## Schema

```
departments (departmentID, name)
doctors (doctorID, name, specialization, role, departmentID)
patients (patientID, name, DOB, gender, phone)
appointments (appointmentID, patientID, doctorID, appointmentTime, status)
prescriptions (precriptionID, appointmentID, medication, dosage)
bills (billID, appointmentID, amount, paid, billDate)
labreports (reportID, appointmentID, reportData, createdAt)
doctor_credentials (doctor_id, user_name, password)
```

## Data Migration

The Excel data was first loaded into a staging table, `hospital_data`, with columns named like `Doctors.Name` and `Patients.PatientID`. `INSERT INTO ... SELECT` statements then split it into the normalized tables above. Rows are filtered on non-empty IDs, and dates are converted to MySQL formats.

## Business Rules

**Appointment validation (trigger `CHECK_NEW_APPOINTMENT`)**
- Rejects appointments with a time in the past.
- Rejects an appointment if the same doctor already has a `Scheduled` appointment at that time.

**Role-based access (procedure `View_Doctor_Data(username, password)`)**
- Verifies the doctor's credentials, then looks up their role and department.
- A **senior** doctor sees patient, appointment, prescription and lab report data for all doctors in their department.
- Any other doctor sees only their own patients' data.

**Revenue reporting (procedure `Monthly_Revenue(year, month)`)**
- Returns total billed amount per department for the given month.

## Usage

```sql
-- Run the schema and migration script first
CALL View_Doctor_Data('doctor1', 'password');
CALL Monthly_Revenue(2024, 9);
```

## Tech

MySQL, with `CHECK` constraints, foreign keys, triggers and stored procedures.

## Files

- `Hospital Database project.sql`: schema, data migration, trigger and stored procedures
