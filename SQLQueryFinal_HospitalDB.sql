-- Create Hospital Data Base
CREATE DATABASE Hospital

USE Hospital
GO
------------------------------------
--CREATE TABLES

CREATE TABLE Patients ( 
PatientID int IDENTITY(1, 1) NOT NULL PRIMARY KEY, 
FirstName nvarchar(50) NOT NULL,
MiddleName nvarchar(50) NULL,
LastName nvarchar(50) NOT NULL,
Address1 nvarchar(50) NOT NULL,
Address2 nvarchar(50) NULL,
PostCode nvarchar(10) NOT NULL,
DateOfBirth date NOT NULL,
InsuranceNr nvarchar(20) NOT NULL,
CONSTRAINT UC_Address UNIQUE (Address1, PostCode)
)

SELECT * FROM Patients
SELECT * FROM PatientContact
SELECT * FROM PatientLoginInfo
SELECT * FROM Available_Appointments
SELECT * FROM Appointments
SELECT * FROM MedicalRecords
SELECT * FROM PastAppointments
SELECT * FROM HospitalArchive
SELECT * FROM PatientFeedBack

-- SEQUENCIAL STEPS FOR DATABASE OPERATION  

--INSERT INTO Patients Table 
EXEC SP_EnterPatientDetails @FirstName= 'Albert', 
												@MiddleName='K', 
												@LastName='Einstien', 
												@Address1='110 Manchester Road',
												@Address2='Manchester',
												@PostCode='M70PE',
												@DateOfBirth='12-05-1992',
												@HealthInsuranceNr='111 222 3333',
												@EmailAddress='albertKE@gmail.com',
												@TelephoneNr='073547569873'



-- If Patient Already Have Login Profile, Then skip this step 
EXEC SP_SetLogin @UserName= 'albert900' , 
								 @Password='einstien7654' , 
								 @HealthInsuranceNr='111 222 3333' 


EXEC SP_ChooseAppointment @ChosenDate = '2024-09-02', 
													@ChosenTime = '01:00:00',
													@ChosenDoctorID ='RJ275', 
													@HealthInsuranceNr='111 222 3333'


-- IF Patient had visited the Hospital before, and has previous record. Then doctor needs to search this
EXEC SP_ShowPatientPastRecord @PrevPatientID = 31,  -- Show Patients Name -- DONE
											@PrevDoctorID = 'RJ275'
											

EXEC SPNewPrescription @PatientID = 31, 
											@NewDiagnosis = 'Kidney Infection (Pyelonephritis)', 
											@NewMedicine = 'Amoxicillin (Augmentin)', 
											@NewAllergies = 'Pets and Dusts';

SELECT * FROM MedicalRecords


-- AFTER THIS STEP, Patient has seen Doctor, and now appointment needs to be set as completed
EXEC SP_StatusComplete @Patient_ID = 31

-- CREATE SP, and include deleting data from Patient, Patient Contact, Patient Login Info
EXEC SP_StatusCancelled @Patient_ID = 6

-- NOW Patient can give Feed Back -- FeedBack will be displayed Automatically
EXEC SPFeedBack @PatientID = 31, @FeedBack = 'VERY GOOD'

-- To manually see FeedBack, Use this function
EXEC SPShowFeedBack

-------------------------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE PatientContact (
PatientContactID int IDENTITY(1, 10) NOT NULL PRIMARY KEY,
PatientID int NOT NULL FOREIGN KEY (PatientID) REFERENCES Patients (PatientID),
EmailAddress nvarchar(100) UNIQUE NULL CHECK (EmailAddress LIKE '%_@_%._%'),
TelephoneNr nvarchar(20) NULL, 
)

CREATE TABLE PatientLoginInfo (
LoginInfoID int IDENTITY(1, 20) NOT NULL PRIMARY KEY,
PatientID int NOT NULL FOREIGN KEY (PatientID) REFERENCES Patients (PatientID),
UserName nvarchar(20) UNIQUE NOT NULL,
Passwords nvarchar(50) UNIQUE NOT NULL, 
)

CREATE TABLE Department (
DepartmentID nvarchar(6) NOT NULL PRIMARY KEY,
DepartmentName nvarchar(50) NOT NULL 
)

CREATE TABLE Doctors (
DoctorID nvarchar(10) NOT NULL PRIMARY KEY,
DoctorName nvarchar(50) NOT NULL,
DepartmentID nvarchar(6) NOT NULL FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID)
)

