# Hospital Database Management System

## Introduction
The Hospital Database Management System is designed to streamline the process of patient management, appointment booking, and medical record maintenance. This system enhances efficiency by automating tasks such as patient registration, appointment scheduling, and the management of medical records. By utilizing stored procedures and triggers, it ensures data integrity and offers a user-friendly interface for both patients and healthcare providers.

## Tables and Schema Description:

1. **Patient Table:**
   - **Columns:**
     - `PatientID` (INT, Primary Key, IDENTITY)
     - `FirstName` (NVARCHAR(n), NOT NULL)
     - `MiddleName` (NVARCHAR(n), NULL)
     - `LastName` (NVARCHAR(n), NOT NULL)
     - `Address` (NVARCHAR(n), NOT NULL)
     - `PostCode` (NVARCHAR(n), NOT NULL)
     - `DateOfBirth` (DATE, NOT NULL)
     - `HealthInsuranceNumber` (NVARCHAR(n), NOT NULL)

2. **PatientsContact Table:**
   - **Columns:**
     - `ContactID` (INT, Primary Key, IDENTITY)
     - `PatientID` (INT, Foreign Key referencing Patient Table)
     - `EmailAddress` (NVARCHAR(n), NULL, UNIQUE, CHECK format)
     - `ContactNumber` (NVARCHAR(n), NULL)

3. **PatientLoginInfo Table:**
   - **Columns:**
     - `LoginInfoID` (INT, Primary Key, IDENTITY)
     - `UserName` (NVARCHAR(n), NOT NULL)
     - `Password` (NVARCHAR(100), NOT NULL, HASHBYTES for encryption)
     - `PatientID` (INT, Foreign Key referencing Patient Table)

4. **Department Table:**
   - **Columns:**
     - `DepartmentID` (INT, Primary Key, IDENTITY)
     - `DepartmentName` (NVARCHAR(n), NOT NULL)

5. **Doctors Table:**
   - **Columns:**
     - `DoctorID` (INT, Primary Key, IDENTITY)
     - `DoctorName` (NVARCHAR(n), NOT NULL)
     - `DepartmentID` (INT, Foreign Key referencing Department Table)

6. **Appointments Table:**
   - **Columns:**
     - `AppointmentID` (INT, Primary Key, IDENTITY)
     - `PatientID` (INT, Foreign Key referencing Patient Table)
     - `AppointmentDate` (DATE, NOT NULL)
     - `AppointmentTime` (TIME, NOT NULL)
     - `DepartmentID` (INT, Foreign Key referencing Department Table)
     - `AppointmentStatus` (NVARCHAR(n), NOT NULL)
     - `DoctorID` (INT, Foreign Key referencing Doctors Table)

7. **Past Appointments Table:**
   - **Columns:**
     - `PastAppointmentID` (INT, Primary Key, NOT NULL)
     - `PatientID` (INT, Foreign Key referencing Patient Table)
     - `PastAppointmentDate` (DATE, NOT NULL)
     - `PastAppointmentTime` (TIME, NOT NULL)
     - `DepartmentID` (INT, Foreign Key referencing Department Table)
     - `AppointmentStatus` (NVARCHAR(n), NOT NULL)
     - `DoctorID` (INT, Foreign Key referencing Doctors Table)

8. **Medical Records Table:**
   - **Columns:**
     - `MedicalRecordID` (INT, Primary Key, IDENTITY)
     - `PatientID` (INT, Foreign Key referencing Patient Table)
     - `Diagnosis` (NVARCHAR(n), NOT NULL)
     - `Medicines` (NVARCHAR(n), NOT NULL)
     - `Allergies` (NVARCHAR(n), NULL)
     - `DoctorID` (INT, Foreign Key referencing Doctors Table)

9. **Hospital Archive Table:**
   - **Columns:**
     - `HospitalArchiveID` (INT, Primary Key, NOT NULL, IDENTITY)
     - `PatientID` (INT, Foreign Key referencing Patient Table)
     - `DoctorID` (INT, NOT NULL)
     - `MedicalRecordID` (INT, Foreign Key referencing Medical Records Table)
     - `PatientDischargeDate` (DATE, NOT NULL)

## Database Diagram

![image](https://github.com/user-attachments/assets/f4179ee9-8e3b-4f58-91b2-4006ee6de293)

## Entity Relationships

- **Patients and Appointments**: A patient can book multiple appointments, establishing a 1 to N relationship.
- **Patients and Medical Records**: Each patient has one medical record, creating a 1 to 1 relationship.
- **Doctors and Medical Records**: A doctor can update many records, establishing a 1 to N relationship.
- **Doctors and Departments**: A doctor belongs to one department, while a department can have many doctors (N to 1 relationship).
- **Patients and Feedback**: A patient can provide multiple feedback entries, resulting in an N to 1 relationship.

# Procedural Steps for Using Database in following sequence:   
## Step 1: Enter Patient Information
The hospital aims to gather detailed patient information during appointment booking. A stored procedure, `SP_EnterPatientDetails`, requires input parameters including First Name, Middle Name, Last Name, Address (First and Second Parts), Post Code, Date of Birth, Health Insurance Number, Email Address, and Telephone Number. While most information is stored in the **Patients** table, Email and Telephone are saved in the **Patient Contact** table. The procedure checks for existing records based on First Name, Last Name, and Date of Birth, printing a message if the patient already exists.

- **For a New Patient**: A unique patient ID is assigned and the details are stored.
- **For an Existing Patient**: A message indicates the patient already exists.

## Step 2: Create Login
Patients must create a login, which involves entering a username and password. The `SP_SetLogin` stored procedure accepts parameters for Username, Password, and Insurance Number. Passwords are hashed using the `HASHBYTES` function before being stored in the **PatientLoginInfo** table.

## Step 3: Booking an Appointment
After logging in, patients select an appointment from the **AvailableAppointment** table, populated by hospital administration. The `SP_ChooseAppointment` stored procedure uses parameters like Chosen Date, Chosen Time, Chosen Doctor ID, and Insurance Number. Checks ensure that valid data is entered.

## Step 4: Doctor Accessing Patient Medical Record
Doctors can access a patient’s medical record using the `SP_ShowPatientPastRecord` procedure, which requires Previous Patient ID and Previous Doctor ID. If the patient is new, a message "No Previous Record Found" is displayed; otherwise, relevant medical records are shown.

## Step 5: Doctor Updates Medical Record (Prescription)
Doctors can update patient records using the `SPNewPrescription` stored procedure. Three scenarios are considered:
1. **No Past Record**: A new record is created.
2. **Different Past Doctor**: A new record is created linked to the current doctor.
3. **Same Past Doctor**: The existing record is updated.

## Step 6: Changing Appointment Status
After the consultation, the appointment status is updated to ‘completed’ using the `SP_StatusComplete` procedure. Triggers in the background handle record transfers and updates.

## Step 6b: Cancelling an Appointment
If a patient cancels an appointment, the `chk_cancel_Appoint` trigger detects the change in status to ‘cancelled’. The `SP_StatusCancelled` procedure updates the appointment table and makes the cancelled slot available again.

## Step 7: Patient Feedback
Patients can provide feedback using the `SPFeedBack` stored procedure, requiring the patient ID and feedback as parameters.


