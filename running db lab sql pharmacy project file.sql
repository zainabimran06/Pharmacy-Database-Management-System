DROP DATABASE IF EXISTS hospital_db;
CREATE DATABASE hospital_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE hospital_db;

CREATE TABLE PATIENT (
    PatientID   INT           PRIMARY KEY AUTO_INCREMENT,
    FirstName   VARCHAR(50)   NOT NULL,
    LastName    VARCHAR(50)   NOT NULL,
    DOB         DATE          NOT NULL,
    Gender      CHAR(1)       NOT NULL CHECK (Gender IN ('M','F','O')),
    Phone       VARCHAR(20)   NOT NULL,
    Email       VARCHAR(100)  UNIQUE,
    Address     TEXT,
    BloodGroup  VARCHAR(5)    CHECK (BloodGroup IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
    InsuranceID INT           NULL,
    CreatedAt   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE STAFF (
    StaffID     INT          PRIMARY KEY AUTO_INCREMENT,
    FirstName   VARCHAR(50)  NOT NULL,
    LastName    VARCHAR(50)  NOT NULL,
    Phone       VARCHAR(20)  NOT NULL UNIQUE,
    Email       VARCHAR(100) NOT NULL UNIQUE,
    Role        VARCHAR(50)  NOT NULL CHECK (Role IN ('Doctor','Nurse','Admin')),
    HireDate    DATE,
    IsActive    BOOLEAN      DEFAULT TRUE
);

CREATE TABLE DOCTOR (
    DoctorID        INT           PRIMARY KEY AUTO_INCREMENT,
    StaffID         INT           NOT NULL UNIQUE,
    Specialization  VARCHAR(100)  NOT NULL,
    Qualification   VARCHAR(100),
    ConsultationFee DECIMAL(10,2) NOT NULL CHECK (ConsultationFee >= 0),
    CONSTRAINT fk_doctor_staff FOREIGN KEY (StaffID) REFERENCES STAFF(StaffID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE NURSE (
    NurseID      INT         PRIMARY KEY AUTO_INCREMENT,
    StaffID      INT         NOT NULL UNIQUE,
    WardAssigned VARCHAR(50),
    CONSTRAINT fk_nurse_staff FOREIGN KEY (StaffID) REFERENCES STAFF(StaffID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE PERMANENT_NURSE (
    NurseID  INT           PRIMARY KEY,
    JoinDate DATE          NOT NULL,
    Salary   DECIMAL(10,2) NOT NULL CHECK (Salary > 0),
    CONSTRAINT fk_pnurse_nurse FOREIGN KEY (NurseID) REFERENCES NURSE(NurseID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE CONTRACT_NURSE (
    NurseID       INT          PRIMARY KEY,
    AgencyName    VARCHAR(100) NOT NULL,
    ContractStart DATE         NOT NULL,
    ContractEnd   DATE         NOT NULL,
    CONSTRAINT fk_cnurse_nurse  FOREIGN KEY (NurseID) REFERENCES NURSE(NurseID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_contract_dates CHECK (ContractEnd > ContractStart)
);

CREATE TABLE ADMIN_STAFF (
    AdminID        INT          PRIMARY KEY AUTO_INCREMENT,
    StaffID        INT          NOT NULL UNIQUE,
    Designation    VARCHAR(100) NOT NULL,
    OfficeLocation VARCHAR(100),
    CONSTRAINT fk_admin_staff FOREIGN KEY (StaffID) REFERENCES STAFF(StaffID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE DEPARTMENT (
    DeptID       INT          PRIMARY KEY AUTO_INCREMENT,
    DeptName     VARCHAR(100) NOT NULL UNIQUE,
    Wing         VARCHAR(50),
    HeadDoctorID INT          NULL,
    CONSTRAINT fk_dept_head FOREIGN KEY (HeadDoctorID) REFERENCES DOCTOR(DoctorID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE DOCTOR_DEPARTMENT (
    DoctorID INT NOT NULL,
    DeptID   INT NOT NULL,
    PRIMARY KEY (DoctorID, DeptID),
    CONSTRAINT fk_dd_doctor FOREIGN KEY (DoctorID) REFERENCES DOCTOR(DoctorID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_dd_dept   FOREIGN KEY (DeptID)   REFERENCES DEPARTMENT(DeptID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE ROOM (
    RoomID      INT         PRIMARY KEY AUTO_INCREMENT,
    DeptID      INT         NOT NULL,
    RoomNumber  VARCHAR(10) NOT NULL UNIQUE,
    Category    VARCHAR(20) NOT NULL CHECK (Category IN ('General','Private','ICU')),
    Capacity    INT         NOT NULL CHECK (Capacity > 0),
    IsAvailable BOOLEAN     DEFAULT TRUE,
    CONSTRAINT fk_room_dept FOREIGN KEY (DeptID) REFERENCES DEPARTMENT(DeptID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE APPOINTMENT (
    AppointmentID INT       PRIMARY KEY AUTO_INCREMENT,
    PatientID     INT       NOT NULL,
    DoctorID      INT       NOT NULL,
    AppDate       DATETIME  NOT NULL,
    Status        VARCHAR(20) NOT NULL DEFAULT 'Scheduled'
                  CHECK (Status IN ('Scheduled','Completed','Cancelled','No-Show')),
    Notes         TEXT,
    CONSTRAINT fk_appt_patient FOREIGN KEY (PatientID) REFERENCES PATIENT(PatientID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_appt_doctor  FOREIGN KEY (DoctorID)  REFERENCES DOCTOR(DoctorID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE TIMETABLE (
    SlotID      INT         PRIMARY KEY AUTO_INCREMENT,
    DoctorID    INT         NOT NULL,
    DayOfWeek   VARCHAR(10) NOT NULL
                CHECK (DayOfWeek IN ('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')),
    StartTime   TIME        NOT NULL,
    EndTime     TIME        NOT NULL,
    IsAvailable BOOLEAN     DEFAULT TRUE,
    CONSTRAINT fk_tt_doctor   FOREIGN KEY (DoctorID) REFERENCES DOCTOR(DoctorID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_tt_times   CHECK (EndTime > StartTime)
);

CREATE TABLE MEDICAL_RECORD (
    RecordID         INT  PRIMARY KEY AUTO_INCREMENT,
    PatientID        INT  NOT NULL,
    DoctorID         INT  NOT NULL,
    AppointmentID    INT,
    VisitDate        DATE NOT NULL,
    Diagnosis        TEXT,
    Prescription     TEXT,
    TestResults      TEXT,
    TreatmentDetails TEXT,
    CONSTRAINT fk_mr_patient FOREIGN KEY (PatientID)     REFERENCES PATIENT(PatientID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_mr_doctor  FOREIGN KEY (DoctorID)      REFERENCES DOCTOR(DoctorID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_mr_appt    FOREIGN KEY (AppointmentID) REFERENCES APPOINTMENT(AppointmentID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE BILLING (
    BillID        INT           PRIMARY KEY AUTO_INCREMENT,
    PatientID     INT           NOT NULL,
    AppointmentID INT,
    ConsultFee    DECIMAL(10,2) DEFAULT 0 CHECK (ConsultFee    >= 0),
    TestCharges   DECIMAL(10,2) DEFAULT 0 CHECK (TestCharges   >= 0),
    TreatCharges  DECIMAL(10,2) DEFAULT 0 CHECK (TreatCharges  >= 0),
    PaymentStatus VARCHAR(20)   NOT NULL DEFAULT 'Pending'
                  CHECK (PaymentStatus IN ('Paid','Pending','Partial','Waived')),
    BillDate      DATE          NOT NULL,
    CONSTRAINT fk_bill_patient FOREIGN KEY (PatientID)     REFERENCES PATIENT(PatientID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_bill_appt    FOREIGN KEY (AppointmentID) REFERENCES APPOINTMENT(AppointmentID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE ROOM_ASSIGNMENT (
    AssignmentID  INT  PRIMARY KEY AUTO_INCREMENT,
    PatientID     INT  NOT NULL,
    RoomID        INT  NOT NULL,
    AdmitDate     DATE NOT NULL,
    DischargeDate DATE NULL,
    CONSTRAINT fk_ra_patient FOREIGN KEY (PatientID) REFERENCES PATIENT(PatientID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_ra_room    FOREIGN KEY (RoomID)    REFERENCES ROOM(RoomID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_ra_dates  CHECK (DischargeDate IS NULL OR DischargeDate >= AdmitDate)
);

CREATE TABLE NURSE_ASSISTS (
    NurseID       INT NOT NULL,
    AppointmentID INT NOT NULL,
    PRIMARY KEY (NurseID, AppointmentID),
    CONSTRAINT fk_na_nurse FOREIGN KEY (NurseID)       REFERENCES NURSE(NurseID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_na_appt  FOREIGN KEY (AppointmentID) REFERENCES APPOINTMENT(AppointmentID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO PATIENT (FirstName,LastName,DOB,Gender,Phone,Email,Address,BloodGroup) VALUES
('Ahmed','Khan','1985-03-12','M','0300-1000001','ahmed.khan@gmail.com','House 1 Gulberg Lahore','A+'),
('Sara','Ali','1990-07-22','F','0300-1000002','sara.ali@gmail.com','House 2 DHA Lahore','B+'),
('Usman','Raza','1978-11-05','M','0300-1000003','usman.raza@gmail.com','House 3 Model Town','O+'),
('Ayesha','Malik','1995-01-30','F','0300-1000004','ayesha.malik@gmail.com','House 4 Johar Town','AB+'),
('Bilal','Shah','1982-09-18','M','0300-1000005','bilal.shah@gmail.com','House 5 Bahria Town','A-'),
('Fatima','Hussain','1998-04-25','F','0300-1000006','fatima.h@gmail.com','House 6 Wapda Town','B-'),
('Zain','Ahmed','1975-12-08','M','0300-1000007','zain.ahmed@gmail.com','House 7 Cantt','O-'),
('Nida','Iqbal','1988-06-14','F','0300-1000008','nida.iqbal@gmail.com','House 8 Allama Iqbal Town','AB-'),
('Tariq','Butt','1993-02-28','M','0300-1000009','tariq.butt@gmail.com','House 9 Gulshan Ravi','A+'),
('Sana','Mirza','1987-10-11','F','0300-1000010','sana.mirza@gmail.com','House 10 Shadman','B+'),
('Omar','Chaudhry','1991-05-19','M','0300-1000011','omar.ch@gmail.com','House 11 Garden Town','O+'),
('Hira','Nawaz','1996-08-03','F','0300-1000012','hira.nawaz@gmail.com','House 12 Faisal Town','A+'),
('Kamran','Siddiqui','1980-01-17','M','0300-1000013','kamran.sid@gmail.com','House 13 Gulberg III','B-'),
('Amna','Farooq','1999-11-22','F','0300-1000014','amna.farooq@gmail.com','House 14 Johar Town','AB+'),
('Danish','Mehmood','1983-07-09','M','0300-1000015','danish.m@gmail.com','House 15 DHA Phase 5','O+'),
('Rabia','Yousaf','1992-03-30','F','0300-1000016','rabia.y@gmail.com','House 16 Bahria Town','A-'),
('Faisal','Anwar','1976-09-24','M','0300-1000017','faisal.anwar@gmail.com','House 17 Model Town','B+'),
('Mariam','Bashir','1989-12-05','F','0300-1000018','mariam.b@gmail.com','House 18 Cantt','O-'),
('Junaid','Qadir','1994-04-16','M','0300-1000019','junaid.q@gmail.com','House 19 Gulshan Ravi','AB-'),
('Zara','Hassan','1997-08-27','F','0300-1000020','zara.hassan@gmail.com','House 20 Shadman','A+'),
('Aamir','Latif','1981-02-13','M','0300-1000021','aamir.l@gmail.com','House 21 Allama Iqbal','B+'),
('Nadia','Rehman','1986-06-07','F','0300-1000022','nadia.r@gmail.com','House 22 Garden Town','O+'),
('Imran','Zafar','1979-10-19','M','0300-1000023','imran.z@gmail.com','House 23 Faisal Town','AB+'),
('Kiran','Ashraf','1993-01-28','F','0300-1000024','kiran.a@gmail.com','House 24 Gulberg','A-'),
('Salman','Gilani','1990-05-04','M','0300-1000025','salman.g@gmail.com','House 25 DHA','B-'),
('Mehwish','Kazmi','1998-09-15','F','0300-1000026','mehwish.k@gmail.com','House 26 Bahria','O+'),
('Asad','Niazi','1977-03-21','M','0300-1000027','asad.niazi@gmail.com','House 27 Wapda Town','A+'),
('Aliya','Gondal','1988-07-12','F','0300-1000028','aliya.g@gmail.com','House 28 Model Town','B+'),
('Hamid','Virk','1995-11-08','M','0300-1000029','hamid.virk@gmail.com','House 29 Cantt','O-'),
('Sobia','Cheema','1982-04-23','F','0300-1000030','sobia.ch@gmail.com','House 30 Shadman','AB+'),
('Raza','Bajwa','1973-08-17','M','0300-1000031','raza.bajwa@gmail.com','House 31 Gulshan','A-'),
('Anum','Sheikh','1996-12-01','F','0300-1000032','anum.sh@gmail.com','House 32 Garden Town','B-'),
('Rizwan','Dar','1984-05-26','M','0300-1000033','rizwan.dar@gmail.com','House 33 Faisal Town','O+'),
('Farah','Taj','1991-09-11','F','0300-1000034','farah.taj@gmail.com','House 34 Johar Town','AB-'),
('Shahzad','Rana','1978-01-14','M','0300-1000035','shahzad.r@gmail.com','House 35 DHA','A+'),
('Mahnoor','Aslam','1999-06-29','F','0300-1000036','mahnoor.a@gmail.com','House 36 Bahria','B+'),
('Adnan','Haider','1985-10-03','M','0300-1000037','adnan.h@gmail.com','House 37 Wapda Town','O+'),
('Lubna','Saeed','1989-02-18','F','0300-1000038','lubna.s@gmail.com','House 38 Model Town','AB+'),
('Naveed','Qureshi','1976-07-07','M','0300-1000039','naveed.q@gmail.com','House 39 Cantt','A-'),
('Shazia','Lodhi','1994-11-20','F','0300-1000040','shazia.l@gmail.com','House 40 Shadman','B-'),
('Zahid','Chaudary','1981-03-15','M','0300-1000041','zahid.ch@gmail.com','House 41 Gulberg','O-'),
('Samia','Hamid','1987-07-28','F','0300-1000042','samia.h@gmail.com','House 42 Allama Iqbal','AB+'),
('Waqas','Pervez','1992-12-10','M','0300-1000043','waqas.p@gmail.com','House 43 Garden Town','A+'),
('Iram','Naqvi','1980-04-05','F','0300-1000044','iram.n@gmail.com','House 44 Faisal Town','B+'),
('Ejaz','Memon','1975-08-22','M','0300-1000045','ejaz.m@gmail.com','House 45 Johar Town','O+'),
('Asma','Khawaja','1997-01-09','F','0300-1000046','asma.kh@gmail.com','House 46 DHA','AB-'),
('Nasir','Abbasi','1983-05-31','M','0300-1000047','nasir.a@gmail.com','House 47 Bahria','A-'),
('Sadaf','Waheed','1990-09-14','F','0300-1000048','sadaf.w@gmail.com','House 48 Wapda Town','B-'),
('Pervaiz','Mughal','1977-02-27','M','0300-1000049','pervaiz.m@gmail.com','House 49 Model Town','O+'),
('Rubina','Akram','1995-06-19','F','0300-1000050','rubina.a@gmail.com','House 50 Cantt','AB+'),
('Shahid','Javed','1986-10-02','M','0300-1000051','shahid.j@gmail.com','House 51 Shadman','A+'),
('Uzma','Khalid','1993-03-25','F','0300-1000052','uzma.kh@gmail.com','House 52 Gulberg','B+'),
('Babar','Sami','1979-07-18','M','0300-1000053','babar.s@gmail.com','House 53 Allama Iqbal','O-'),
('Noor','Hashmi','1998-11-06','F','0300-1000054','noor.h@gmail.com','House 54 Garden Town','AB-'),
('Mohsin','Warraich','1984-04-11','M','0300-1000055','mohsin.w@gmail.com','House 55 Faisal Town','A-'),
('Tasneem','Bhatti','1991-08-24','F','0300-1000056','tasneem.b@gmail.com','House 56 Johar Town','B-'),
('Farhan','Zaidi','1976-12-17','M','0300-1000057','farhan.z@gmail.com','House 57 DHA','O+'),
('Misbah','Qadri','1988-05-08','F','0300-1000058','misbah.q@gmail.com','House 58 Bahria','AB+'),
('Azhar','Malik','1994-09-21','M','0300-1000059','azhar.m@gmail.com','House 59 Wapda Town','A+'),
('Shirin','Sattar','1982-01-14','F','0300-1000060','shirin.s@gmail.com','House 60 Model Town','B+'),
('Muzaffar','Aziz','1973-06-27','M','0300-1000061','muzaffar.a@gmail.com','House 61 Cantt','O+'),
('Amber','Riaz','1996-10-10','F','0300-1000062','amber.r@gmail.com','House 62 Shadman','AB-'),
('Wasim','Ansari','1985-02-03','M','0300-1000063','wasim.an@gmail.com','House 63 Gulberg','A-'),
('Farzana','Khatri','1989-07-16','F','0300-1000064','farzana.k@gmail.com','House 64 Allama Iqbal','B-'),
('Nabeel','Kashmiri','1992-11-29','M','0300-1000065','nabeel.k@gmail.com','House 65 Garden Town','O-'),
('Shehla','Zahid','1997-04-22','F','0300-1000066','shehla.z@gmail.com','House 66 Faisal Town','AB+'),
('Khalid','Awan','1980-08-15','M','0300-1000067','khalid.aw@gmail.com','House 67 Johar Town','A+'),
('Sumera','Basharat','1987-12-08','F','0300-1000068','sumera.b@gmail.com','House 68 DHA','B+'),
('Naeem','Ghauri','1975-05-01','M','0300-1000069','naeem.gh@gmail.com','House 69 Bahria','O+'),
('Afshan','Hasan','1993-09-24','F','0300-1000070','afshan.h@gmail.com','House 70 Wapda Town','AB-'),
('Sarfraz','Bhutto','1978-01-17','M','0300-1000071','sarfraz.b@gmail.com','House 71 Model Town','A-'),
('Gulnaz','Suleman','1986-06-10','F','0300-1000072','gulnaz.s@gmail.com','House 72 Cantt','B-'),
('Irfan','Baloch','1991-10-23','M','0300-1000073','irfan.bal@gmail.com','House 73 Shadman','O+'),
('Tehmina','Pasha','1999-03-16','F','0300-1000074','tehmina.p@gmail.com','House 74 Gulberg','AB+'),
('Saeed','Joiya','1974-07-09','M','0300-1000075','saeed.jo@gmail.com','House 75 Allama Iqbal','A+'),
('Rozina','Kausar','1995-11-02','F','0300-1000076','rozina.k@gmail.com','House 76 Garden Town','B+'),
('Mansoor','Toor','1981-04-25','M','0300-1000077','mansoor.t@gmail.com','House 77 Faisal Town','O-'),
('Haleema','Jatoi','1988-08-18','F','0300-1000078','haleema.j@gmail.com','House 78 Johar Town','AB-'),
('Sajjad','Rind','1976-12-11','M','0300-1000079','sajjad.r@gmail.com','House 79 DHA','A-'),
('Nusrat','Chattha','1994-05-04','F','0300-1000080','nusrat.ch@gmail.com','House 80 Bahria','B-'),
('Aslam','Gujjar','1983-09-17','M','0300-1000081','aslam.g@gmail.com','House 81 Wapda Town','O+'),
('Parveen','Dogar','1990-01-10','F','0300-1000082','parveen.d@gmail.com','House 82 Model Town','AB+'),
('Tanveer','Sipra','1977-06-03','M','0300-1000083','tanveer.s@gmail.com','House 83 Cantt','A+'),
('Bushra','Noon','1996-09-26','F','0300-1000084','bushra.n@gmail.com','House 84 Shadman','B+'),
('Ghulam','Mustafa','1985-02-19','M','0300-1000085','ghulam.m@gmail.com','House 85 Gulberg','O+'),
('Shaista','Manzoor','1992-07-12','F','0300-1000086','shaista.m@gmail.com','House 86 Allama Iqbal','AB-'),
('Qasim','Langah','1979-11-05','M','0300-1000087','qasim.l@gmail.com','House 87 Garden Town','A-'),
('Tahira','Ghazi','1998-03-28','F','0300-1000088','tahira.gh@gmail.com','House 88 Faisal Town','B-'),
('Imtiaz','Swati','1984-08-21','M','0300-1000089','imtiaz.s@gmail.com','House 89 Johar Town','O-'),
('Fouzia','Abbasi','1991-12-14','F','0300-1000090','fouzia.a@gmail.com','House 90 DHA','AB+'),
('Shaukat','Lashari','1973-05-07','M','0300-1000091','shaukat.l@gmail.com','House 91 Bahria','A+'),
('Nighat','Buriro','1987-09-30','F','0300-1000092','nighat.b@gmail.com','House 92 Wapda Town','B+'),
('Habib','Pirzada','1994-01-23','M','0300-1000093','habib.p@gmail.com','House 93 Model Town','O+'),
('Zohra','Chandio','1982-06-16','F','0300-1000094','zohra.ch@gmail.com','House 94 Cantt','AB-'),
('Shafiq','Mengal','1976-10-09','M','0300-1000095','shafiq.m@gmail.com','House 95 Shadman','A-'),
('Rehana','Sial','1993-02-02','F','0300-1000096','rehana.s@gmail.com','House 96 Gulberg','B-'),
('Mehmood','Talpur','1980-07-25','M','0300-1000097','mehmood.t@gmail.com','House 97 Allama Iqbal','O+'),
('Shakeela','Zehri','1997-11-18','F','0300-1000098','shakeela.z@gmail.com','House 98 Garden Town','AB+'),
('Riaz','Marri','1975-04-11','M','0300-1000099','riaz.marri@gmail.com','House 99 Faisal Town','A+'),
('Zubaida','Umrani','1989-08-04','F','0300-1000100','zubaida.u@gmail.com','House 100 Johar Town','B+'),
('Arshad','Bijarani','1986-12-27','M','0300-1000101','arshad.b@gmail.com','House 101 DHA','O-'),
('Naseem','Magsi','1995-05-20','F','0300-1000102','naseem.m@gmail.com','House 102 Bahria','AB-'),
('Liaqat','Zardari','1978-09-13','M','0300-1000103','liaqat.z@gmail.com','House 103 Wapda Town','A-'),
('Rukhsana','Bhutto','1991-01-06','F','0300-1000104','rukhsana.b@gmail.com','House 104 Model Town','B-'),
('Shakeel','Gilani','1984-06-29','M','0300-1000105','shakeel.g@gmail.com','House 105 Cantt','O+'),
('Andleeb','Pirzado','1998-10-22','F','0300-1000106','andleeb.p@gmail.com','House 106 Shadman','AB+'),
('Javaid','Soomro','1977-03-15','M','0300-1000107','javaid.s@gmail.com','House 107 Gulberg','A+'),
('Kishwar','Leghari','1992-07-08','F','0300-1000108','kishwar.l@gmail.com','House 108 Allama Iqbal','B+'),
('Aurangzeb','Khuhro','1983-11-01','M','0300-1000109','aurang.k@gmail.com','House 109 Garden Town','O+'),
('Maryam','Talpur','1996-04-24','F','0300-1000110','maryam.t@gmail.com','House 110 Faisal Town','AB-'),
('Sirajuddin','Bugti','1974-08-17','M','0300-1000111','siraj.b@gmail.com','House 111 Johar Town','A-'),
('Fauzia','Lund','1990-12-10','F','0300-1000112','fauzia.l@gmail.com','House 112 DHA','B-'),
('Attaullah','Mengal','1985-05-03','M','0300-1000113','attaullah.m@gmail.com','House 113 Bahria','O-'),
('Zubeda','Raisani','1993-09-26','F','0300-1000114','zubeda.r@gmail.com','House 114 Wapda Town','AB+'),
('Sardar','Akhtar','1979-01-19','M','0300-1000115','sardar.a@gmail.com','House 115 Model Town','A+'),
('Benazir','Domki','1997-06-12','F','0300-1000116','benazir.d@gmail.com','House 116 Cantt','B+'),
('Ghous','Bakhsh','1982-10-05','M','0300-1000117','ghous.b@gmail.com','House 117 Shadman','O+'),
('Shahnaz','Gabol','1988-02-28','F','0300-1000118','shahnaz.g@gmail.com','House 118 Gulberg','AB-'),
('Muzammil','Jamali','1994-07-21','M','0300-1000119','muzammil.j@gmail.com','House 119 Allama Iqbal','A-'),
('Fahmida','Mirza','1981-11-14','F','0300-1000120','fahmida.m@gmail.com','House 120 Garden Town','B-');

INSERT INTO STAFF (FirstName,LastName,Phone,Email,Role,HireDate) VALUES
('Dr Tariq','Mahmood','0311-2000001','tariq.doc@hospital.com','Doctor','2015-01-10'),
('Dr Amina','Siddiqui','0311-2000002','amina.doc@hospital.com','Doctor','2016-03-15'),
('Dr Hassan','Javed','0311-2000003','hassan.doc@hospital.com','Doctor','2014-07-20'),
('Dr Sana','Qureshi','0311-2000004','sana.doc@hospital.com','Doctor','2017-02-01'),
('Dr Rizwan','Bajwa','0311-2000005','rizwan.doc@hospital.com','Doctor','2013-09-05'),
('Dr Nadia','Cheema','0311-2000006','nadia.doc@hospital.com','Doctor','2018-06-12'),
('Dr Usman','Shah','0311-2000007','usman.doc@hospital.com','Doctor','2012-11-25'),
('Dr Rabia','Nawaz','0311-2000008','rabia.doc@hospital.com','Doctor','2019-04-30'),
('Dr Asad','Iqbal','0311-2000009','asad.doc@hospital.com','Doctor','2016-08-18'),
('Dr Zainab','Butt','0311-2000010','zainab.doc@hospital.com','Doctor','2020-01-07'),
('Dr Faisal','Raza','0311-2000011','faisal.doc@hospital.com','Doctor','2015-05-22'),
('Dr Hira','Anwar','0311-2000012','hira.doc@hospital.com','Doctor','2017-10-14'),
('Dr Kamran','Malik','0311-2000013','kamran.doc@hospital.com','Doctor','2011-03-08'),
('Dr Lubna','Ahmed','0311-2000014','lubna.doc@hospital.com','Doctor','2018-12-19'),
('Dr Shahzad','Ali','0311-2000015','shahzad.doc@hospital.com','Doctor','2014-06-03'),
('Yasmin','Fatima','0311-2000016','yasmin.nur@hospital.com','Nurse','2017-08-11'),
('Saima','Bibi','0311-2000017','saima.nur@hospital.com','Nurse','2018-02-14'),
('Rukhsar','Parveen','0311-2000018','rukhsar.nur@hospital.com','Nurse','2019-05-20'),
('Nazia','Kanwal','0311-2000019','nazia.nur@hospital.com','Nurse','2016-11-01'),
('Ambar','Shafiq','0311-2000020','ambar.nur@hospital.com','Nurse','2020-03-15'),
('Gulshan','Akhtar','0311-2000021','gulshan.nur@hospital.com','Nurse','2015-07-22'),
('Riffat','Begum','0311-2000022','riffat.nur@hospital.com','Nurse','2017-01-30'),
('Shaheen','Koser','0311-2000023','shaheen.nur@hospital.com','Nurse','2021-09-10'),
('Parveen','Bibi','0311-2000024','parveen.nur@hospital.com','Nurse','2018-06-18'),
('Zakia','Sultana','0311-2000025','zakia.nur@hospital.com','Nurse','2016-04-05'),
('Tariq','Aziz','0311-2000026','tariq.adm@hospital.com','Admin','2016-01-15'),
('Mahmood','Akhter','0311-2000027','mahmood.adm@hospital.com','Admin','2015-06-20'),
('Samina','Rafiq','0311-2000028','samina.adm@hospital.com','Admin','2017-09-25'),
('Zahoor','Hussain','0311-2000029','zahoor.adm@hospital.com','Admin','2018-03-10'),
('Rubab','Kazmi','0311-2000030','rubab.adm@hospital.com','Admin','2019-07-05'),
('Naveel','Chaudry','0311-2000031','naveel.adm@hospital.com','Admin','2020-11-20'),
('Asifa','Saleem','0311-2000032','asifa.adm@hospital.com','Admin','2016-04-15'),
('Saqlain','Mushtaq','0311-2000033','saqlain.adm@hospital.com','Admin','2014-08-30'),
('Anam','Zahra','0311-2000034','anam.nur@hospital.com','Nurse','2022-01-10'),
('Mehreen','Rauf','0311-2000035','mehreen.nur@hospital.com','Nurse','2021-05-25');

INSERT INTO DOCTOR (StaffID,Specialization,Qualification,ConsultationFee) VALUES
(1,'Cardiology','MBBS FCPS',2500.00),
(2,'Gynecology','MBBS FCPS',2000.00),
(3,'Orthopedics','MBBS MS',2200.00),
(4,'Neurology','MBBS FCPS MD',3000.00),
(5,'Gastroenterology','MBBS FCPS',1800.00),
(6,'Dermatology','MBBS FCPS',1500.00),
(7,'Pediatrics','MBBS DCH',1600.00),
(8,'ENT','MBBS FCPS',1700.00),
(9,'Urology','MBBS FCPS',2100.00),
(10,'Oncology','MBBS FCPS MD',3500.00),
(11,'Pulmonology','MBBS FCPS',1900.00),
(12,'Endocrinology','MBBS FCPS',2300.00),
(13,'Psychiatry','MBBS FCPS',2800.00),
(14,'Ophthalmology','MBBS FCPS',1400.00),
(15,'General Surgery','MBBS FRCS',2600.00);


INSERT INTO NURSE (StaffID,WardAssigned) VALUES
(16,'Cardiology Ward'),(17,'Maternity Ward'),(18,'Orthopedic Ward'),
(19,'Neurology Ward'),(20,'General Ward'),(21,'ICU'),
(22,'Pediatric Ward'),(23,'ENT Ward'),(24,'Urology Ward'),
(25,'Oncology Ward'),(34,'Emergency Ward'),(35,'Recovery Ward');


INSERT INTO PERMANENT_NURSE (NurseID,JoinDate,Salary) VALUES
(1,'2017-08-11',45000),(2,'2018-02-14',42000),(3,'2019-05-20',40000),
(4,'2016-11-01',46000),(5,'2020-03-15',38000),(6,'2015-07-22',50000),
(7,'2017-01-30',44000);

INSERT INTO CONTRACT_NURSE (NurseID,AgencyName,ContractStart,ContractEnd) VALUES
(8,'HealthStaff Agency','2025-01-01','2026-12-31'),
(9,'MedTemp Solutions','2025-03-01','2026-02-28'),
(10,'CareLink Agency','2024-07-01','2026-06-30'),
(11,'NurseNet Pakistan','2025-06-01','2026-05-31'),
(12,'StaffMed Pakistan','2024-09-01','2026-08-31');


INSERT INTO ADMIN_STAFF (StaffID,Designation,OfficeLocation) VALUES
(26,'Reception Manager','Main Reception'),
(27,'HR Officer','Admin Block Room 101'),
(28,'Billing Supervisor','Billing Department'),
(29,'IT Administrator','Server Room'),
(30,'Medical Records Officer','Records Room'),
(31,'Pharmacy Coordinator','Pharmacy Counter'),
(32,'Accounts Officer','Finance Office'),
(33,'Operations Manager','Admin Block Room 205');

INSERT INTO DEPARTMENT (DeptName,Wing,HeadDoctorID) VALUES
('Cardiology','East Wing',1),
('Gynecology & Obstetrics','West Wing',2),
('Orthopedics','North Wing',3),
('Neurology','East Wing',4),
('Gastroenterology','South Wing',5),
('Pediatrics','West Wing',7),
('Oncology','North Wing',10),
('General Surgery','South Wing',15);

INSERT INTO DOCTOR_DEPARTMENT (DoctorID,DeptID) VALUES
(1,1),(2,2),(3,3),(4,4),(5,5),(6,1),(7,6),(8,3),(9,5),(10,7),
(11,1),(12,4),(13,4),(14,6),(15,8),(1,8),(3,8),(5,4),(9,8),(12,5);


INSERT INTO ROOM (DeptID,RoomNumber,Category,Capacity,IsAvailable) VALUES
(1,'C-101','General',4,TRUE),(1,'C-102','Private',1,TRUE),(1,'C-103','ICU',2,FALSE),
(2,'G-101','General',4,TRUE),(2,'G-102','Private',1,FALSE),(2,'G-103','ICU',2,TRUE),
(3,'O-101','General',4,FALSE),(3,'O-102','Private',1,TRUE),(3,'O-103','ICU',2,TRUE),
(4,'N-101','General',4,TRUE),(4,'N-102','Private',1,TRUE),(4,'N-103','ICU',2,FALSE),
(5,'GI-101','General',4,TRUE),(5,'GI-102','Private',1,FALSE),(5,'GI-103','ICU',2,TRUE),
(6,'P-101','General',6,TRUE),(6,'P-102','Private',1,TRUE),(6,'P-103','ICU',2,FALSE),
(7,'ON-101','General',4,TRUE),(7,'ON-102','Private',1,TRUE),(7,'ON-103','ICU',2,FALSE),
(8,'S-101','General',4,FALSE),(8,'S-102','Private',1,TRUE),(8,'S-103','ICU',2,TRUE),
(1,'C-104','General',4,TRUE),(2,'G-104','General',4,TRUE),(3,'O-104','Private',1,TRUE),
(4,'N-104','Private',1,FALSE),(5,'GI-104','General',4,TRUE),(6,'P-104','General',6,TRUE);


INSERT INTO APPOINTMENT (PatientID,DoctorID,AppDate,Status,Notes) VALUES
(1,1,'2026-01-05 09:00:00','Completed','Chest pain evaluation'),
(2,2,'2026-01-06 10:30:00','Completed','Routine prenatal checkup'),
(3,3,'2026-01-07 11:00:00','Completed','Knee pain'),
(4,4,'2026-01-08 14:00:00','Completed','Migraine follow-up'),
(5,5,'2026-01-09 09:30:00','Completed','Acidity and GERD'),
(6,6,'2026-01-10 15:00:00','Completed','Skin rash'),
(7,7,'2026-01-11 08:30:00','Completed','Child fever'),
(8,8,'2026-01-12 16:00:00','Completed','Ear infection'),
(9,9,'2026-01-13 10:00:00','Completed','Kidney stones'),
(10,10,'2026-01-14 13:00:00','Completed','Oncology follow-up'),
(11,11,'2026-01-15 09:00:00','Completed','Asthma review'),
(12,12,'2026-01-16 11:30:00','Completed','Diabetes management'),
(13,13,'2026-01-17 14:30:00','Completed','Depression screening'),
(14,14,'2026-01-18 10:00:00','Completed','Eye checkup'),
(15,15,'2026-01-19 08:00:00','Completed','Pre-surgical consult'),
(16,1,'2026-01-20 09:00:00','Completed','BP monitoring'),
(17,2,'2026-01-21 10:30:00','Completed','Pregnancy checkup'),
(18,3,'2026-01-22 11:00:00','Completed','Fracture review'),
(19,4,'2026-01-23 14:00:00','Completed','EEG results review'),
(20,5,'2026-01-24 09:30:00','Completed','IBS management'),
(21,6,'2026-01-25 15:00:00','Completed','Acne treatment'),
(22,7,'2026-01-26 08:30:00','Completed','Vaccination'),
(23,8,'2026-01-27 16:00:00','Completed','Sinusitis'),
(24,9,'2026-01-28 10:00:00','Completed','Prostate checkup'),
(25,10,'2026-01-29 13:00:00','Completed','Chemo follow-up'),
(26,11,'2026-01-30 09:00:00','Completed','COPD review'),
(27,12,'2026-02-01 11:30:00','Completed','Thyroid check'),
(28,13,'2026-02-02 14:30:00','Completed','Anxiety management'),
(29,14,'2026-02-03 10:00:00','Completed','Glaucoma check'),
(30,15,'2026-02-04 08:00:00','Completed','Post-op review'),
(31,1,'2026-02-05 09:00:00','Completed','Palpitations'),
(32,2,'2026-02-06 10:30:00','Completed','Fertility consult'),
(33,3,'2026-02-07 11:00:00','Completed','Hip pain'),
(34,4,'2026-02-08 14:00:00','Completed','Seizure follow-up'),
(35,5,'2026-02-09 09:30:00','Completed','Liver function review'),
(36,6,'2026-02-10 15:00:00','Completed','Eczema review'),
(37,7,'2026-02-11 08:30:00','Completed','Growth check'),
(38,8,'2026-02-12 16:00:00','Completed','Hearing test'),
(39,9,'2026-02-13 10:00:00','Completed','UTI follow-up'),
(40,10,'2026-02-14 13:00:00','Completed','MRI results'),
(41,11,'2026-02-15 09:00:00','Completed','Pulmonary function test'),
(42,12,'2026-02-16 11:30:00','Completed','HbA1c review'),
(43,13,'2026-02-17 14:30:00','Completed','Bipolar screening'),
(44,14,'2026-02-18 10:00:00','Completed','Cataract consult'),
(45,15,'2026-02-19 08:00:00','Completed','Appendix review'),
(46,1,'2026-02-20 09:00:00','Completed','Cholesterol check'),
(47,2,'2026-02-21 10:30:00','Completed','Ovarian cyst'),
(48,3,'2026-02-22 11:00:00','Completed','Spine pain'),
(49,4,'2026-02-23 14:00:00','Completed','Parkinson screening'),
(50,5,'2026-02-24 09:30:00','Completed','Colonoscopy prep'),
(51,6,'2026-03-01 15:00:00','Completed','Psoriasis review'),
(52,7,'2026-03-02 08:30:00','Completed','Child development'),
(53,8,'2026-03-03 16:00:00','Completed','Tonsillitis'),
(54,9,'2026-03-04 10:00:00','Completed','Bladder scan'),
(55,10,'2026-03-05 13:00:00','Completed','Biopsy results'),
(56,11,'2026-03-06 09:00:00','Completed','Bronchitis review'),
(57,12,'2026-03-07 11:30:00','Completed','Insulin adjustment'),
(58,13,'2026-03-08 14:30:00','Completed','Stress counseling'),
(59,14,'2026-03-09 10:00:00','Completed','Retina check'),
(60,15,'2026-03-10 08:00:00','Completed','Hernia follow-up'),
(61,1,'2026-03-11 09:00:00','Completed','Angina review'),
(62,2,'2026-03-12 10:30:00','Completed','Menopause consult'),
(63,3,'2026-03-13 11:00:00','Completed','ACL injury'),
(64,4,'2026-03-14 14:00:00','Completed','Nerve pain'),
(65,5,'2026-03-15 09:30:00','Completed','Hepatitis review'),
(66,6,'2026-03-16 15:00:00','Completed','Rosacea treatment'),
(67,7,'2026-03-17 08:30:00','Completed','Immunization'),
(68,8,'2026-03-18 16:00:00','Completed','Nasal polyps'),
(69,9,'2026-03-19 10:00:00','Completed','Kidney function'),
(70,10,'2026-03-20 13:00:00','Completed','Radiation follow-up'),
(71,11,'2026-03-21 09:00:00','Completed','Sleep apnea'),
(72,12,'2026-03-22 11:30:00','Completed','Gestational diabetes'),
(73,13,'2026-03-23 14:30:00','Completed','OCD therapy'),
(74,14,'2026-03-24 10:00:00','Completed','Dry eye syndrome'),
(75,15,'2026-03-25 08:00:00','Completed','Gallbladder review'),
(76,1,'2026-04-01 09:00:00','Completed','Heart failure mgmt'),
(77,2,'2026-04-02 10:30:00','Completed','PCOS review'),
(78,3,'2026-04-03 11:00:00','Completed','Arthritis'),
(79,4,'2026-04-04 14:00:00','Completed','MS follow-up'),
(80,5,'2026-04-05 09:30:00','Completed','Crohns disease'),
(81,6,'2026-04-06 15:00:00','Completed','Vitiligo'),
(82,7,'2026-04-07 08:30:00','Completed','ADHD evaluation'),
(83,8,'2026-04-08 16:00:00','Completed','Vertigo'),
(84,9,'2026-04-09 10:00:00','Completed','Incontinence'),
(85,10,'2026-04-10 13:00:00','Completed','Lymphoma staging'),
(86,11,'2026-04-11 09:00:00','Completed','Pneumonia follow-up'),
(87,12,'2026-04-12 11:30:00','Completed','Thyroid nodule'),
(88,13,'2026-04-13 14:30:00','Completed','PTSD counseling'),
(89,14,'2026-04-14 10:00:00','Completed','Macular degeneration'),
(90,15,'2026-04-15 08:00:00','Completed','Laparoscopy'),
(91,1,'2026-05-01 09:00:00','Scheduled','Pacemaker check'),
(92,2,'2026-05-02 10:30:00','Scheduled','Routine OB'),
(93,3,'2026-05-03 11:00:00','Scheduled','Joint replacement consult'),
(94,4,'2026-05-04 14:00:00','Scheduled','Dementia screening'),
(95,5,'2026-05-05 09:30:00','Scheduled','Endoscopy follow-up'),
(96,6,'2026-05-06 15:00:00','Scheduled','Acne'),
(97,7,'2026-05-07 08:30:00','Cancelled','Fever'),
(98,8,'2026-05-08 16:00:00','Scheduled','Tinnitus'),
(99,9,'2026-05-09 10:00:00','Scheduled','Renal calculi'),
(100,10,'2026-05-10 13:00:00','Scheduled','CT scan review'),
(101,11,'2026-05-11 09:00:00','No-Show','COPD checkup'),
(102,12,'2026-05-12 11:30:00','Scheduled','Diabetes review'),
(103,13,'2026-05-13 14:30:00','Scheduled','Phobia treatment'),
(104,14,'2026-05-14 10:00:00','No-Show','Cornea check'),
(105,15,'2026-05-15 08:00:00','Scheduled','Bypass follow-up'),
(106,1,'2026-06-01 09:00:00','Scheduled','Echo result'),
(107,2,'2026-06-02 10:30:00','Scheduled','IVF consult'),
(108,3,'2026-06-03 11:00:00','Scheduled','Physiotherapy review'),
(109,4,'2026-06-04 14:00:00','Scheduled','Migraine'),
(110,5,'2026-06-05 09:30:00','Scheduled','Gastritis'),
(111,6,'2026-06-06 15:00:00','Scheduled','Fungal infection'),
(112,7,'2026-06-07 08:30:00','Scheduled','Child nutrition'),
(113,8,'2026-06-08 16:00:00','Scheduled','Deviated septum'),
(114,9,'2026-06-09 10:00:00','Scheduled','Kidney biopsy'),
(115,10,'2026-06-10 13:00:00','Scheduled','Chemo session'),
(116,11,'2026-06-11 09:00:00','Scheduled','Spirometry'),
(117,12,'2026-06-12 11:30:00','Scheduled','HbA1c test'),
(118,13,'2026-06-13 14:30:00','Scheduled','Memory issues'),
(119,14,'2026-06-14 10:00:00','Scheduled','Lasik consult'),
(120,15,'2026-06-15 08:00:00','Scheduled','Tumor removal');

INSERT INTO TIMETABLE (DoctorID,DayOfWeek,StartTime,EndTime,IsAvailable) VALUES
(1,'Monday','08:00','12:00',TRUE),(1,'Tuesday','08:00','12:00',TRUE),
(1,'Wednesday','08:00','12:00',TRUE),(1,'Thursday','08:00','12:00',TRUE),
(1,'Friday','08:00','11:00',TRUE),(1,'Saturday','09:00','12:00',TRUE),
(1,'Sunday','09:00','11:00',FALSE),
(2,'Monday','10:00','14:00',TRUE),(2,'Tuesday','10:00','14:00',TRUE),
(2,'Wednesday','10:00','14:00',TRUE),(2,'Thursday','10:00','14:00',TRUE),
(2,'Friday','10:00','13:00',TRUE),(2,'Saturday','10:00','12:00',TRUE),
(2,'Sunday','10:00','12:00',FALSE),
(3,'Monday','09:00','13:00',TRUE),(3,'Tuesday','09:00','13:00',TRUE),
(3,'Wednesday','09:00','13:00',TRUE),(3,'Thursday','09:00','13:00',TRUE),
(3,'Friday','09:00','12:00',TRUE),(3,'Saturday','09:00','11:00',TRUE),
(3,'Sunday','09:00','11:00',FALSE),
(4,'Monday','14:00','18:00',TRUE),(4,'Tuesday','14:00','18:00',TRUE),
(4,'Wednesday','14:00','18:00',TRUE),(4,'Thursday','14:00','18:00',TRUE),
(4,'Friday','14:00','17:00',TRUE),(4,'Saturday','14:00','17:00',FALSE),
(4,'Sunday','14:00','16:00',FALSE),
(5,'Monday','08:00','12:00',TRUE),(5,'Tuesday','08:00','12:00',TRUE),
(5,'Wednesday','08:00','12:00',TRUE),(5,'Thursday','08:00','12:00',TRUE),
(5,'Friday','08:00','11:00',TRUE),(5,'Saturday','09:00','12:00',TRUE),
(5,'Sunday','09:00','11:00',FALSE),
(6,'Monday','15:00','19:00',TRUE),(6,'Tuesday','15:00','19:00',TRUE),
(6,'Wednesday','15:00','19:00',TRUE),(6,'Thursday','15:00','19:00',TRUE),
(6,'Friday','15:00','18:00',TRUE),(6,'Saturday','15:00','18:00',TRUE),
(6,'Sunday','15:00','17:00',FALSE),
(7,'Monday','08:00','12:00',TRUE),(7,'Tuesday','08:00','12:00',TRUE),
(7,'Wednesday','08:00','12:00',TRUE),(7,'Thursday','08:00','12:00',TRUE),
(7,'Friday','08:00','11:00',TRUE),(7,'Saturday','09:00','11:00',TRUE),
(7,'Sunday','09:00','11:00',FALSE),
(8,'Monday','16:00','20:00',TRUE),(8,'Tuesday','16:00','20:00',TRUE),
(8,'Wednesday','16:00','20:00',TRUE),(8,'Thursday','16:00','20:00',TRUE),
(8,'Friday','16:00','19:00',TRUE),(8,'Saturday','16:00','18:00',TRUE),
(8,'Sunday','16:00','18:00',FALSE),
(9,'Monday','10:00','14:00',TRUE),(9,'Tuesday','10:00','14:00',TRUE),
(9,'Wednesday','10:00','14:00',TRUE),(9,'Thursday','10:00','14:00',TRUE),
(9,'Friday','10:00','13:00',TRUE),(9,'Saturday','10:00','12:00',TRUE),
(9,'Sunday','10:00','12:00',FALSE),
(10,'Monday','13:00','17:00',TRUE),(10,'Tuesday','13:00','17:00',TRUE),
(10,'Wednesday','13:00','17:00',TRUE),(10,'Thursday','13:00','17:00',TRUE),
(10,'Friday','13:00','16:00',TRUE),(10,'Saturday','13:00','16:00',FALSE),
(10,'Sunday','13:00','15:00',FALSE),
(11,'Monday','09:00','13:00',TRUE),(11,'Tuesday','09:00','13:00',TRUE),
(11,'Wednesday','09:00','13:00',TRUE),(11,'Thursday','09:00','13:00',TRUE),
(11,'Friday','09:00','12:00',TRUE),(11,'Saturday','09:00','11:00',TRUE),
(11,'Sunday','09:00','11:00',FALSE),
(12,'Monday','11:00','15:00',TRUE),(12,'Tuesday','11:00','15:00',TRUE),
(12,'Wednesday','11:00','15:00',TRUE),(12,'Thursday','11:00','15:00',TRUE),
(12,'Friday','11:00','14:00',TRUE),(12,'Saturday','11:00','13:00',TRUE),
(12,'Sunday','11:00','13:00',FALSE),
(13,'Monday','14:00','18:00',TRUE),(13,'Tuesday','14:00','18:00',TRUE),
(13,'Wednesday','14:00','18:00',TRUE),(13,'Thursday','14:00','18:00',TRUE),
(13,'Friday','14:00','17:00',TRUE),(13,'Saturday','14:00','16:00',TRUE),
(13,'Sunday','14:00','16:00',FALSE),
(14,'Monday','10:00','14:00',TRUE),(14,'Tuesday','10:00','14:00',TRUE),
(14,'Wednesday','10:00','14:00',TRUE),(14,'Thursday','10:00','14:00',TRUE),
(14,'Friday','10:00','13:00',TRUE),(14,'Saturday','10:00','12:00',TRUE),
(14,'Sunday','10:00','12:00',FALSE),
(15,'Monday','08:00','12:00',TRUE),(15,'Tuesday','08:00','12:00',TRUE),
(15,'Wednesday','08:00','12:00',TRUE),(15,'Thursday','08:00','12:00',TRUE),
(15,'Friday','08:00','11:00',TRUE),(15,'Saturday','08:00','11:00',TRUE),
(15,'Sunday','08:00','10:00',FALSE);

INSERT INTO MEDICAL_RECORD (PatientID,DoctorID,AppointmentID,VisitDate,Diagnosis,Prescription,TestResults,TreatmentDetails) VALUES
(1,1,1,'2026-01-05','Hypertension Stage 1','Amlodipine 5mg OD; Aspirin 75mg OD','BP 150/95','Lifestyle modification; low sodium diet'),
(2,2,2,'2026-01-06','Normal Pregnancy 28 wks','FeSO4 200mg BD; Folic Acid 5mg OD','USG normal','Iron supplementation; prenatal vitamins'),
(3,3,3,'2026-01-07','Osteoarthritis Knee','Diclofenac 50mg BD; Omeprazole 20mg OD','X-ray mild degeneration','Physiotherapy; weight reduction'),
(4,4,4,'2026-01-08','Migraine with Aura','Sumatriptan 50mg PRN; Propranolol 40mg OD','MRI normal','Avoid triggers; stress management'),
(5,5,5,'2026-01-09','GERD','Omeprazole 40mg OD; Domperidone 10mg TDS','Endoscopy: esophagitis','Dietary changes; elevate bed head'),
(6,6,6,'2026-01-10','Contact Dermatitis','Hydrocortisone cream 1%; Cetirizine 10mg OD','Patch test positive for nickel','Avoid allergen; moisturizer'),
(7,7,7,'2026-01-11','Viral URTI','Paracetamol 250mg TDS; Vitamin C 500mg OD','CBC normal','Rest; fluids; monitor temperature'),
(8,8,8,'2026-01-12','Acute Otitis Media','Amoxicillin 500mg TDS; Paracetamol 500mg TDS','Ear swab culture pending','Analgesics; warm compress'),
(9,9,9,'2026-01-13','Renal Calculi 6mm','Tamsulosin 0.4mg OD; Diclofenac 75mg IM stat','USG: 6mm stone right kidney','High fluid intake; pain management'),
(10,10,10,'2026-01-14','Breast Cancer Stage II','Capecitabine 1250mg/m2 BD; Ondansetron 8mg BD','Biopsy: IDC Grade 2','Chemotherapy cycle 3; radiation planned'),
(11,11,11,'2026-01-15','Bronchial Asthma','Salbutamol inhaler PRN; Budesonide inhaler BD','PFT: FEV1 68%','Inhaler technique; avoid triggers'),
(12,12,12,'2026-01-16','Type 2 Diabetes','Metformin 1000mg BD; Glimepiride 2mg OD','HbA1c 8.2%','Diet control; exercise; SMBG'),
(13,13,13,'2026-01-17','Major Depressive Disorder','Sertraline 50mg OD; Clonazepam 0.5mg HS','PHQ-9 score 18','CBT sessions weekly'),
(14,14,14,'2026-01-18','Presbyopia','Reading glasses +2.0; Lubricating eye drops','Visual acuity 6/9','Spectacle correction'),
(15,15,15,'2026-01-19','Inguinal Hernia','Paracetamol 1g TDS post-op','Ultrasound confirmed hernia','Surgical repair planned'),
(16,1,16,'2026-01-20','Essential Hypertension','Atenolol 50mg OD; Hydrochlorothiazide 25mg OD','BP 145/90','Monthly BP monitoring'),
(17,2,17,'2026-01-21','Pregnancy 32 wks GDM','Insulin Aspart 6 units before meals','Glucose: Fasting 110','Diet; insulin therapy; monitoring'),
(18,3,18,'2026-01-22','Colles Fracture','Calcium 1000mg OD; Vitamin D 1000IU OD','X-ray: distal radius fracture','Cast immobilization 6 weeks'),
(19,4,19,'2026-01-23','Epilepsy','Sodium Valproate 500mg BD; Levetiracetam 500mg BD','EEG: abnormal focal discharge','Anti-epileptic therapy; driving restriction'),
(20,5,20,'2026-01-24','Irritable Bowel Syndrome','Mebeverine 135mg TDS; Ispaghula husk sachets BD','Colonoscopy: normal','High fiber diet; stress management'),
(21,6,21,'2026-01-25','Acne Vulgaris','Doxycycline 100mg OD; Benzoyl Peroxide gel topical','Clinical diagnosis','Topical retinoid; sunscreen'),
(22,7,22,'2026-01-26','Normal Child - Vaccination','MMR vaccine given','Growth chart normal','Next vaccine at 18 months'),
(23,8,23,'2026-01-27','Chronic Sinusitis','Amoxicillin-Clavulanate 625mg BD; Xylometazoline nasal spray','CT: mucosal thickening','Saline nasal irrigation; decongestant'),
(24,9,24,'2026-01-28','Benign Prostatic Hyperplasia','Tamsulosin 0.4mg OD; Finasteride 5mg OD','PSA 2.8; TRUS normal','Annual PSA monitoring'),
(25,10,25,'2026-01-29','Colorectal Cancer Stage III','FOLFOX regimen; Ondansetron 8mg BD','CT: lymph node involvement','Chemotherapy cycle 5'),
(26,11,26,'2026-01-30','COPD Moderate','Tiotropium inhaler OD; Salmeterol inhaler BD','PFT: FEV1/FVC 0.62','Pulmonary rehabilitation; smoking cessation'),
(27,12,27,'2026-02-01','Hypothyroidism','Levothyroxine 50mcg OD; Calcium supplement OD','TSH 8.5 mIU/L','Monthly TSH monitoring'),
(28,13,28,'2026-02-02','Generalized Anxiety Disorder','Escitalopram 10mg OD; Alprazolam 0.25mg PRN','GAD-7 score 14','CBT; relaxation techniques'),
(29,14,29,'2026-02-03','Primary Open Angle Glaucoma','Latanoprost 0.005% eye drops nocte; Timolol 0.5% BD','IOP 24mmHg; visual fields constricted','Regular IOP monitoring'),
(30,15,30,'2026-02-04','Post-appendectomy','Amoxicillin 500mg TDS; Paracetamol 1g TDS','WBC normalizing','Wound care; activity restriction'),
(31,1,31,'2026-02-05','Atrial Fibrillation','Warfarin 5mg OD; Digoxin 0.125mg OD','ECG: AF; INR 1.8','INR monitoring weekly; rate control'),
(32,2,32,'2026-02-06','PCOS','Metformin 500mg BD; Combined OCP','USG: multiple follicles; LH/FSH 3:1','Weight management; hormonal therapy'),
(33,3,33,'2026-02-07','Lumbar Disc Prolapse','Ibuprofen 400mg TDS; Diazepam 5mg HS','MRI: L4-L5 disc herniation','Physiotherapy; bed rest'),
(34,4,34,'2026-02-08','Juvenile Epilepsy','Sodium Valproate 400mg BD','EEG: generalized spike wave','School counseling; medication compliance'),
(35,5,35,'2026-02-09','Fatty Liver Disease','Ursodeoxycholic acid 300mg BD; Vitamin E 400IU OD','LFT mildly elevated; USG fatty liver','Weight loss; alcohol abstinence'),
(36,6,36,'2026-02-10','Atopic Dermatitis','Tacrolimus 0.1% ointment BD; Fexofenadine 120mg OD','IgE elevated','Emollient; avoid triggers'),
(37,7,37,'2026-02-11','Failure to Thrive','Multivitamin drops OD; Zinc sulfate drops OD','Weight below 3rd centile','Nutritional counseling; calorie-dense diet'),
(38,8,38,'2026-02-12','Sensorineural Hearing Loss','No specific drug; refer audiology','Audiogram: 40dB loss bilat','Hearing aid fitting'),
(39,9,39,'2026-02-13','Urinary Tract Infection','Nitrofurantoin 100mg BD x 5 days','Urine C&S: E. coli sensitive','Hydration; hygiene advice'),
(40,10,40,'2026-02-14','Hodgkins Lymphoma Stage II','ABVD regimen; Ondansetron 8mg BD','PET scan: mediastinal nodes','Cycle 2 chemotherapy'),
(41,11,41,'2026-02-15','Obstructive Sleep Apnea','CPAP therapy; Weight reduction','Sleep study: AHI 35','CPAP; positional therapy'),
(42,12,42,'2026-02-16','Type 1 Diabetes','Insulin Glargine 20 units HS; Insulin Lispro TDS','HbA1c 9.1%','Carb counting; SMBG 4x daily'),
(43,13,43,'2026-02-17','Bipolar Disorder','Lithium 400mg BD; Quetiapine 50mg HS','Mood chart: cycling','Mood stabilizer; psychotherapy'),
(44,14,44,'2026-02-18','Cataract Bilateral','No medication; surgery planned','BCVA 6/24 bilat','Phacoemulsification surgery'),
(45,15,45,'2026-02-19','Acute Appendicitis','Metronidazole 500mg TDS; Cefuroxime 750mg TDS IV','WBC 16000; USG: appendix 9mm','Laparoscopic appendectomy'),
(46,1,46,'2026-02-20','Hyperlipidemia','Atorvastatin 40mg OD; Fenofibrate 160mg OD','LDL 190 mg/dL; TG 280 mg/dL','Diet; exercise; statin therapy'),
(47,2,47,'2026-02-21','Ovarian Cyst 4cm','OCP for 3 months; monitor','USG: simple cyst left ovary','Repeat ultrasound in 3 months'),
(48,3,48,'2026-02-22','Ankylosing Spondylitis','Naproxen 500mg BD; Sulfasalazine 1g BD','MRI: sacroiliac joint inflammation','Physiotherapy; posture correction'),
(49,4,49,'2026-02-23','Parkinsons Disease Early','Levodopa 100mg TDS; Carbidopa 25mg TDS','DaTscan: reduced uptake','Neurological rehabilitation'),
(50,5,50,'2026-02-24','Ulcerative Colitis','Mesalazine 800mg TDS; Prednisolone 40mg OD','Colonoscopy: continuous mucosal inflammation','Maintenance mesalazine'),
(51,6,51,'2026-03-01','Plaque Psoriasis','Calcipotriol ointment BD; Betamethasone cream OD','PASI score 12','Topical treatment; phototherapy'),
(52,7,52,'2026-03-02','Autism Spectrum Disorder','Risperidone 0.5mg OD','CARS score 35','ABA therapy; speech therapy'),
(53,8,53,'2026-03-03','Recurrent Tonsillitis','Penicillin V 500mg QDS x 10 days; Paracetamol 500mg TDS','Throat swab: Strep A','Tonsillectomy considered'),
(54,9,54,'2026-03-04','Overactive Bladder','Oxybutynin 5mg BD; Pelvic floor exercises','Cystoscopy: trabeculation','Behavioral therapy; drug therapy'),
(55,10,55,'2026-03-05','Non-Hodgkins Lymphoma','R-CHOP regimen; Ondansetron 8mg BD','Biopsy: DLBCL','Cycle 4 immunochemotherapy'),
(56,11,56,'2026-03-06','Acute Bronchitis','Amoxicillin 500mg TDS; Salbutamol nebulization TDS','CXR: perihilar shadowing','Rest; antipyretics; bronchodilator'),
(57,12,57,'2026-03-07','Type 2 DM Poorly Controlled','Insulin Glargine 24 units HS added; Metformin continued','HbA1c 9.8%','Insulin initiation; diabetes education'),
(58,13,58,'2026-03-08','Post-traumatic Stress Disorder','Sertraline 100mg OD; Prazosin 1mg HS for nightmares','PCL-5 score 52','Trauma-focused CBT; EMDR'),
(59,14,59,'2026-03-09','Diabetic Retinopathy','Ranibizumab intravitreal injection; control DM','FFA: neovascularization','Laser photocoagulation; glycemic control'),
(60,15,60,'2026-03-10','Incisional Hernia','Paracetamol 1g TDS; wound care','USG: hernia confirmed','Elective hernia repair'),
(61,1,61,'2026-03-11','Stable Angina','Isosorbide mononitrate 20mg BD; Aspirin 75mg OD; Atenolol 25mg OD','Stress ECG: ST changes','Anti-anginal therapy; lifestyle'),
(62,2,62,'2026-03-12','Perimenopause','Estradiol patch 50mcg; Micronized progesterone 200mg HS','FSH elevated; LH elevated','HRT; calcium supplementation'),
(63,3,63,'2026-03-13','ACL Tear Complete','Naproxen 500mg BD; Calcium OD','MRI: complete ACL tear','ACL reconstruction surgery'),
(64,4,64,'2026-03-14','Trigeminal Neuralgia','Carbamazepine 200mg BD; Oxcarbazepine 300mg BD','MRI: vascular compression','Drug therapy; surgical option if resistant'),
(65,5,65,'2026-03-15','Hepatitis B Chronic','Tenofovir 300mg OD; Vitamin E supplement','HBV DNA 2M IU/mL; LFT mildly elevated','Antiviral therapy; 6-monthly monitoring'),
(66,6,66,'2026-03-16','Rosacea','Metronidazole gel 0.75% BD; Doxycycline 40mg OD','Clinical diagnosis','Sunscreen; avoid triggers; topical treatment'),
(67,7,67,'2026-03-17','Normal Child Immunization','DTP booster; MMR2 given','Growth normal','Next visit 12 months'),
(68,8,68,'2026-03-18','Nasal Polyps','Fluticasone nasal spray OD; Montelukast 10mg OD','CT: bilateral nasal polyps','Intranasal steroids; FESS if no response'),
(69,9,69,'2026-03-19','Chronic Kidney Disease Stage 3','Amlodipine 5mg OD; Erythropoietin 4000IU weekly','eGFR 42; Hb 9.8','Nephroprotective measures; diet'),
(70,10,70,'2026-03-20','Cervical Cancer Stage IB','Cisplatin 40mg/m2 weekly; Ondansetron 8mg IV','CT: cervix mass 3cm','Concurrent chemoradiation'),
(71,11,71,'2026-03-21','Obstructive Sleep Apnea','Auto-CPAP 8-12 cmH2O; Weight management','PSG: AHI 42','Positional therapy; CPAP compliance'),
(72,12,72,'2026-03-22','Gestational Diabetes','Metformin 500mg BD; dietary control','OGTT: 2h glucose 9.2','Dietary modification; weekly monitoring'),
(73,13,73,'2026-03-23','OCD','Fluvoxamine 100mg OD; ERP therapy','Y-BOCS score 28','ERP; medication; family education'),
(74,14,74,'2026-03-24','Dry Eye Syndrome','Hypromellose 0.3% drops QDS; Omega-3 supplements OD','Schirmers test 5mm','Warm compress; punctal plugs'),
(75,15,75,'2026-03-25','Gallstones Symptomatic','Ursodeoxycholic acid 500mg OD; Antispasmodic PRN','USG: multiple calculi CBD','Laparoscopic cholecystectomy'),
(76,1,76,'2026-04-01','Heart Failure NYHA III','Furosemide 40mg OD; Enalapril 5mg BD; Carvedilol 3.125mg BD','Echo: EF 35%','Salt restriction; fluid management'),
(77,2,77,'2026-04-02','PCOS with Infertility','Letrozole 2.5mg CD3-7; Metformin 500mg BD','AMH 8.2; AFC 16','Ovulation induction; weight loss'),
(78,3,78,'2026-04-03','Rheumatoid Arthritis','Methotrexate 15mg weekly; Folic acid 5mg weekly; Prednisolone 10mg OD','RF positive; Anti-CCP 120','DMARD therapy; joint protection'),
(79,4,79,'2026-04-04','Multiple Sclerosis','Interferon Beta-1a 30mcg IM weekly; Baclofen 10mg TDS','MRI: periventricular lesions','Disease modifying therapy; physiotherapy'),
(80,5,80,'2026-04-05','Crohns Disease Active','Prednisolone 40mg OD tapering; Azathioprine 2mg/kg OD','Colonoscopy: skip lesions; CRP 68','Steroid induction; immunomodulator'),
(81,6,81,'2026-04-06','Vitiligo','Tacrolimus 0.1% ointment BD; NBUVB phototherapy','Wood lamp: depigmented patches','Phototherapy 3x weekly; camouflage'),
(82,7,82,'2026-04-07','ADHD Combined Type','Methylphenidate 10mg OD; parent training','Conners scale: elevated','Medication; behavioral therapy'),
(83,8,83,'2026-04-08','Benign Paroxysmal Positional Vertigo','Betahistine 16mg TDS; Epley maneuver','Dix-Hallpike: positive right','Vestibular rehabilitation'),
(84,9,84,'2026-04-09','Stress Urinary Incontinence','Duloxetine 40mg BD; pelvic floor exercises','Urodynamics: SUI confirmed','Pelvic floor physiotherapy; surgery if no response'),
(85,10,85,'2026-04-10','Non-Hodgkins Lymphoma Stage IV','R-CHOP cycle 6; G-CSF support','CT: partial response','Consolidation therapy planned'),
(86,11,86,'2026-04-11','Community-acquired Pneumonia','Amoxicillin 1g TDS; Azithromycin 500mg OD','CXR: RLL consolidation; WBC 13000','Antibiotics 7 days; chest physio'),
(87,12,87,'2026-04-12','Thyroid Nodule','Levothyroxine 25mcg OD suppressive; repeat USG in 6 months','USG: hypoechoic nodule 1.8cm; FNAC benign','Watch and wait; 6-monthly USG'),
(88,13,88,'2026-04-13','Complex PTSD','Sertraline 150mg OD; Prazosin 2mg HS','PCL-5 score 48; improving','Schema therapy; trauma-focused CBT'),
(89,14,89,'2026-04-14','Age-related Macular Degeneration','Bevacizumab intravitreal; AREDS2 supplements','OCT: drusen; CNV','Anti-VEGF injections monthly'),
(90,15,90,'2026-04-15','Laparoscopic Ovarian Cystectomy','Paracetamol 1g TDS; Ibuprofen 400mg TDS','Post-op: vitals stable','Discharge in 24h; follow-up 2 weeks'),
(91,1,91,'2026-05-01','Hypertensive Heart Disease','Ramipril 5mg OD; Amlodipine 10mg OD; Aspirin 75mg OD','Echo: LVH; BP 160/100','Intensify antihypertensive; low sodium'),
(92,2,92,'2026-05-02','Normal Pregnancy 36 wks','FeSO4 200mg OD; Folic acid 5mg OD continued','USG: cephalic; normal AFI','Delivery plan discussion'),
(93,3,93,'2026-05-03','Severe Knee OA','Celecoxib 200mg OD; Glucosamine 1500mg OD','X-ray: severe joint space narrowing','Total knee replacement planned'),
(94,4,94,'2026-05-04','Alzheimers Disease Early','Donepezil 5mg OD; Memantine 10mg BD','MMSE 21; MRI: hippocampal atrophy','Cognitive stimulation; caregiver support'),
(95,5,95,'2026-05-05','Gastric Ulcer','Omeprazole 40mg BD; Amoxicillin 1g BD; Clarithromycin 500mg BD x 14 days','Endoscopy: 1.5cm gastric ulcer; H.pylori +ve','H.pylori eradication; PPI maintenance'),
(96,6,96,'2026-05-06','Sebaceous Cyst','No oral medication; surgical excision planned','Clinical diagnosis','Minor surgical excision'),
(98,8,98,'2026-05-08','Tinnitus Chronic','Betahistine 8mg TDS; Melatonin 3mg HS','Audiogram: normal; tinnitus bilateral','Sound therapy; tinnitus retraining'),
(99,9,99,'2026-05-09','Nephrolithiasis Recurrent','Tamsulosin 0.4mg OD; Citrate supplement OD','CT KUB: 5mm stone left ureter','High fluid; dietary oxalate restriction'),
(100,10,100,'2026-05-10','Breast Cancer Follow-up','Tamoxifen 20mg OD; Calcium+D3 supplement','CT: no recurrence; CA 15-3 normal','Annual mammogram; continue hormonal therapy');

INSERT INTO BILLING (PatientID,AppointmentID,ConsultFee,TestCharges,TreatCharges,PaymentStatus,BillDate) VALUES
(1,1,2500,500,0,'Paid','2026-01-05'),(2,2,2000,800,0,'Paid','2026-01-06'),
(3,3,2200,600,0,'Paid','2026-01-07'),(4,4,3000,1200,0,'Paid','2026-01-08'),
(5,5,1800,900,1500,'Paid','2026-01-09'),(6,6,1500,300,500,'Paid','2026-01-10'),
(7,7,1600,400,0,'Paid','2026-01-11'),(8,8,1700,500,800,'Paid','2026-01-12'),
(9,9,2100,800,0,'Paid','2026-01-13'),(10,10,3500,2000,5000,'Paid','2026-01-14'),
(11,11,1900,700,0,'Paid','2026-01-15'),(12,12,2300,1000,0,'Paid','2026-01-16'),
(13,13,2800,500,0,'Paid','2026-01-17'),(14,14,1400,800,0,'Paid','2026-01-18'),
(15,15,2600,0,8000,'Paid','2026-01-19'),(16,16,2500,500,0,'Paid','2026-01-20'),
(17,17,2000,1200,0,'Paid','2026-01-21'),(18,18,2200,700,4000,'Paid','2026-01-22'),
(19,19,3000,1500,0,'Paid','2026-01-23'),(20,20,1800,600,0,'Paid','2026-01-24'),
(21,21,1500,0,500,'Paid','2026-01-25'),(22,22,1600,1000,500,'Paid','2026-01-26'),
(23,23,1700,500,800,'Paid','2026-01-27'),(24,24,2100,1000,0,'Paid','2026-01-28'),
(25,25,3500,2500,8000,'Partial','2026-01-29'),(26,26,1900,700,0,'Paid','2026-01-30'),
(27,27,2300,900,0,'Paid','2026-02-01'),(28,28,2800,500,0,'Paid','2026-02-02'),
(29,29,1400,800,0,'Paid','2026-02-03'),(30,30,2600,0,0,'Paid','2026-02-04'),
(31,31,2500,1500,0,'Paid','2026-02-05'),(32,32,2000,1200,0,'Paid','2026-02-06'),
(33,33,2200,1500,0,'Paid','2026-02-07'),(34,34,3000,1200,0,'Paid','2026-02-08'),
(35,35,1800,1000,0,'Paid','2026-02-09'),(36,36,1500,300,500,'Paid','2026-02-10'),
(37,37,1600,800,0,'Paid','2026-02-11'),(38,38,1700,2000,0,'Paid','2026-02-12'),
(39,39,2100,500,800,'Paid','2026-02-13'),(40,40,3500,3000,8000,'Partial','2026-02-14'),
(41,41,1900,1500,3000,'Paid','2026-02-15'),(42,42,2300,1000,0,'Paid','2026-02-16'),
(43,43,2800,600,0,'Paid','2026-02-17'),(44,44,1400,800,0,'Pending','2026-02-18'),
(45,45,2600,0,12000,'Paid','2026-02-19'),(46,46,2500,1000,0,'Paid','2026-02-20'),
(47,47,2000,800,0,'Paid','2026-02-21'),(48,48,2200,1500,0,'Paid','2026-02-22'),
(49,49,3000,2000,0,'Paid','2026-02-23'),(50,50,1800,1200,0,'Paid','2026-02-24'),
(51,51,1500,0,1000,'Paid','2026-03-01'),(52,52,1600,800,0,'Paid','2026-03-02'),
(53,53,1700,500,800,'Paid','2026-03-03'),(54,54,2100,1500,0,'Paid','2026-03-04'),
(55,55,3500,2500,10000,'Partial','2026-03-05'),(56,56,1900,700,800,'Paid','2026-03-06'),
(57,57,2300,1000,0,'Paid','2026-03-07'),(58,58,2800,500,0,'Paid','2026-03-08'),
(59,59,1400,0,5000,'Pending','2026-03-09'),(60,60,2600,0,8000,'Paid','2026-03-10'),
(61,61,2500,700,0,'Paid','2026-03-11'),(62,62,2000,1000,0,'Paid','2026-03-12'),
(63,63,2200,1500,0,'Pending','2026-03-13'),(64,64,3000,1200,0,'Paid','2026-03-14'),
(65,65,1800,1500,0,'Paid','2026-03-15'),(66,66,1500,0,500,'Paid','2026-03-16'),
(67,67,1600,1000,500,'Paid','2026-03-17'),(68,68,1700,1200,0,'Paid','2026-03-18'),
(69,69,2100,1000,0,'Paid','2026-03-19'),(70,70,3500,2000,15000,'Partial','2026-03-20'),
(71,71,1900,1500,3000,'Paid','2026-03-21'),(72,72,2300,1000,0,'Paid','2026-03-22'),
(73,73,2800,600,0,'Paid','2026-03-23'),(74,74,1400,300,0,'Paid','2026-03-24'),
(75,75,2600,800,0,'Pending','2026-03-25'),(76,76,2500,1500,0,'Paid','2026-04-01'),
(77,77,2000,1200,0,'Paid','2026-04-02'),(78,78,2200,1500,0,'Paid','2026-04-03'),
(79,79,3000,2000,0,'Paid','2026-04-04'),(80,80,1800,1200,0,'Paid','2026-04-05'),
(81,81,1500,0,2000,'Paid','2026-04-06'),(82,82,1600,800,0,'Paid','2026-04-07'),
(83,83,1700,800,0,'Paid','2026-04-08'),(84,84,2100,1500,0,'Paid','2026-04-09'),
(85,85,3500,3000,12000,'Partial','2026-04-10'),(86,86,1900,700,800,'Paid','2026-04-11'),
(87,87,2300,1000,0,'Paid','2026-04-12'),(88,88,2800,500,0,'Paid','2026-04-13'),
(89,89,1400,0,8000,'Pending','2026-04-14'),(90,90,2600,0,10000,'Paid','2026-04-15'),
(91,91,2500,1000,0,'Pending','2026-05-01'),(92,92,2000,800,0,'Pending','2026-05-02'),
(93,93,2200,600,0,'Pending','2026-05-03'),(94,94,3000,1500,0,'Pending','2026-05-04'),
(95,95,1800,900,1500,'Pending','2026-05-05'),(96,96,1500,0,2000,'Pending','2026-05-06'),
(98,98,1700,800,0,'Pending','2026-05-08'),(99,99,2100,800,0,'Pending','2026-05-09'),
(100,100,3500,2000,0,'Pending','2026-05-10'),(101,101,1900,0,0,'Waived','2026-05-11'),
(102,102,2300,1000,0,'Pending','2026-05-12'),(103,103,2800,500,0,'Pending','2026-05-13'),
(105,105,2600,0,0,'Pending','2026-05-15'),(106,106,2500,1000,0,'Pending','2026-06-01'),
(107,107,2000,1200,0,'Pending','2026-06-02'),(108,108,2200,600,0,'Pending','2026-06-03'),
(109,109,3000,1200,0,'Pending','2026-06-04'),(110,110,1800,900,0,'Pending','2026-06-05'),
(111,111,1500,300,500,'Pending','2026-06-06'),(112,112,1600,400,0,'Pending','2026-06-07');

INSERT INTO ROOM_ASSIGNMENT (PatientID,RoomID,AdmitDate,DischargeDate) VALUES
(10,3,'2026-01-14','2026-01-21'),(15,22,'2026-01-19','2026-01-22'),
(25,19,'2026-01-29','2026-02-07'),(40,4,'2026-02-14','2026-02-18'),
(45,22,'2026-02-19','2026-02-21'),(55,19,'2026-03-05',NULL),
(70,6,'2026-03-20',NULL),(76,3,'2026-04-01','2026-04-07'),
(85,20,'2026-04-10',NULL),(86,1,'2026-04-11','2026-04-16'),
(90,8,'2026-04-15','2026-04-16'),(1,2,'2026-01-05','2026-01-08'),
(3,7,'2026-01-07','2026-01-10'),(9,12,'2026-01-13','2026-01-15'),
(19,10,'2026-01-23','2026-01-26'),(31,25,'2026-02-05','2026-02-08'),
(41,21,'2026-02-15','2026-02-18'),(42,5,'2026-02-16','2026-02-19'),
(63,8,'2026-03-13','2026-03-16'),(78,15,'2026-04-03','2026-04-06'),
(79,11,'2026-04-04','2026-04-07'),(80,14,'2026-04-05','2026-04-08'),
(91,2,'2026-05-01',NULL),(93,8,'2026-05-03',NULL),
(99,12,'2026-05-09',NULL),(100,20,'2026-05-10',NULL),
(105,22,'2026-05-15',NULL),(107,5,'2026-06-02',NULL),
(114,12,'2026-05-09',NULL),(115,20,'2026-05-10',NULL);
-
INSERT INTO NURSE_ASSISTS (NurseID,AppointmentID) VALUES
(1,1),(2,2),(3,3),(4,4),(5,5),(6,6),(7,7),(8,8),(9,9),(10,10),
(1,11),(2,12),(3,13),(4,14),(5,15),(6,16),(7,17),(8,18),(9,19),(10,20),
(1,21),(2,22),(3,23),(4,24),(5,25),(6,26),(7,27),(8,28),(9,29),(10,30),
(1,31),(2,32),(3,33),(4,34),(5,35),(6,36),(7,37),(8,38),(9,39),(10,40),
(1,41),(2,42),(3,43),(4,44),(5,45),(6,46),(7,47),(8,48),(9,49),(10,50),
(11,51),(12,52),(1,53),(2,54),(3,55),(4,56),(5,57),(6,58),(7,59),(8,60),
(9,61),(10,62),(11,63),(12,64),(1,65),(2,66),(3,67),(4,68),(5,69),(6,70),
(7,71),(8,72),(9,73),(10,74),(11,75),(12,76),(1,77),(2,78),(3,79),(4,80),
(5,81),(6,82),(7,83),(8,84),(9,85),(10,86),(11,87),(12,88),(1,89),(2,90),
(3,91),(4,92),(5,93),(6,94),(7,95),(8,96),(9,98),(10,99),(11,100),(12,101);



ALTER TABLE PATIENT ADD COLUMN EmergencyContact VARCHAR(20) AFTER Phone;


ALTER TABLE PATIENT MODIFY COLUMN Address VARCHAR(300);


ALTER TABLE BILLING ADD COLUMN MedicineCharges DECIMAL(10,2) DEFAULT 0;

ALTER TABLE MEDICAL_RECORD ADD COLUMN FollowUpDate DATE NULL;


ALTER TABLE TIMETABLE RENAME COLUMN IsAvailable TO SlotActive;


ALTER TABLE BILLING ADD CONSTRAINT chk_medicine CHECK (MedicineCharges >= 0);


ALTER TABLE APPOINTMENT ADD INDEX idx_app_date (AppDate);

ALTER TABLE APPOINTMENT MODIFY Status VARCHAR(20) NOT NULL DEFAULT 'Scheduled';


SELECT PatientID, CONCAT(FirstName,' ',LastName) AS FullName, BloodGroup, DOB
FROM   PATIENT
WHERE  BloodGroup = 'A+';

SELECT PatientID, FirstName, LastName, Gender, BloodGroup
FROM   PATIENT
WHERE  Gender = 'M' AND BloodGroup IN ('B+','O+');


SELECT CONCAT(S.FirstName,' ',S.LastName) AS DoctorName,
       D.Specialization, D.ConsultationFee
FROM   DOCTOR D JOIN STAFF S ON D.StaffID = S.StaffID
WHERE  D.Specialization LIKE '%ology';

SELECT AppointmentID, PatientID, DoctorID, AppDate, Status
FROM   APPOINTMENT
WHERE  AppDate BETWEEN '2026-01-01' AND '2026-03-31';


SELECT AppointmentID, PatientID, AppDate, Status
FROM   APPOINTMENT
WHERE  Status IN ('Completed','Cancelled');

SELECT P.PatientID, CONCAT(P.FirstName,' ',P.LastName) AS Patient,
       R.RoomNumber, RA.AdmitDate
FROM   ROOM_ASSIGNMENT RA
JOIN   PATIENT P ON RA.PatientID = P.PatientID
JOIN   ROOM    R ON RA.RoomID    = R.RoomID
WHERE  RA.DischargeDate IS NULL;


SELECT CONCAT(S.FirstName,' ',S.LastName) AS Doctor,
       D.Specialization, D.ConsultationFee
FROM   DOCTOR D JOIN STAFF S ON D.StaffID = S.StaffID
ORDER  BY D.ConsultationFee DESC;

SELECT CONCAT(S.FirstName,' ',S.LastName) AS Doctor,
       D.Specialization, D.ConsultationFee
FROM   DOCTOR D JOIN STAFF S ON D.StaffID = S.StaffID
ORDER  BY D.ConsultationFee DESC
LIMIT  5;


SELECT DISTINCT Specialization FROM DOCTOR ORDER BY Specialization;

SELECT D.DoctorID,
       CONCAT(S.FirstName,' ',S.LastName) AS Doctor,
       D.Specialization,
       COUNT(A.AppointmentID)             AS TotalAppointments
FROM   DOCTOR      D
JOIN   STAFF       S ON D.StaffID  = S.StaffID
JOIN   APPOINTMENT A ON A.DoctorID = D.DoctorID
GROUP  BY D.DoctorID, S.FirstName, S.LastName, D.Specialization
ORDER  BY TotalAppointments DESC;

SELECT D.DoctorID,
       CONCAT(S.FirstName,' ',S.LastName) AS Doctor,
       COUNT(A.AppointmentID)             AS TotalAppointments
FROM   DOCTOR      D
JOIN   STAFF       S ON D.StaffID  = S.StaffID
JOIN   APPOINTMENT A ON A.DoctorID = D.DoctorID
GROUP  BY D.DoctorID, S.FirstName, S.LastName
HAVING COUNT(A.AppointmentID) > 5;

SELECT
    SUM(ConsultFee + TestCharges + TreatCharges + MedicineCharges) AS TotalBilled,
    AVG(ConsultFee)                                                  AS AvgConsultFee,
    MIN(ConsultFee)                                                  AS MinFee,
    MAX(ConsultFee)                                                  AS MaxFee,
    COUNT(BillID)                                                    AS TotalBills
FROM BILLING;

SELECT BillID, PatientID,
       (ConsultFee + TestCharges + TreatCharges + MedicineCharges) AS TotalBill,
       CASE
           WHEN (ConsultFee + TestCharges + TreatCharges) < 3000 THEN 'Low'
           WHEN (ConsultFee + TestCharges + TreatCharges) < 8000 THEN 'Medium'
           ELSE 'High'
       END AS BillCategory,
       PaymentStatus
FROM   BILLING
ORDER  BY TotalBill DESC;


SELECT PatientID, CONCAT(FirstName,' ',LastName) AS Patient
FROM   PATIENT
WHERE  PatientID NOT IN (
    SELECT PatientID FROM BILLING WHERE PaymentStatus = 'Paid'
);


SELECT CONCAT(S.FirstName,' ',S.LastName) AS Doctor, D.Specialization
FROM   DOCTOR D JOIN STAFF S ON D.StaffID = S.StaffID
WHERE  EXISTS (
    SELECT 1 FROM MEDICAL_RECORD MR
    WHERE  MR.DoctorID = D.DoctorID AND MR.Prescription IS NOT NULL
);

SELECT CONCAT(P.FirstName,' ',P.LastName) AS Patient,
       MR.VisitDate, MR.Diagnosis
FROM   MEDICAL_RECORD MR JOIN PATIENT P ON MR.PatientID = P.PatientID
WHERE  YEAR(MR.VisitDate) = YEAR(CURDATE());


SELECT UPPER(CONCAT(FirstName,' ',LastName)) AS DoctorName,
       SUBSTRING_INDEX(Email,'@',-1)          AS EmailDomain
FROM   STAFF
WHERE  Role = 'Doctor';


SELECT A.AppointmentID,
       CONCAT(P.FirstName,' ',P.LastName) AS Patient,
       CONCAT(S.FirstName,' ',S.LastName) AS Doctor,
       D.Specialization,
       A.AppDate, A.Status
FROM   APPOINTMENT A
INNER JOIN PATIENT P ON A.PatientID = P.PatientID
INNER JOIN DOCTOR  D ON A.DoctorID  = D.DoctorID
INNER JOIN STAFF   S ON D.StaffID   = S.StaffID;

SELECT CONCAT(P.FirstName,' ',P.LastName) AS Patient,
       B.BillID, B.BillDate,
       COALESCE(B.ConsultFee,0)            AS ConsultFee,
       B.PaymentStatus
FROM   PATIENT  P
LEFT JOIN BILLING B ON P.PatientID = B.PatientID
ORDER  BY P.PatientID;

SELECT B.BillID, B.BillDate, B.PaymentStatus,
       CONCAT(P.FirstName,' ',P.LastName) AS Patient
FROM   BILLING B
RIGHT JOIN PATIENT P ON B.PatientID = P.PatientID
WHERE  B.BillID IS NOT NULL
ORDER  BY B.BillID;

SELECT CONCAT(S.FirstName,' ',S.LastName) AS Doctor,
       D.Specialization,
       DE.DeptName
FROM   DOCTOR D
CROSS JOIN DEPARTMENT DE
JOIN   STAFF S ON D.StaffID = S.StaffID
LIMIT  30;


SELECT A.PatientID AS PatID1,
       CONCAT(A.FirstName,' ',A.LastName) AS Patient1,
       B.PatientID AS PatID2,
       CONCAT(B.FirstName,' ',B.LastName) AS Patient2,
       YEAR(A.DOB)                         AS BirthYear
FROM   PATIENT A
JOIN   PATIENT B ON YEAR(A.DOB) = YEAR(B.DOB) AND A.PatientID < B.PatientID
ORDER  BY BirthYear
LIMIT  20;

SELECT CONCAT(P.FirstName,' ',P.LastName) AS Patient, P.Phone
FROM   PATIENT     P
LEFT JOIN APPOINTMENT A ON P.PatientID = A.PatientID
WHERE  A.AppointmentID IS NULL;


SELECT CONCAT(P.FirstName,' ',P.LastName)  AS Patient,
       MR.VisitDate, MR.Diagnosis,
       CONCAT(S.FirstName,' ',S.LastName)  AS Doctor,
       D.Specialization,
       R.RoomNumber, R.Category,
       DE.DeptName
FROM   MEDICAL_RECORD  MR
JOIN   PATIENT         P  ON MR.PatientID  = P.PatientID
JOIN   DOCTOR          D  ON MR.DoctorID   = D.DoctorID
JOIN   STAFF           S  ON D.StaffID     = S.StaffID
LEFT JOIN ROOM_ASSIGNMENT RA ON P.PatientID = RA.PatientID AND RA.DischargeDate IS NULL
LEFT JOIN ROOM            R  ON RA.RoomID   = R.RoomID
LEFT JOIN DEPARTMENT      DE ON R.DeptID    = DE.DeptID
ORDER  BY MR.VisitDate DESC
LIMIT  30;


CREATE OR REPLACE VIEW vw_ActivePrescriptions AS
SELECT MR.RecordID,
       MR.VisitDate,
       CONCAT(P.FirstName,' ',P.LastName)  AS Patient,
       P.DOB, P.BloodGroup, P.Phone,
       CONCAT(S.FirstName,' ',S.LastName)  AS PrescribingDoctor,
       D.Specialization,
       MR.Diagnosis,
       MR.Prescription,
       MR.FollowUpDate
FROM   MEDICAL_RECORD MR
JOIN   PATIENT        P ON MR.PatientID = P.PatientID
JOIN   DOCTOR         D ON MR.DoctorID  = D.DoctorID
JOIN   STAFF          S ON D.StaffID    = S.StaffID
WHERE  MR.Prescription IS NOT NULL AND MR.Prescription <> '';


CREATE OR REPLACE VIEW vw_OutstandingBills AS
SELECT B.BillID,
       CONCAT(P.FirstName,' ',P.LastName)                              AS Patient,
       P.Phone,
       B.BillDate,
       (B.ConsultFee + B.TestCharges + B.TreatCharges + B.MedicineCharges) AS TotalAmount,
       B.PaymentStatus
FROM   BILLING  B
JOIN   PATIENT  P ON B.PatientID = P.PatientID
WHERE  B.PaymentStatus IN ('Pending','Partial');

CREATE OR REPLACE VIEW vw_DoctorScheduleToday AS
SELECT CONCAT(S.FirstName,' ',S.LastName)  AS Doctor,
       D.Specialization,
       D.ConsultationFee,
       T.DayOfWeek,
       T.StartTime, T.EndTime, T.SlotActive
FROM   TIMETABLE  T
JOIN   DOCTOR     D ON T.DoctorID = D.DoctorID
JOIN   STAFF      S ON D.StaffID  = S.StaffID
WHERE  T.DayOfWeek = DAYNAME(CURDATE()) AND T.SlotActive = TRUE;

CREATE OR REPLACE VIEW vw_CurrentInpatients AS
SELECT CONCAT(P.FirstName,' ',P.LastName) AS Patient,
       P.BloodGroup,
       R.RoomNumber, R.Category,
       DE.DeptName,
       RA.AdmitDate,
       DATEDIFF(CURDATE(), RA.AdmitDate)  AS DaysAdmitted
FROM   ROOM_ASSIGNMENT RA
JOIN   PATIENT         P  ON RA.PatientID = P.PatientID
JOIN   ROOM            R  ON RA.RoomID    = R.RoomID
JOIN   DEPARTMENT      DE ON R.DeptID     = DE.DeptID
WHERE  RA.DischargeDate IS NULL;


CREATE OR REPLACE VIEW vw_RevenueByDoctor AS
SELECT CONCAT(S.FirstName,' ',S.LastName)                               AS Doctor,
       D.Specialization,
       COUNT(B.BillID)                                                   AS BillCount,
       SUM(B.ConsultFee)                                                 AS TotalConsultRevenue,
       SUM(B.TestCharges + B.TreatCharges + B.MedicineCharges)           AS TotalOtherCharges,
       SUM(B.ConsultFee + B.TestCharges + B.TreatCharges + B.MedicineCharges) AS GrandTotal
FROM   BILLING     B
JOIN   APPOINTMENT A ON B.AppointmentID = A.AppointmentID
JOIN   DOCTOR      D ON A.DoctorID      = D.DoctorID
JOIN   STAFF       S ON D.StaffID       = S.StaffID
GROUP  BY D.DoctorID, S.FirstName, S.LastName, D.Specialization;

SELECT * FROM vw_ActivePrescriptions LIMIT 10;
SELECT * FROM vw_OutstandingBills ORDER BY TotalAmount DESC;
SELECT * FROM vw_DoctorScheduleToday;
SELECT * FROM vw_CurrentInpatients;
SELECT * FROM vw_RevenueByDoctor ORDER BY GrandTotal DESC;


CREATE INDEX idx_patient_name       ON PATIENT(LastName, FirstName);
CREATE INDEX idx_patient_blood      ON PATIENT(BloodGroup);
CREATE INDEX idx_appointment_status ON APPOINTMENT(Status);
CREATE INDEX idx_appointment_doctor ON APPOINTMENT(DoctorID, AppDate);
CREATE INDEX idx_billing_status     ON BILLING(PaymentStatus);
CREATE INDEX idx_billing_patient    ON BILLING(PatientID, BillDate);
CREATE INDEX idx_medrec_patient     ON MEDICAL_RECORD(PatientID, VisitDate);
CREATE INDEX idx_medrec_doctor      ON MEDICAL_RECORD(DoctorID);
CREATE INDEX idx_timetable_doctor   ON TIMETABLE(DoctorID, DayOfWeek);
CREATE FULLTEXT INDEX idx_prescription ON MEDICAL_RECORD(Prescription);
CREATE FULLTEXT INDEX idx_diagnosis    ON MEDICAL_RECORD(Diagnosis);

DELIMITER $$

CREATE PROCEDURE sp_GetPatientPrescriptions(IN p_PatientID INT)
BEGIN
    SELECT MR.RecordID, MR.VisitDate,
           CONCAT(S.FirstName,' ',S.LastName) AS Doctor,
           D.Specialization,
           MR.Diagnosis, MR.Prescription, MR.FollowUpDate
    FROM   MEDICAL_RECORD MR
    JOIN   DOCTOR         D ON MR.DoctorID = D.DoctorID
    JOIN   STAFF          S ON D.StaffID   = S.StaffID
    WHERE  MR.PatientID   = p_PatientID
      AND  MR.Prescription IS NOT NULL
    ORDER  BY MR.VisitDate DESC;
END$$


CREATE PROCEDURE sp_BookAppointment(
    IN  p_PatientID INT,
    IN  p_DoctorID  INT,
    IN  p_AppDate   DATETIME,
    IN  p_Notes     TEXT,
    OUT p_AppointmentID INT,
    OUT p_Message       VARCHAR(200)
)
BEGIN
    DECLARE v_DayName   VARCHAR(10);
    DECLARE v_SlotCount INT;

    SET v_DayName = DAYNAME(p_AppDate);

    SELECT COUNT(*) INTO v_SlotCount
    FROM   TIMETABLE
    WHERE  DoctorID   = p_DoctorID
      AND  DayOfWeek  = v_DayName
      AND  SlotActive = TRUE
      AND  TIME(p_AppDate) BETWEEN StartTime AND EndTime;

    IF v_SlotCount = 0 THEN
        SET p_AppointmentID = NULL;
        SET p_Message = 'Doctor not available in this slot.';
    ELSE
        INSERT INTO APPOINTMENT (PatientID, DoctorID, AppDate, Status, Notes)
        VALUES (p_PatientID, p_DoctorID, p_AppDate, 'Scheduled', p_Notes);
        SET p_AppointmentID = LAST_INSERT_ID();
        SET p_Message = CONCAT('Appointment booked. ID: ', p_AppointmentID);
    END IF;
END$$

CREATE PROCEDURE sp_GenerateBill(
    IN p_PatientID     INT,
    IN p_AppointmentID INT,
    IN p_ConsultFee    DECIMAL(10,2),
    IN p_TestCharges   DECIMAL(10,2),
    IN p_TreatCharges  DECIMAL(10,2),
    IN p_MedCharges    DECIMAL(10,2)
)
BEGIN
    INSERT INTO BILLING
        (PatientID, AppointmentID, ConsultFee, TestCharges, TreatCharges,
         MedicineCharges, PaymentStatus, BillDate)
    VALUES
        (p_PatientID, p_AppointmentID, p_ConsultFee, p_TestCharges,
         p_TreatCharges, p_MedCharges, 'Pending', CURDATE());

    SELECT LAST_INSERT_ID() AS NewBillID,
           (p_ConsultFee + p_TestCharges + p_TreatCharges + p_MedCharges) AS TotalAmount;
END$$


CREATE PROCEDURE sp_DischargePatient(IN p_PatientID INT)
BEGIN
    DECLARE v_RoomID INT;

    SELECT RoomID INTO v_RoomID
    FROM   ROOM_ASSIGNMENT
    WHERE  PatientID = p_PatientID AND DischargeDate IS NULL
    LIMIT  1;

    IF v_RoomID IS NOT NULL THEN
        UPDATE ROOM_ASSIGNMENT
        SET    DischargeDate = CURDATE()
        WHERE  PatientID = p_PatientID AND DischargeDate IS NULL;

        UPDATE ROOM SET IsAvailable = TRUE WHERE RoomID = v_RoomID;
        SELECT CONCAT('Patient ', p_PatientID, ' discharged. Room ', v_RoomID, ' freed.') AS Result;
    ELSE
        SELECT 'Patient is not currently admitted.' AS Result;
    END IF;
END$$

CREATE PROCEDURE sp_MonthlyRevenue(IN p_Year INT, IN p_Month INT)
BEGIN
    SELECT CONCAT(S.FirstName,' ',S.LastName)  AS Doctor,
           D.Specialization,
           COUNT(B.BillID)                      AS Bills,
           SUM(B.ConsultFee + B.TestCharges + B.TreatCharges + B.MedicineCharges) AS Revenue,
           SUM(CASE WHEN B.PaymentStatus='Paid' THEN B.ConsultFee+B.TestCharges+B.TreatCharges+B.MedicineCharges ELSE 0 END) AS Collected
    FROM   BILLING     B
    JOIN   APPOINTMENT A ON B.AppointmentID = A.AppointmentID
    JOIN   DOCTOR      D ON A.DoctorID      = D.DoctorID
    JOIN   STAFF       S ON D.StaffID       = S.StaffID
    WHERE  YEAR(B.BillDate)  = p_Year
      AND  MONTH(B.BillDate) = p_Month
    GROUP  BY D.DoctorID, S.FirstName, S.LastName, D.Specialization
    ORDER  BY Revenue DESC;
END$$

CREATE PROCEDURE sp_SearchByDrug(IN p_DrugName VARCHAR(100))
BEGIN
    SELECT MR.RecordID, MR.VisitDate,
           CONCAT(P.FirstName,' ',P.LastName) AS Patient,
           P.DOB, P.BloodGroup,
           CONCAT(S.FirstName,' ',S.LastName) AS Doctor,
           MR.Diagnosis, MR.Prescription
    FROM   MEDICAL_RECORD MR
    JOIN   PATIENT        P ON MR.PatientID = P.PatientID
    JOIN   DOCTOR         D ON MR.DoctorID  = D.DoctorID
    JOIN   STAFF          S ON D.StaffID    = S.StaffID
    WHERE  MR.Prescription LIKE CONCAT('%', p_DrugName, '%')
    ORDER  BY MR.VisitDate DESC;
END$$

DELIMITER ;


CALL sp_GetPatientPrescriptions(1);
CALL sp_SearchByDrug('Metformin');
CALL sp_MonthlyRevenue(2026, 1);

DELIMITER $$

CREATE TRIGGER trg_AutoBillOnComplete
AFTER UPDATE ON APPOINTMENT
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Completed' AND OLD.Status != 'Completed' THEN
        IF NOT EXISTS (SELECT 1 FROM BILLING WHERE AppointmentID = NEW.AppointmentID) THEN
            INSERT INTO BILLING (PatientID, AppointmentID, ConsultFee, PaymentStatus, BillDate)
            SELECT NEW.PatientID,
                   NEW.AppointmentID,
                   D.ConsultationFee,
                   'Pending',
                   DATE(NEW.AppDate)
            FROM   DOCTOR D WHERE D.DoctorID = NEW.DoctorID;
        END IF;
    END IF;
END$$


CREATE TRIGGER trg_RoomUnavailableOnAdmit
AFTER INSERT ON ROOM_ASSIGNMENT
FOR EACH ROW
BEGIN
    UPDATE ROOM SET IsAvailable = FALSE WHERE RoomID = NEW.RoomID;
END$$

CREATE TRIGGER trg_RoomAvailableOnDischarge
AFTER UPDATE ON ROOM_ASSIGNMENT
FOR EACH ROW
BEGIN
    IF NEW.DischargeDate IS NOT NULL AND OLD.DischargeDate IS NULL THEN
        UPDATE ROOM SET IsAvailable = TRUE WHERE RoomID = NEW.RoomID;
    END IF;
END$$


CREATE TRIGGER trg_CheckSlotBeforeInsert
BEFORE INSERT ON APPOINTMENT
FOR EACH ROW
BEGIN
    DECLARE v_SlotCount INT;
    SELECT COUNT(*) INTO v_SlotCount
    FROM   TIMETABLE
    WHERE  DoctorID   = NEW.DoctorID
      AND  DayOfWeek  = DAYNAME(NEW.AppDate)
      AND  SlotActive = TRUE;

    IF v_SlotCount = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot book: Doctor has no active slot on this day.';
    END IF;
END$$

CREATE TABLE IF NOT EXISTS PRESCRIPTION_AUDIT (
    AuditID      INT PRIMARY KEY AUTO_INCREMENT,
    RecordID     INT,
    ChangedAt    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    OldPrescription TEXT,
    NewPrescription TEXT
)$$

CREATE TRIGGER trg_PrescriptionAudit
AFTER UPDATE ON MEDICAL_RECORD
FOR EACH ROW
BEGIN
    IF (OLD.Prescription IS NULL AND NEW.Prescription IS NOT NULL)
    OR (OLD.Prescription <> NEW.Prescription) THEN
        INSERT INTO PRESCRIPTION_AUDIT (RecordID, OldPrescription, NewPrescription)
        VALUES (OLD.RecordID, OLD.Prescription, NEW.Prescription);
    END IF;
END$$

CREATE TRIGGER trg_NoBillNegative
BEFORE INSERT ON BILLING
FOR EACH ROW
BEGIN
    IF NEW.ConsultFee < 0 OR NEW.TestCharges < 0
    OR NEW.TreatCharges < 0 OR NEW.MedicineCharges < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Billing amounts cannot be negative.';
    END IF;
END$$

DELIMITER ;


SELECT * FROM vw_ActivePrescriptions
WHERE  MONTH(VisitDate) = MONTH(CURDATE())
  AND  YEAR(VisitDate)  = YEAR(CURDATE());


SELECT MR.Prescription, COUNT(*) AS Frequency
FROM   MEDICAL_RECORD MR
WHERE  MR.Prescription IS NOT NULL
GROUP  BY MR.Prescription
ORDER  BY Frequency DESC
LIMIT  10;


CALL sp_SearchByDrug('Metformin');


SELECT * FROM vw_OutstandingBills
WHERE  BillDate < CURDATE() - INTERVAL 30 DAY
ORDER  BY BillDate;


SELECT MONTH(BillDate) AS Month,
       YEAR(BillDate)  AS Year,
       SUM(CASE WHEN PaymentStatus='Paid' THEN ConsultFee+TestCharges+TreatCharges+MedicineCharges ELSE 0 END) AS Collected,
       SUM(CASE WHEN PaymentStatus='Pending' THEN ConsultFee+TestCharges+TreatCharges+MedicineCharges ELSE 0 END) AS Pending
FROM   BILLING
GROUP  BY YEAR(BillDate), MONTH(BillDate)
ORDER  BY Year, Month;