CREATE TABLE Appointments (
AppointmentID int IDENTITY(100, 5) NOT NULL PRIMARY KEY,
PatientID int NOT NULL FOREIGN KEY (PatientID) REFERENCES Patients (PatientID),
AppointDate date NOT NULL,
AppointTime time NOT NULL,
DepartmentID nvarchar(6) NOT NULL FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID),
AppointStatus nvarchar(50) NOT NULL,
DoctorID nvarchar(10) NOT NULL FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID)
)

CREATE TABLE PastAppointments (
PastAppointmentID int NOT NULL PRIMARY KEY,  
PatientID int NOT NULL FOREIGN KEY (PatientID) REFERENCES Patients (PatientID),
PastAppointDate date NOT NULL,
PastAppointTime time NOT NULL,
DepartmentID nvarchar(6) NOT NULL,
AppointStatus nvarchar(50) NOT NULL,
DoctorID nvarchar(10)
)

-----------------------------------------------------------------------

CREATE TABLE MedicalRecords (
MedicalRecordID int IDENTITY(1000, 100) NOT NULL PRIMARY KEY,
PatientID int NOT NULL FOREIGN KEY (PatientID) REFERENCES Patients (PatientID),
Diagnosis nvarchar(100) NOT NULL,
Medicines nvarchar(100) NOT NULL,
Allergies nvarchar(100) NULL,
DoctorID nvarchar(10) NOT NULL FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID) -- Cannot be Reference to Appointment DoctorID
)

SELECT * FROM Appointments

CREATE TABLE HospitalArchive (
HospitalArchiveID int IDENTITY(1, 5) NOT NULL PRIMARY KEY,
PatientID int NOT NULL FOREIGN KEY (PatientID) REFERENCES Patients (PatientID),
DoctorID nvarchar(10) NOT NULL, --FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID), Removed because if a doctor stops working at the hospital, or being removed from Doctors
MedicalRecordID int NOT NULL FOREIGN KEY (MedicalRecordID) REFERENCES MedicalRecords(MedicalRecordID),
PatientDischargeDate date NOT NULL   
)

CREATE TABLE PatientFeedBack (
FeedBackID int IDENTITY(1, 1) NOT NULL PRIMARY KEY,
PatientID int NOT NULL FOREIGN KEY (PatientID) REFERENCES Patients (PatientID),
FeedBack nvarchar(100)
)

DROP TABLE Available_Appointments
CREATE TABLE Available_Appointments (
AvailableAppointID int IDENTITY(1, 20) NOT NULL PRIMARY KEY,
AppointmentDate date NOT NULL,
AppointmentTime time NOT NULL,
DoctorName nvarchar(50) NOT NULL,
DoctorID nvarchar(10) NOT NULL,
DepartmentName nvarchar(50) NOT NULL,
DepartmentID nvarchar(6) NOT NULL
)

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- TRIGGERS 
--TRIGGER TO CHECK IF APPOINTMENT DATE NOT IN PAST
DROP TRIGGER IF EXISTS chk_appoint_date;
GO
CREATE TRIGGER chk_appoint_date
ON Appointments
AFTER INSERT, UPDATE
AS BEGIN
	DECLARE @InputDate date; 
	SELECT @InputDate = AppointDate FROM Appointments
    IF @InputDate < CONVERT (DATE,GETDATE())
        THROW 50001, 'Invalid Appointment Date is Entered :: Please Try Again with Correct Date', 1;
END
-----------------------------------------------------------------------
----------------------------------------------------------------------- 
--TRIGGER SYSTEM CHECK IF DOCTOR IS AVAILABLE WHEN PATIENT MAKES APPOINTMENT 
DROP TRIGGER IF EXISTS chk_doctr_availbl;
GO
CREATE TRIGGER chk_doctr_availbl
ON Appointments
AFTER INSERT, UPDATE
AS BEGIN
	DECLARE @Doctor_Id nvarchar(10);
	DECLARE @App_Date nvarchar(10);

	SELECT @Doctor_Id =  COUNT(DoctorID) FROM Appointments GROUP BY DoctorID HAVING COUNT(DoctorID)>1;
    SELECT @App_Date =  COUNT(AppointDate) FROM Appointments GROUP BY AppointDate HAVING COUNT(AppointDate)>1;

	-- Appointment for Same Doctor on Same Appointment Date Is Forbidden. DoctorID duplicate on different Date is allowed    
	IF ((@Doctor_Id > 1) AND (@App_Date > 1))
		THROW 51000, 'DOCTOR NOT AVAILABLE :: PLEASE CHOOSE APPOINTMENT ON ANOTHER DATE', 1;
	 
