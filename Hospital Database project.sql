-- Schema Design.
-- Here are all the columns of the dataset that I got and separted as per the requirement.
-- DepartmentID, Department_Name
-- DoctorID, Name, Specialization, Role, DepartmentID
-- PatientID, Name, DOB, Gender, Phone
-- AppointmentID, PatientID, DoctorID, AppointmentTime, Status
-- PrescriptionID, AppointmentID, Medication, Dosage
-- BillID, AppointmentID, Amount,Paid, Date
-- ReportID, AppointmentID,ReportData, CreatedAt

-- Doctor Credentials
-- doctor_id, user_name, password

CREATE DATABASE EHIAS; -- Database Name
USE EHIAS;

-- Departmenbt Table
CREATE TABLE departments
(
departmentID int auto_increment Primary Key, -- now the departmentid cannot be duplicate and null . Problem 1 solved.
name varchar(100) not null
);

-- Doctors table
CREATE TABLE doctors
(
doctorID int auto_increment Primary Key, -- Problem 1 solved
name varchar(100),
specialization varchar(150),
role varchar(100),
departmentID int ,
foreign key(departmentID) references departments(departmentID) -- now only valid departments can be inserted . Problem 2 solved
);

-- Patients
CREATE TABLE PATIENTS(
patientID int auto_increment primary key,-- Problem 1 solved
name varchar(100),
DOB date,
gender varchar(1),
phone varchar(15),
check(gender in('m','f','o','M','F','O')) -- Problem 3 solved
);

-- Appointments
CREATE TABLE Appointments(
appointmentID int auto_increment primary key,-- Problem 1 solved
patientID int,
doctorID int,
appointmentTime datetime,
status varchar(20),
foreign key (patientID) references Patients(patientID), -- only valid patients entry for appointment . Problem 2 solved
foreign key (doctorID) references Doctors(doctorID), -- only valid doctor entry to fulfill appointment. Problem 2 solved
check(status in('Scheduled','Completed','Cancelled')) -- Problem 3 solved
);

-- Prescription table
CREATE TABLE prescriptions(
precriptionID int auto_increment primary key,-- Problem 1 solved
appointmentID int,
medication varchar(200),
dosage varchar(100),
foreign key (appointmentID) references Appointments(appointmentID) -- valid appointment id is allowed. Problem 2 solved.
);

-- Bill table

CREATE TABLE Bills(
billID int auto_increment primary key,-- Problem 1 solved
appointmentID int,
amount int,
paid tinyint(1),
billDate datetime default current_timestamp,
foreign key(appointmentID) references Appointments(appointmentID)-- Problem 2 solved.
);

-- Lab Reports
CREATE TABLE LabReports(
reportID int auto_increment primary key, -- Problem 1 solved
appointmentID int,
reportData text,
createdAt datetime default current_timestamp,
foreign key(appointmentID) references Appointments(appointmentID) -- Problem 2 solved
);
USE ehias;
SELECT * FROM hospital_data;
USE ehias;
-- Just simplifying column extraction for insertion or existing data migration
SELECT group_concat('`',COLUMN_NAME,'`') FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='ehias' AND TABLE_NAME='hospital_data'
AND COLUMN_NAME LIKE 'LabReports.%';

-- SELECT `Departments.DepartmentID`,`Departments.Name` FROM hospital_data;

-- INsert
INSERT INTO departments(departmentID,name)
SELECT `Departments.DepartmentID`,`Departments.Name` FROM hospital_data
WHERE `Departments.DepartmentID`!='';

SELECT * FROM departments;

INSERT INTO doctors(doctorID,name,specialization,role,departmentID)
SELECT `Doctors.DoctorID`,`Doctors.Name`,`Doctors.Specialization`,`Doctors.Role`,`Doctors.DepartmentID`
 FROM hospital_data
WHERE `Doctors.DepartmentID`>=1 AND `Doctors.DepartmentID`<=10;

INSERT INTO patients(patientID,name,DOB,gender,phone)
SELECT `Patients.PatientID`,`Patients.Name`,str_to_date(`Patients.DateOfBirth`,'%d-%m-%Y'),`Patients.Gender`,`Patients.Phone`
FROM hospital_data
WHERE `Patients.PatientID`!='';

INSERT INTO Appointments(appointmentID,patientID,doctorID,appointmentTime,status)
SELECT `Appointments.AppointmentID`,`Appointments.PatientID`,`Appointments.DoctorID`,str_to_date(`Appointments.AppointmentTime`,'%d-%m-%Y %H:%i'),`Appointments.Status`
FROM hospital_data
WHERE `Appointments.AppointmentID`!='';

INSERT INTO Prescriptions(precriptionID,appointmentID,medication,dosage)
SELECT `Prescriptions.PrescriptionID`,`Prescriptions.AppointmentID`,`Prescriptions.Medication`,`Prescriptions.Dosage`
FROM hospital_data
WHERE `Prescriptions.PrescriptionID`!='';