END
-----------------------------------------------------------------------
-----------------------------------------------------------------------
--TRIGGER to UPDATE Past Appointment Table when status= complete in Appointment 

DROP TRIGGER IF EXISTS PastAppointUpdate;
GO
CREATE TRIGGER PastAppointUpdate
ON Appointments
FOR UPDATE
AS BEGIN

DECLARE @status nvarchar(50)
SELECT @status = AppointStatus FROM Appointments WHERE AppointStatus = 'completed'

	--SELECT @status
	IF @status = 'completed'
		BEGIN
			PRINT ('Thank you For Visiting Our Hospital') 
			PRINT(' We would appreciate to have your FeedBack')
			PRINT(' To enter your FeedBack use ::SPFeedBack::@PatientID, @FeedBack)')

			INSERT INTO PastAppointments
			SELECT * FROM Appointments WHERE AppointStatus = 'completed' OR AppointStatus = 'cancelled' 

			DELETE FROM Appointments WHERE AppointStatus = 'completed'
			
		END
END			     
GO

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- TRIGGER UPDATE HospitalArchive Table with patient Data when status = complete in Appointment table (Patient Leaves Hospital)

DROP TRIGGER IF EXISTS Update_HospitalArchive;
GO
CREATE TRIGGER Update_HospitalArchive
ON Appointments
AFTER UPDATE
AS BEGIN
	
INSERT INTO HospitalArchive (PatientID, DoctorID,MedicalRecordID,PatientDischargeDate)
SELECT a.PatientID, a.DoctorID, m.MedicalRecordID, GETDATE() FROM Appointments as a INNER JOIN MedicalRecords as m 
ON a.PatientID = m.PatientID 
WHERE a.AppointStatus = 'completed' 
    
END
GO

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- Populating the Tables from .csv file with Hypothetical Data

--Table Patients
INSERT INTO Patients(FirstName, MiddleName, LastName, Address1, Address2, PostCode, DateOfBirth, InsuranceNr)
SELECT Patient_FirstName, Patient_MiddleName, Patient_LastName, Address_1, Address_2, PostCode, Patient_DOB, Insurance
FROM dbo.[HospitalDB.csv]

SELECT * FROM Patients

--Table PatientsContact -- TO BE RESOLVED, EMAIL CONSTRAINT 
INSERT INTO PatientContact(PatientID, EmailAddress, TelephoneNr)
SELECT DISTINCT p.PatientID, h.Email_Address , h.Telephone_Nr 
FROM Patients as p INNER JOIN dbo.[HospitalDB.csv] as h 
ON p.FirstName = h.Patient_FirstName

SELECT * FROM PatientContact

--Table PatientsLoginInfo --Password Hashed 
--declare @afterhash varbinary(256) = HASHBYTES('SHA2_256', 'P@ssw0rd')

INSERT INTO PatientLoginInfo (PatientID, UserName, Passwords)
VALUES (1, 'VKJoanna', HASHBYTES('SHA2_256', 'uk5ACZx7K2un')),
				(2, 'ICFerdie', HASHBYTES('SHA2_256', 'Akb9dJL5qsqq')),
				(3, 'PRGodfrey', HASHBYTES('SHA2_256', 'hXDkNBJrrGPX')),
				(4, 'LBJarvis', HASHBYTES('SHA2_256', 'XRYkhdf8Fs8C')),
				(5, 'TPSmith', HASHBYTES('SHA2_256', 'LXJM8yYWPZTw')),
				(6, 'BKBlack', HASHBYTES('SHA2_256', 'gJzFv9stemFj')),
				(7, 'LABelanger', HASHBYTES('SHA2_256', 'TvFPedWU8Dxn')),
				(8, 'RaminH', HASHBYTES('SHA2_256', '4XfecXyPPBHy')),
				(9, 'ShEve', HASHBYTES('SHA2_256', 'KdMRL5Ut8FHB')),
			  (10, 'AlanaAH', HASHBYTES('SHA2_256', 'SrCnYx6aNaYe'))

 SELECT * FROM PatientLoginInfo


--Table Department
INSERT INTO Department(DepartmentID, DepartmentName)
SELECT Department_ID2, Department_Name
FROM dbo.[HospitalDB.csv]

SELECT * FROM Department

-- Table Doctors
INSERT INTO Doctors(DoctorID, DoctorName, DepartmentID)
SELECT Doctor_ID, Doctor_Name, Department_ID2
FROM dbo.[HospitalDB.csv]


-- Table Appointments
INSERT INTO Appointments(PatientID,AppointDate, AppointTime, DepartmentID, AppointStatus, DoctorID)
SELECT DISTINCT p.PatientID, h.Date , h.Time, d.DepartmentID, h.Status, dt.DoctorID 
FROM Patients as p INNER JOIN dbo.[HospitalDB.csv] as h
ON p.FirstName = h.Patient_FirstName INNER JOIN Department as d 
ON d.DepartmentName= h.Department_Name INNER JOIN Doctors as dt
ON dt.DoctorName=h.Doctor_Name

SELECT * FROM Appointments

-- Table Medical Records
INSERT INTO MedicalRecords(PatientID, Diagnosis, Medicines, Allergies, DoctorID)
SELECT DISTINCT p.PatientID , h.Diagnosis, h.Medicines, h.Allergies, h.Doctor_ID 
FROM Patients as p INNER JOIN dbo.[HospitalDB.csv] as h 
ON p.FirstName = h.Patient_FirstName 

SELECT * FROM MedicalRecords

--INSERT INTO MedicalRecords
--VALUES ('6', 'Stomach Pain', 'Diges Syrup', 'Dairy Products', 'LF103')


-- TABLE HospitalArchive-- Used in Trigger, When Appointment status changes to complete, then store patient data into this table

--Populate Available_Appointments Table
INSERT INTO Available_Appointments(AppointmentDate, AppointmentTime, DoctorName, DoctorID, DepartmentName, DepartmentID)
SELECT Available_Date, Available_Time, Doctor_Name, Doctor_ID, Department_Name, Department_ID FROM dbo.[AvailableAppointments.csv]

SELECT * FROM Available_Appointments


-----------------------------------------------------------------------
-- STORED PROCEDURES
-- SP for Doctor to Update Medical Record with new Diagnosis, Medicine and Allergies
DROP PROCEDURE IF EXISTS SPNewPrescription;
GO
CREATE PROCEDURE SPNewPrescription (@PatientID int, 
																	@NewDiagnosis nvarchar(100), 
																	@NewMedicine nvarchar(100), 
																	@NewAllergies nvarchar(100))
AS
	BEGIN
		
		DECLARE @DocID nvarchar(20)
		SELECT @DocID = DoctorID FROM Appointments WHERE PatientID = @PatientID

		DECLARE @Result AS INT

		IF EXISTS (SELECT * FROM MedicalRecords WHERE PatientID = @PatientID AND DoctorID = @DocID )  

			BEGIN	
				UPDATE MedicalRecords
				SET Diagnosis=@NewDiagnosis, Medicines=@NewMedicine, Allergies=@NewAllergies 
				WHERE PatientID = @PatientID AND DoctorID = @DocID
			END

		ELSE

			BEGIN
				INSERT INTO MedicalRecords
				VALUES (@PatientID, @NewDiagnosis, @NewMedicine, @NewAllergies, @DocID)
			END
			
END;
-----------------------------------------------------------------------
--TEST SP NewPrescription
EXEC SPNewPrescription @PatientID = 11, @NewDiagnosis = 'ToothAche', @NewMedicine = 'Levofloxacin', @NewAllergies = 'NA';

-----------------------------------------------------------------------
-- SP for Doctor to Get Patient's Previous Medical Record 
DROP PROCEDURE IF EXISTS SP_ShowPatientPastRecord;
GO
CREATE PROCEDURE SP_ShowPatientPastRecord @PrevPatientID INT,
																					   @PrevDoctorID NVARCHAR(20)