INSERT INTO Prescriptions(precriptionID,appointmentID,medication,dosage)
SELECT `Prescriptions.PrescriptionID`,`Prescriptions.AppointmentID`,`Prescriptions.Medication`,`Prescriptions.Dosage`
FROM hospital_data
WHERE `Prescriptions.PrescriptionID`!='';

INSERT INTO LabReports(reportID,appointmentID,reportData,createdAt)
SELECT `LabReports.ReportID`,`LabReports.AppointmentID`,`LabReports.ReportData`,`LabReports.CreatedAt`
FROM hospital_data
WHERE `LabReports.ReportID`!='';

-- USE ehias;
-- SELECT * FROM Prescriptions


-- Solving Problem 4 (Doctor's are being double-booked or back-time appointment inserted)

-- Forming Trigger to reject backdate and double-booking
DELIMITER $$
CREATE TRIGGER CHECK_NEW_APPOINTMENT
BEFORE INSERT ON APPOINTMENTS
FOR EACH ROW
BEGIN
	IF NEW.APPOINTMENTTIME < NOW() THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT= 'Error: Appointment cn not be in the past'; -- Custom Error Signal
    END IF;
    IF EXISTS(
		SELECT * FROM APPOINTMENTS
        WHERE DOCTORID= NEW.DOCTORID AND APPOINTMENTTIME=NEW.APPOINTMENTTIME AND STATUS IN ('Scheduled') -- Extracting if there exist same appointment time of same doctor
		)
    THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT= 'Error: appointment already exist at this time';
    END IF;
END $$
DELIMITER 



-- Validating the trigger
INSERT INTO APPOINTMENTS(appointmentid, patientid,doctorid,appointmenttime,status)
values(11,20,5,'2026-10-29 11:00:00','')
-- Result
-- 0	10	12:37:26	INSERT INTO APPOINTMENTS(appointmentid, patientid,doctorid,appointmenttime,status)
--  values(11,20,5,'2026-10-29 11:00:00','')	Error Code: 1644. Error: Appointment cn not be in the past	0.016 sec

-- Solving Problem 5 (Only Senior doctor can access all the patient informations across his department. Others can only see patients who are appointed to him/her only).

SELECT * FROM doctors;
-- Rough step by step mental checklist
-- first check of user id and password is valid otherwise immediately deny request.
-- retrieve the doctorID from valids
-- then you can have role and departmentID in doctor
-- patient , labreport, appointment , prescription table for pateient information to be shown to the doctor but only senior doctor (role column) can only view the entire department's info
-- role and departmentID in

-- As there are lot of things to do let's create procedures

DELIMITER $$
CREATE PROCEDURE View_Doctor_Data(IN input_username VARCHAR(100), IN input_password VARCHAR(100))
BEGIN
DECLARE doc_role VARCHAR(100);
DECLARE department_ID INT;
DECLARE doc_ID int;

SELECT doctor_ID INTO doc_ID
FROM doctor_credentials
WHERE user_name=input_username AND password=input_password;

SELECT role,departmentID INTO doc_role, department_ID
FROM doctors WHERE doctorID=doc_ID;

-- SHOW patient details
IF doc_role='senior' THEN
	SELECT P.patientID,p.name AS 'patient_name',P.gender,A.appointmenttime, P1.medication, L.reportdata
	FROM Patients AS P 
	INNER JOIN 
	Appointments AS A on A.patientID=P.patientID
	JOIN
	doctors as D ON A.doctorID=D.doctorID
	LEFT JOIN
	Prescriptions AS P1 ON A.appointmentID=P1.appointmentID
	LEFT JOIN
	LabReports AS L ON A.appointmentID=L.appointmentID
	WHERE D.departmentID = department_ID;
ELSE
	SELECT P.patientID,p.name AS 'patient_name',P.gender,A.appointmenttime, P1.medication, L.reportdata
	FROM Patients AS P 
	INNER JOIN 
	Appointments AS A on A.patientID=P.patientID
	LEFT JOIN
	Prescriptions AS P1 ON A.appointmentID=P1.appointmentID
	LEFT JOIN
	LabReports AS L ON A.appointmentID=L.appointmentID
	WHERE A.doctorID = doc_ID;
END IF;


END $$
DELIMITER 

-- patientID, patient_name, gender, appointmenttime, medication, reportdata
-- CALL View_Doctor_Data('doctor1','W3jzIANG')
-- CALL View_Doctor_Data('doctor4','ic0pFSn0')


-- Solving Problem 6 (Generate Montly revenue reports for each department)
DELIMITER $$
CREATE PROCEDURE Monthly_Revenue(IN yea INT, IN mont int)
BEGIN
SELECT D1.name AS department, SUM(B.amount) AS total_revenue FROM bills as B
Inner JOIN Appointments AS A ON A.appointmentID=B.appointmentID
Inner Join Doctors AS D ON A.doctorID=D.doctorID
INNER Join Departments AS D1 ON D1.departmentID=D.doctorID
WHERE MONTH(B.billdate)=mont AND Year(B.billdate)=yea
GROUP BY D1.name;
END $$
DELIMITER 

CALL Monthly_Revenue(2024,9)