AS
	BEGIN
		DECLARE @CheckPrevID INT
		SELECT @CheckPrevID = PatientID FROM MedicalRecords WHERE DoctorID = @PrevDoctorID 
		
		--IF Patient has already visited a doctor before and have previous record 
		--ELSE Patient has visited first time to hospital
		
		IF (@CheckPrevID IS NOT NULL)
			BEGIN
				SELECT m.MedicalRecordID, p.FirstName, p.MiddleName, p.LastName, p.InsuranceNr, m.Diagnosis, m.Medicines, m.Allergies, m. DoctorID 
				FROM MedicalRecords as m INNER JOIN Patients as p 
				ON p.PatientID = m.PatientID
				WHERE m.DoctorID = @PrevDoctorID AND m.PatientID = @PrevPatientID
			END
		ELSE 
			BEGIN
				PRINT ('NO PREVIOUS RECORD FOUND')
			END
END;

-----------------------------------------------------------------------
-- SP for Patient to input feedback when status = completed
DROP PROCEDURE IF EXISTS SPFeedBack;
GO
CREATE PROCEDURE SPFeedBack (@PatientID int, @FeedBack nvarchar(100))
AS
	BEGIN
		
		INSERT INTO PatientFeedBack (PatientID, FeedBack) 
		SELECT @PatientID, @FeedBack  
		
		EXEC SPShowFeedBack

END;
-----------------------------------------------------------------------
------------------------------------------------------------------------
-- SP to Display Patient feedback 
DROP PROCEDURE IF EXISTS SPShowFeedBack;
GO
CREATE PROCEDURE SPShowFeedBack 
AS
	BEGIN
		
		SELECT * FROM PatientFeedBack

END;

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- STEPS TO FOLLOW
-- SP for Patient to Enter Personal Information 
DROP PROCEDURE IF EXISTS SP_EnterPatientDetails;
GO
CREATE PROCEDURE SP_EnterPatientDetails (@FirstName nvarchar(50), 
																			  @MiddleName nvarchar(50),
																			  @LastName nvarchar(50),
																			  @Address1 nvarchar(50), 
																			  @Address2 nvarchar(50),
																			  @PostCode nvarchar(10),
																			  @DateOfBirth date, 
																			  @HealthInsuranceNr nvarchar(20),
																			  @EmailAddress nvarchar(100),
																			  @TelephoneNr nvarchar(20))
AS
	BEGIN
		
		DECLARE @chckInsurnceNr nvarchar(20) 
		SELECT @chckInsurnceNr = InsuranceNr FROM Patients WHERE FirstName = @FirstName AND LastName = @LastName AND DateOfBirth = @DateOfBirth
		
		SELECT @chckInsurnceNr

		IF (@chckInsurnceNr = @HealthInsuranceNr)
			BEGIN
				PRINT('Patient Record Already Exists. You Can Access Available Appointments With Your Login Details')
			END
		ELSE
		BEGIN
			INSERT INTO Patients(FirstName, MiddleName, LastName, Address1, Address2, PostCode, DateOfBirth, InsuranceNr)
			SELECT @FirstName, @MiddleName, @LastName, @Address1, @Address2, @PostCode, @DateOfBirth, @HealthInsuranceNr 

			--WAITFOR DELAY '00:00:01'
			DECLARE @ID int
			SELECT @ID = PatientID FROM Patients WHERE Patients.InsuranceNr = @HealthInsuranceNr

			INSERT INTO PatientContact (PatientID, EmailAddress, TelephoneNr)
			SELECT @ID, @EmailAddress, @TelephoneNr
		END
		
END;

-----------------------------------------------------------------------
-- SP for Patient to Enter login Information 
DROP PROCEDURE IF EXISTS SP_SetLogin;
GO
CREATE PROCEDURE SP_SetLogin (@UserName nvarchar(50), 
																@Password nvarchar(50),
																@HealthInsuranceNr nvarchar(20))
AS
	BEGIN
		
		DECLARE @ID int
		SELECT @ID = PatientID FROM Patients WHERE Patients.InsuranceNr = @HealthInsuranceNr

		INSERT INTO PatientLoginInfo(PatientID, UserName, Passwords)
		SELECT @ID, @UserName, HASHBYTES('SHA2_256', @Password) 

		SELECT * FROM PatientLoginInfo
		
END;

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- SP for Checking Patient Login Info to Access Available Appointments  
DROP PROCEDURE IF EXISTS SP_AccessAppointments;
GO
CREATE PROCEDURE SP_AccessAppointments (@UserName nvarchar(50), 
																@Password nvarchar(50),
																@HealthInsuranceNr nvarchar(20))
AS
	BEGIN
		
		DECLARE @UserCheck nvarchar(20)
		DECLARE @PassCheck nvarchar(20)

		SELECT @UserCheck = p.UserName FROM PatientLoginInfo as p INNER JOIN Patients as t ON p.PatientID=t.PatientID WHERE t.InsuranceNr = @HealthInsuranceNr 
		SELECT @PassCheck = p.Passwords FROM PatientLoginInfo as p INNER JOIN Patients as t ON p.PatientID=t.PatientID WHERE t.InsuranceNr = @HealthInsuranceNr

		IF @UserCheck = @UserName
			BEGIN
				SELECT * FROM Available_Appointments
				PRINT ('Please Use ::SP_ChooseAppointment:: To Book Appointment Date From List')
			END
		ELSE
			PRINT ('Entered User Name and Password Not Matched, Please Enter Correct UserName and Password OR Register into our Login Portal')
END;

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- SP for Patient to Choose an Appointment Date from Available Appointments  -- DONE
DROP PROCEDURE IF EXISTS SP_ChooseAppointment;
GO
CREATE PROCEDURE SP_ChooseAppointment (@ChosenDate date, 
																@ChosenTime time,
																@ChosenDoctorID nvarchar(10),
																@HealthInsuranceNr nvarchar(20))
AS BEGIN
		
		-- Check if User Entered Correct Date, Time and Doctor ID From Available Appointments
		IF NOT EXISTS(SELECT AppointmentDate FROM Available_Appointments WHERE AppointmentDate LIKE @ChosenDate)
		BEGIN
			PRINT ('Invalid Date, Please Try Again with Correct Date From Available Appointments')
		END
		
		ELSE IF NOT EXISTS(SELECT AppointmentTime FROM Available_Appointments WHERE AppointmentTime LIKE @ChosenTime)
		BEGIN
			PRINT ('Invalid Time, Please Try Again with Correct Time From Available Appointments')
		END
		
		ELSE IF NOT EXISTS(SELECT DoctorID FROM Available_Appointments WHERE DoctorID LIKE @ChosenDoctorID)
		BEGIN
			PRINT ('Invalid Doctor ID, Please Try Again with Correct Doctor ID From Available Appointments')
		END

		ELSE		
		BEGIN
			DECLARE @ID int
			DECLARE @DepartID nvarchar(20)
			DECLARE @DocID nvarchar(20)

			SELECT @ID = PatientID FROM Patients WHERE InsuranceNr = @HealthInsuranceNr 
			SELECT @DepartID = DepartmentID FROM Available_Appointments WHERE AppointmentDate = @ChosenDate AND AppointmentTime = @ChosenTime 
			SELECT @DocID = DoctorID FROM Available_Appointments WHERE DoctorID = @ChosenDoctorID

			INSERT INTO Appointments (PatientID, AppointDate, AppointTime, DepartmentID, AppointStatus, DoctorID) 
			SELECT @ID, @ChosenDate, @ChosenTime, @DepartID, 'Pending', @DocID

			WAITFOR DELAY '00:00:01'
			DELETE FROM Available_Appointments WHERE AppointmentDate = @ChosenDate AND AppointmentTime = @ChosenTime
		END	
END;
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- SP to Set Appointment Status to 'complete' 
DROP PROCEDURE IF EXISTS SP_StatusComplete;
GO
CREATE PROCEDURE SP_StatusComplete @Patient_ID INT
AS
	BEGIN
		UPDATE Appointments
		SET AppointStatus = 'completed'
		WHERE PatientID = @Patient_ID

END;

-----------------------------------------------------------------------
-- SP to Set Appointment Status to 'cancelled' 
DROP PROCEDURE IF EXISTS SP_StatusCancelled;
GO
CREATE PROCEDURE SP_StatusCancelled @Patient_ID INT
AS
	BEGIN
		UPDATE Appointments
		SET AppointStatus = 'cancelled'
		WHERE PatientID = @Patient_ID

END;

-----------------------------------------------------------------------
--TASK 2
-----------------------------------------------------------------------
--2..
--Add the constraint to check that the appointment date is not in the past. -- DONE
-----------------------------------------------------------------------

--3.. List all the patients with older than 40 and have Cancer in diagnosis
-- SP to Query for Patient Record Based On DIAGNOSIS and AGE --> Convert to Function = DONE
DROP FUNCTION IF EXISTS ListPatients;
GO
CREATE FUNCTION ListPatients (@Diag nvarchar(50), 
															       @Age nvarchar(50))
RETURNS TABLE AS 
RETURN (
	
		SELECT p.FirstName, p.MiddleName, p.LastName, p.DateOfBirth, m.MedicalRecordID, m.Diagnosis, m.Medicines, m.Allergies, m.DoctorID 
		FROM Patients as p INNER JOIN MedicalRecords as m ON p.PatientID = m.PatientID
		WHERE (m.Diagnosis = @Diag) AND DATEDIFF(hour,p.DateOfBirth,GETDATE())/8766.0 > @Age
)
-----------------------------------------------------------------------
--TEST Function ListPatients
SELECT * FROM dbo.ListPatients('Cancer', '40')
-----------------------------------------------------------------------
-- 6..
--TRIGGER so that the current state of an appointment can be changed to available when it is cancelled.
DROP TRIGGER IF EXISTS chk_cancel_Appoint;
GO
CREATE TRIGGER chk_cancel_Appoint
ON Appointments
AFTER UPDATE
AS BEGIN
	DECLARE @Status nvarchar(50); 
	DECLARE @Patient_Id INT; 
	SELECT @Status = AppointStatus FROM Appointments WHERE AppointStatus = 'cancelled'
	SELECT @Patient_Id = PatientID FROM Appointments WHERE AppointStatus = 'cancelled'
    
	IF @Status = 'cancelled'
		BEGIN
			WAITFOR DELAY '00:00:01'
			PRINT CONCAT('For Patient ID :: ',@Patient_Id, ' :: Appointment Cancelled Successfully: Please Book a New Appointment ')
			
			-- Move Cancelled Appointment Date and Time to Available Appointment Table
			INSERT INTO Available_Appointments (AppointmentDate, AppointmentTime, DoctorName, DoctorID, DepartmentName, DepartmentID)
			SELECT a.AppointDate, a.AppointTime, m.DoctorName, a.DoctorID, d.DepartmentName, a.DepartmentID FROM Appointments as a INNER JOIN Doctors as m 
			ON a.DoctorID = m.DoctorID INNER JOIN Department as d 
			ON d.DepartmentID = a.DepartmentID 
			WHERE a.AppointStatus = 'cancelled'

			--Delete cancelled appointment from Appointments
			DELETE FROM Appointments WHERE AppointStatus = 'cancelled'
			
		END
END
		
-----------------------------------------------------------------------
--7 Write a select query which allows the hospital to identify the number of completed appointments with the specialty of doctors as ‘Gastroenterologists’.
DROP PROCEDURE IF EXISTS SP_CompletedAppointments;
GO
CREATE PROCEDURE SP_CompletedAppointments (@Department nvarchar(50))
AS
	BEGIN

		SELECT pa.PastAppointmentID, pa.PatientID, pa.PastAppointDate, pa.PastAppointTime, pa.DepartmentID, pa.AppointStatus, pa.DoctorID, d.DepartmentName 
		FROM PastAppointments as pa INNER JOIN Department as d ON pa.DepartmentID = d.DepartmentID 
		WHERE d.DepartmentName = @Department AND pa.AppointStatus = 'completed'
		GROUP BY pa.PastAppointmentID, pa.PatientID, pa.PastAppointDate, pa.PastAppointTime, d.DepartmentID, pa.DepartmentID, pa.AppointStatus, pa.DoctorID, d.DepartmentName

	END;
-----------------------------------------------------------------------
EXEC SP_CompletedAppointments @Department = 'Gynecology'
--EXEC SP_CompletedAppointments @Department = 'Otolaryngology'
--EXEC SP_CompletedAppointments @Department = 'Urology'
--EXEC SP_CompletedAppointments @Department = 'Gastroenterology'


-----------------------------------------------------------------------
--8. Within your report, you will also need to provide your client with advice and guidance on:
--Data integrity and concurrency
--Database security
--Database backup and recovery

-----------------------------------------------------------------------
--4a. Search the database of the hospital for matching character strings by name of medicine. 
--Results should be sorted with most recent medicine prescribed date first.: 

DECLARE @MedString nvarchar(10)
SET @MedString = '%[en]'

SELECT m.PatientID, m.Diagnosis, m.Medicines, m.Allergies, m.DoctorID, m.MedicalRecordID, pa.PastAppointDate  FROM MedicalRecords as m INNER JOIN PastAppointments as pa 
ON m.PatientID = pa.PatientID
WHERE (m.Medicines LIKE @MedString) 
ORDER BY pa.PastAppointDate DESC


-----------------------------------------------------------------------
--4b. Return a full list of diagnosis and allergies for a specific patient who has an appointment today (i.e., the system date when the query is run)
DECLARE @PatientFirstName nvarchar(50), @PatientLastName nvarchar(50), @FullName nvarchar(50)
SET @PatientFirstName = 'Bernetta'
SET @PatientLastName = 'Blackbourne'


SELECT m.Diagnosis, m.Allergies, a.AppointDate, p.FirstName, p.LastName FROM MedicalRecords as m INNER JOIN Appointments as a 
ON m.PatientID = a.PatientID INNER JOIN Patients as p ON a.PatientID = p.PatientID
WHERE a.AppointDate = CONVERT (DATE,GETDATE()) AND p.FirstName = @PatientFirstName AND p.LastName = @PatientLastName

-----------------------------------------------------------------------
--c) Update the details for an existing doctor
-- Changing the Department of Doctor  

DROP PROCEDURE IF EXISTS SP_ChangeDoctorDepartment;
GO
CREATE PROCEDURE SP_ChangeDoctorDepartment (@NewDoctorID nvarchar(20), 
																							@DoctorName nvarchar(50), 
																							@NewDepartID nvarchar(20))
AS
	BEGIN

	DECLARE @OldDoctorID nvarchar(20) 
	SELECT @OldDoctorID = DoctorID FROM Doctors WHERE DoctorName = @DoctorName

-- Insert New Department Information Of Dr. Mila Simlick into Doctors Table
	INSERT INTO Doctors (DoctorID, DoctorName, DepartmentID)
	VALUES (@NewDoctorID, @DoctorName, @NewDepartID)

-- Delete Old Department Information Of Dr. Mila Simlick from foreign key dependent tables -- Appointment, 
	DELETE FROM Appointments 
	WHERE DoctorID  = @OldDoctorID

-- Delete Old Department Information Of Dr. Mila Simlick from foreign key dependent tables -- Available appointment
	DELETE FROM Available_Appointments 
	WHERE DoctorID  = @OldDoctorID

-- Delete Old Department Information Of Dr. Mila Simlick from foreign key dependent tables -- Medical Records
	DELETE FROM MedicalRecords 
	WHERE DoctorID  = @OldDoctorID

-- Delete Old Department Information Of Dr. Mila Simlick from Main table -- Doctors 
	DELETE FROM Doctors 
	WHERE DoctorID  = @OldDoctorID 

	END;

-- ##Doctor Information Updated Successful##
-----------------------------------------------------------------------

EXEC SP_ChangeDoctorDepartment @NewDoctorID = 'MS380', 
															 @DoctorName = 'Dr. Mila Simlick', 
															 @NewDepartID = 'GYNE'

SELECT * FROM Doctors
-----------------------------------------------------------------------

--d) Delete the appointment who status is already completed -- DONE
-----------------------------------------------------------------------

--The hospitals wants to view the appointment date and time, 
--showing all previous and current appointments for all doctors, 
--and including details of the department (the doctor is associated with), 
--doctor’s specialty and any associate review/feedback given for a doctor. 
--You should create a view containing all the required information.

DROP VIEW IF EXISTS [Required_Information]
GO
CREATE VIEW [Required_Information] AS

SELECT a.AppointDate as CurrAppointDate, a.AppointTime as CurrAppointTime, pa.PastAppointDate as PastAppointDate, pa.PastAppointTime as PastAppointTime, 
pa.DoctorID as PastAppointDocID, a.PatientID as CurrAppointPatientID, Dp.DepartmentID, Dp.DepartmentName, fb.FeedBack 

FROM Appointments as a FULL JOIN PastAppointments as pa 
ON a.PatientID = pa.PatientID FULL JOIN PatientFeedBack as fb 
ON fb.PatientID = a.PatientID FULL JOIN Department as Dp 
ON a.DepartmentID = Dp.DepartmentID

--SELECT * FROM Required_Information



