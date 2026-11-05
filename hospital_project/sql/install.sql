
-- install.sql
-- Ygeiopolis Hospital Database - Full Schema with Constraints


SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE;
SET SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

CREATE SCHEMA IF NOT EXISTS `ygeiopolis_db`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `ygeiopolis_db`;


-- DROP TABLES (reverse dependency order)

DROP TABLE IF EXISTS `shift_assignment`;
DROP TABLE IF EXISTS `shift`;
DROP TABLE IF EXISTS `prescription`;
DROP TABLE IF EXISTS `patient_allergy`;
DROP TABLE IF EXISTS `drug_active_substance`;
DROP TABLE IF EXISTS `active_substance`;
DROP TABLE IF EXISTS `drug`;
DROP TABLE IF EXISTS `procedure_participation`;
DROP TABLE IF EXISTS `procedure_occurrence`;
DROP TABLE IF EXISTS `procedure_room`;
DROP TABLE IF EXISTS `medical_procedure`;
DROP TABLE IF EXISTS `lab_exam`;
DROP TABLE IF EXISTS `lab_exam_type`;
DROP TABLE IF EXISTS `rating`;
DROP TABLE IF EXISTS `hospitalization`;
DROP TABLE IF EXISTS `ken`;
DROP TABLE IF EXISTS `icd10_diagnosis`;
DROP TABLE IF EXISTS `triage_record`;
DROP TABLE IF EXISTS `patient_contact`;
DROP TABLE IF EXISTS `patient_allergy`;
DROP TABLE IF EXISTS `bed`;
DROP TABLE IF EXISTS `doctor_department`;
DROP TABLE IF EXISTS `admin_staff`;
DROP TABLE IF EXISTS `nurse`;
DROP TABLE IF EXISTS `department`;
DROP TABLE IF EXISTS `doctor`;
DROP TABLE IF EXISTS `patient`;
DROP TABLE IF EXISTS `staff`;


-- DROP TRIGGERS

DROP TRIGGER IF EXISTS `trg_doctor_insert_rank_supervisor`;
DROP TRIGGER IF EXISTS `trg_doctor_update_rank_supervisor`;
DROP TRIGGER IF EXISTS `trg_prescription_allergy_check`;
DROP TRIGGER IF EXISTS `trg_shift_assignment_max_monthly_doctor`;
DROP TRIGGER IF EXISTS `trg_shift_assignment_max_monthly_nurse`;
DROP TRIGGER IF EXISTS `trg_shift_assignment_max_monthly_admin`;
DROP TRIGGER IF EXISTS `trg_shift_assignment_rest_period`;
DROP TRIGGER IF EXISTS `trg_shift_assignment_consecutive_nights`;
DROP TRIGGER IF EXISTS `trg_procedure_room_overlap`;
DROP TRIGGER IF EXISTS `trg_procedure_surgeon_overlap`;
DROP TRIGGER IF EXISTS `trg_rating_only_discharged`;



-- TABLE: staff
-- Base table for all personnel (doctors, nurses, admin)

CREATE TABLE `staff` (
  `amka`       BIGINT       NOT NULL,
  `first_name` VARCHAR(100) NOT NULL,
  `last_name`  VARCHAR(100) NOT NULL,
  `age`        INT          NOT NULL,
  `email`      VARCHAR(100) NULL,
  `phone`      VARCHAR(20)  NULL,
  `hire_date`  DATE         NOT NULL,
  `staff_type` VARCHAR(20)  NOT NULL,

  PRIMARY KEY (`amka`),
  UNIQUE KEY `uq_staff_email` (`email`),

  -- Field integrity
  CONSTRAINT `chk_staff_age`
    CHECK (`age` >= 18 AND `age` <= 80),
  CONSTRAINT `chk_staff_type`
    CHECK (`staff_type` IN ('doctor', 'nurse', 'admin'))
) ENGINE=InnoDB;



-- TABLE: patient

CREATE TABLE `patient` (
  `amka`               BIGINT        NOT NULL,
  `first_name`         VARCHAR(45)   NOT NULL,
  `last_name`          VARCHAR(45)   NOT NULL,
  `father_name`        VARCHAR(45)   NOT NULL,
  `age`                INT           NOT NULL,
  `gender`             VARCHAR(20)   NOT NULL,
  `weight`             DECIMAL(5,2)  NULL,
  `height`             DECIMAL(5,2)  NULL,
  `address`            VARCHAR(255)  NULL,
  `phone`              VARCHAR(20)   NULL,
  `email`              VARCHAR(100)  NULL,
  `occupation`         VARCHAR(100)  NULL,
  `nationality`        VARCHAR(100)  NULL,
  `insurance_provider` VARCHAR(100)  NULL,

  PRIMARY KEY (`amka`),

  -- Field integrity
  CONSTRAINT `chk_patient_age`
    CHECK (`age` >= 0 AND `age` <= 150),
  CONSTRAINT `chk_patient_gender`
    CHECK (`gender` IN ('Άνδρας', 'Γυναίκα', 'Άλλο')),
  CONSTRAINT `chk_patient_weight`
    CHECK (`weight` IS NULL OR `weight` > 0),
  CONSTRAINT `chk_patient_height`
    CHECK (`height` IS NULL OR `height` > 0)
) ENGINE=InnoDB;



-- TABLE: doctor
-- Subtype of staff

CREATE TABLE `doctor` (
  `amka`             BIGINT       NOT NULL,
  `licence_number`   VARCHAR(50)  NOT NULL,
  `specialty`        VARCHAR(100) NOT NULL,
  `rank`             VARCHAR(30)  NOT NULL,
  `supervisor_amka`  BIGINT       NULL,

  PRIMARY KEY (`amka`),
  UNIQUE KEY `uq_doctor_licence` (`licence_number`),
  KEY `idx_doctor_supervisor_amka` (`supervisor_amka`),
  KEY `idx_doctor_specialty` (`specialty`),
  KEY `idx_doctor_rank` (`rank`),

  CONSTRAINT `fk_doctor_staff`
    FOREIGN KEY (`amka`)
    REFERENCES `staff` (`amka`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_doctor_supervisor`
    FOREIGN KEY (`supervisor_amka`)
    REFERENCES `doctor` (`amka`)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  -- Field integrity
  CONSTRAINT `chk_doctor_rank`
    CHECK (`rank` IN ('Ειδικευόμενος', 'Επιμελητής Β', 'Επιμελητής Α', 'Διευθυντής'))
) ENGINE=InnoDB;



-- TABLE: department

CREATE TABLE `department` (
  `department_id`  INT          NOT NULL AUTO_INCREMENT,
  `name`           VARCHAR(100) NOT NULL,
  `description`    TEXT         NULL,
  `floor_building` VARCHAR(100) NOT NULL,
  `director_amka`  BIGINT       NOT NULL,

  PRIMARY KEY (`department_id`),
  UNIQUE KEY `uq_department_name` (`name`),
  KEY `idx_department_director_amka` (`director_amka`),

  CONSTRAINT `fk_department_director`
    FOREIGN KEY (`director_amka`)
    REFERENCES `doctor` (`amka`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;



-- TABLE: nurse
-- Subtype of staff

CREATE TABLE `nurse` (
  `amka`          BIGINT      NOT NULL,
  `nurse_rank`    VARCHAR(30) NOT NULL,
  `department_id` INT         NOT NULL,

  PRIMARY KEY (`amka`),
  KEY `idx_nurse_department_id` (`department_id`),
  KEY `idx_nurse_rank` (`nurse_rank`),

  CONSTRAINT `fk_nurse_staff`
    FOREIGN KEY (`amka`)
    REFERENCES `staff` (`amka`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_nurse_department`
    FOREIGN KEY (`department_id`)
    REFERENCES `department` (`department_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  -- Field integrity
  CONSTRAINT `chk_nurse_rank`
    CHECK (`nurse_rank` IN ('Βοηθός Νοσηλευτή', 'Νοσηλευτής', 'Προϊστάμενος'))
) ENGINE=InnoDB;



-- TABLE: admin_staff
-- Subtype of staff

CREATE TABLE `admin_staff` (
  `amka`          BIGINT       NOT NULL,
  `role`          VARCHAR(100) NOT NULL,
  `office`        VARCHAR(100) NULL,
  `department_id` INT          NOT NULL,

  PRIMARY KEY (`amka`),
  KEY `idx_admin_department_id` (`department_id`),

  CONSTRAINT `fk_admin_staff_staff`
    FOREIGN KEY (`amka`)
    REFERENCES `staff` (`amka`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_admin_staff_department`
    FOREIGN KEY (`department_id`)
    REFERENCES `department` (`department_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;



-- TABLE: doctor_department
-- Many-to-many: doctor <-> department

CREATE TABLE `doctor_department` (
  `doctor_amka`   BIGINT NOT NULL,
  `department_id` INT    NOT NULL,

  PRIMARY KEY (`doctor_amka`, `department_id`),
  KEY `idx_doctor_department_dept` (`department_id`),

  CONSTRAINT `fk_dd_doctor`
    FOREIGN KEY (`doctor_amka`)
    REFERENCES `doctor` (`amka`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_dd_department`
    FOREIGN KEY (`department_id`)
    REFERENCES `department` (`department_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;



-- TABLE: bed

CREATE TABLE `bed` (
  `bed_id`        INT         NOT NULL AUTO_INCREMENT,
  `bed_number`    VARCHAR(20) NOT NULL,
  `bed_type`      VARCHAR(50) NOT NULL,
  `status`        VARCHAR(30) NOT NULL DEFAULT 'available',
  `department_id` INT         NOT NULL,

  PRIMARY KEY (`bed_id`),
  UNIQUE KEY `uq_bed_dept_number` (`department_id`, `bed_number`),

  CONSTRAINT `fk_bed_department`
    FOREIGN KEY (`department_id`)
    REFERENCES `department` (`department_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  -- Field integrity
  CONSTRAINT `chk_bed_status`
    CHECK (`status` IN ('available', 'occupied', 'maintenance')),
  CONSTRAINT `chk_bed_type`
    CHECK (`bed_type` IN ('ΜΕΘ', 'μονόκλινο', 'πολύκλινο', 'άλλο'))
) ENGINE=InnoDB;



-- TABLE: patient_contact
-- Emergency contacts per patient

CREATE TABLE `patient_contact` (
  `contact_id`   INT          NOT NULL AUTO_INCREMENT,
  `patient_amka` BIGINT       NOT NULL,
  `full_name`    VARCHAR(100) NOT NULL,
  `phone`        VARCHAR(20)  NOT NULL,
  `relationship` VARCHAR(50)  NULL,
  `notes`        TEXT         NULL,

  PRIMARY KEY (`contact_id`),
  KEY `idx_patient_contact_patient_amka` (`patient_amka`),

  CONSTRAINT `fk_patient_contact_patient`
    FOREIGN KEY (`patient_amka`)
    REFERENCES `patient` (`amka`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;



-- TABLE: triage_record

CREATE TABLE `triage_record` (
  `triage_id`             INT          NOT NULL AUTO_INCREMENT,
  `patient_amka`          BIGINT       NOT NULL,
  `nurse_amka`            BIGINT       NOT NULL,
  `arrival_time`          DATETIME     NOT NULL,
  `symptoms`              TEXT         NULL,
  `urgency_level`         INT          NOT NULL,
  `outcome`               VARCHAR(30)  NOT NULL,
  `decision_time`         DATETIME     NULL,
  `referred_department_id` INT         NULL,

  PRIMARY KEY (`triage_id`),
  KEY `idx_triage_patient_amka` (`patient_amka`),
  KEY `idx_triage_nurse_amka` (`nurse_amka`),
  KEY `idx_triage_urgency_arrival` (`urgency_level`, `arrival_time`),
  KEY `idx_triage_referred_dept` (`referred_department_id`),

  CONSTRAINT `fk_triage_patient`
    FOREIGN KEY (`patient_amka`)
    REFERENCES `patient` (`amka`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_triage_nurse`
    FOREIGN KEY (`nurse_amka`)
    REFERENCES `nurse` (`amka`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_triage_referred_dept`
    FOREIGN KEY (`referred_department_id`)
    REFERENCES `department` (`department_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  -- Field integrity
  CONSTRAINT `chk_triage_urgency`
    CHECK (`urgency_level` BETWEEN 1 AND 5),
  CONSTRAINT `chk_triage_outcome`
    CHECK (`outcome` IN ('discharged', 'hospitalized')),
  CONSTRAINT `chk_triage_decision_after_arrival`
    CHECK (`decision_time` IS NULL OR `decision_time` >= `arrival_time`)
) ENGINE=InnoDB;



-- TABLE: icd10_diagnosis
-- Reference table (loaded from Ministry of Health)

CREATE TABLE `icd10_diagnosis` (
  `icd10_code`  VARCHAR(20)  NOT NULL,
  `description` VARCHAR(255) NOT NULL,

  PRIMARY KEY (`icd10_code`)
) ENGINE=InnoDB;



-- TABLE: ken
-- Κλειστά Ενοποιημένα Νοσήλια - reference table

CREATE TABLE `ken` (
  `ken_code`           VARCHAR(20)   NOT NULL,
  `description`        VARCHAR(255)  NULL,
  `base_cost`          DECIMAL(10,2) NOT NULL,
  `mean_length_of_stay` INT          NOT NULL,

  PRIMARY KEY (`ken_code`),

  CONSTRAINT `chk_ken_base_cost`
    CHECK (`base_cost` >= 0),
  CONSTRAINT `chk_ken_mlos`
    CHECK (`mean_length_of_stay` > 0)
) ENGINE=InnoDB;



-- TABLE: hospitalization

CREATE TABLE `hospitalization` (
  `hospitalization_id`    INT           NOT NULL AUTO_INCREMENT,
  `patient_amka`          BIGINT        NOT NULL,
  `department_id`         INT           NOT NULL,
  `bed_id`                INT           NOT NULL,
  `ken_code`              VARCHAR(20)   NOT NULL,
  `admission_icd10_code`  VARCHAR(20)   NOT NULL,
  `discharge_icd10_code`  VARCHAR(20)   NULL,
  `admission_date`        DATETIME      NOT NULL,
  `discharge_date`        DATETIME      NULL,
  `total_cost`            DECIMAL(10,2) NULL,
  `primary_doctor_amka`   BIGINT        NOT NULL,

  PRIMARY KEY (`hospitalization_id`),
  KEY `idx_hosp_patient_amka`        (`patient_amka`),
  KEY `idx_hosp_department_id`       (`department_id`),
  KEY `idx_hosp_bed_id`              (`bed_id`),
  KEY `idx_hosp_ken_code`            (`ken_code`),
  KEY `idx_hosp_admission_icd10`     (`admission_icd10_code`),
  KEY `idx_hosp_discharge_icd10`     (`discharge_icd10_code`),
  KEY `idx_hosp_primary_doctor`      (`primary_doctor_amka`),
  KEY `idx_hosp_dept_admission_date` (`department_id`, `admission_date`),

  CONSTRAINT `fk_hosp_patient`
    FOREIGN KEY (`patient_amka`)
    REFERENCES `patient` (`amka`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_hosp_department`
    FOREIGN KEY (`department_id`)
    REFERENCES `department` (`department_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_hosp_bed`
    FOREIGN KEY (`bed_id`)
    REFERENCES `bed` (`bed_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_hosp_ken`
    FOREIGN KEY (`ken_code`)
    REFERENCES `ken` (`ken_code`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_hosp_admission_icd10`
    FOREIGN KEY (`admission_icd10_code`)
    REFERENCES `icd10_diagnosis` (`icd10_code`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_hosp_discharge_icd10`
    FOREIGN KEY (`discharge_icd10_code`)
    REFERENCES `icd10_diagnosis` (`icd10_code`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_hosp_primary_doctor`
    FOREIGN KEY (`primary_doctor_amka`)
    REFERENCES `doctor` (`amka`)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  -- Field integrity
  CONSTRAINT `chk_hosp_discharge_after_admission`
    CHECK (`discharge_date` IS NULL OR `discharge_date` > `admission_date`),
  CONSTRAINT `chk_hosp_total_cost`
    CHECK (`total_cost` IS NULL OR `total_cost` >= 0)
) ENGINE=InnoDB;



-- TABLE: rating
-- Likert-scale review per hospitalization (post-discharge)

CREATE TABLE `rating` (
  `rating_id`               INT NOT NULL AUTO_INCREMENT,
  `hospitalization_id`      INT NOT NULL,
  `medical_care_score`      INT NULL,
  `nursing_care_score`      INT NULL,
  `cleanliness_score`       INT NULL,
  `food_score`              INT NULL,
  `overall_experience_score` INT NULL,

  PRIMARY KEY (`rating_id`),
  UNIQUE KEY `uq_rating_hosp` (`hospitalization_id`),

  CONSTRAINT `fk_rating_hospitalization`
    FOREIGN KEY (`hospitalization_id`)
    REFERENCES `hospitalization` (`hospitalization_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,

  -- Likert scale 1-5
  CONSTRAINT `chk_rating_medical`
    CHECK (`medical_care_score` IS NULL OR `medical_care_score` BETWEEN 1 AND 5),
  CONSTRAINT `chk_rating_nursing`
    CHECK (`nursing_care_score` IS NULL OR `nursing_care_score` BETWEEN 1 AND 5),
  CONSTRAINT `chk_rating_cleanliness`
    CHECK (`cleanliness_score` IS NULL OR `cleanliness_score` BETWEEN 1 AND 5),
  CONSTRAINT `chk_rating_food`
    CHECK (`food_score` IS NULL OR `food_score` BETWEEN 1 AND 5),
  CONSTRAINT `chk_rating_overall`
    CHECK (`overall_experience_score` IS NULL OR `overall_experience_score` BETWEEN 1 AND 5)
) ENGINE=InnoDB;



-- TABLE: lab_exam_type
-- Reference table loaded from Ministry of Health
-- Categories Γ (απεικονιστική), Δ (βιοπαθολογία), Ε (κυτταρολογία)

CREATE TABLE `lab_exam_type` (
  `exam_code` VARCHAR(20)  NOT NULL,
  `exam_name` VARCHAR(500) NOT NULL,
  `exam_type` VARCHAR(100)  NOT NULL,

  PRIMARY KEY (`exam_code`),
  KEY `idx_lab_exam_type_type` (`exam_type`)

) ENGINE=InnoDB;



-- TABLE: lab_exam

CREATE TABLE `lab_exam` (
  `exam_id`            INT          NOT NULL AUTO_INCREMENT,
  `hospitalization_id` INT          NOT NULL,
  `doctor_amka`        BIGINT       NOT NULL,
  `exam_code`          VARCHAR(20)  NOT NULL,
  `exam_date`          DATETIME     NOT NULL,
  `result_text`        TEXT         NULL,
  `numeric_value`      DECIMAL(10,2) NULL,
  `unit`               VARCHAR(20)  NULL,
  `cost`               DECIMAL(10,2) NULL,

  PRIMARY KEY (`exam_id`),
  KEY `idx_lab_exam_hosp_id`     (`hospitalization_id`),
  KEY `idx_lab_exam_doctor_amka` (`doctor_amka`),
  KEY `idx_lab_exam_code`        (`exam_code`),

  CONSTRAINT `fk_lab_exam_hosp`
    FOREIGN KEY (`hospitalization_id`)
    REFERENCES `hospitalization` (`hospitalization_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_lab_exam_doctor`
    FOREIGN KEY (`doctor_amka`)
    REFERENCES `doctor` (`amka`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_lab_exam_type`
    FOREIGN KEY (`exam_code`)
    REFERENCES `lab_exam_type` (`exam_code`)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT `chk_lab_cost`
    CHECK (`cost` IS NULL OR `cost` >= 0)
) ENGINE=InnoDB;



-- TABLE: medical_procedure
-- Reference table (loaded from Ministry of Health)

CREATE TABLE `medical_procedure` (
  `procedure_code` VARCHAR(20)   NOT NULL,
  `name`           VARCHAR(500)  NOT NULL,
  `category`       VARCHAR(50)   NOT NULL,
  `duration`       INT           NULL,
  `cost`           DECIMAL(10,2) NULL,

  PRIMARY KEY (`procedure_code`),
  KEY `idx_medical_procedure_category` (`category`),

  CONSTRAINT `chk_procedure_category`
    CHECK (`category` IN ('χειρουργική', 'διαγνωστική', 'θεραπευτική')),
  CONSTRAINT `chk_procedure_duration`
    CHECK (`duration` IS NULL OR `duration` > 0),
  CONSTRAINT `chk_procedure_cost`
    CHECK (`cost` IS NULL OR `cost` >= 0)
) ENGINE=InnoDB;



-- TABLE: procedure_room

CREATE TABLE `procedure_room` (
  `room_id`   INT          NOT NULL AUTO_INCREMENT,
  `room_name` VARCHAR(100) NOT NULL,
  `room_type` VARCHAR(50)  NULL,

  PRIMARY KEY (`room_id`),
  UNIQUE KEY `uq_room_name` (`room_name`),

  CONSTRAINT `chk_room_type`
    CHECK (`room_type` IN ('χειρουργείο', 'αίθουσα επέμβασης'))
) ENGINE=InnoDB;



-- TABLE: procedure_occurrence
-- A specific execution of a medical_procedure during a hospitalization

CREATE TABLE `procedure_occurrence` (
  `occurrence_id`      INT          NOT NULL AUTO_INCREMENT,
  `hospitalization_id` INT          NOT NULL,
  `procedure_code`     VARCHAR(20)  NOT NULL,
  `room_id`            INT          NOT NULL,
  `main_surgeon_amka`  BIGINT       NOT NULL,
  `start_datetime`     DATETIME     NOT NULL,
  `end_datetime`       DATETIME     NULL,

  PRIMARY KEY (`occurrence_id`),
  KEY `idx_proc_occ_hosp_id`        (`hospitalization_id`),
  KEY `idx_proc_occ_procedure_code` (`procedure_code`),
  KEY `idx_proc_occ_room_id`        (`room_id`),
  KEY `idx_proc_occ_surgeon_amka`   (`main_surgeon_amka`),
  KEY `idx_proc_occ_start_datetime` (`start_datetime`),

  CONSTRAINT `fk_proc_occ_hosp`
    FOREIGN KEY (`hospitalization_id`)
    REFERENCES `hospitalization` (`hospitalization_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_proc_occ_procedure`
    FOREIGN KEY (`procedure_code`)
    REFERENCES `medical_procedure` (`procedure_code`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_proc_occ_room`
    FOREIGN KEY (`room_id`)
    REFERENCES `procedure_room` (`room_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_proc_occ_surgeon`
    FOREIGN KEY (`main_surgeon_amka`)
    REFERENCES `doctor` (`amka`)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT `chk_proc_occ_end_after_start`
    CHECK (`end_datetime` IS NULL OR `end_datetime` > `start_datetime`)
) ENGINE=InnoDB;



-- TABLE: procedure_participation
-- Assistants (doctors or nurses) in a procedure_occurrence

CREATE TABLE `procedure_participation` (
  `occurrence_id`    INT         NOT NULL,
  `staff_amka`       BIGINT      NOT NULL,
  `role_in_procedure` VARCHAR(50) NOT NULL,

  PRIMARY KEY (`occurrence_id`, `staff_amka`),
  KEY `idx_proc_part_staff_amka` (`staff_amka`),

  CONSTRAINT `fk_proc_part_occurrence`
    FOREIGN KEY (`occurrence_id`)
    REFERENCES `procedure_occurrence` (`occurrence_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_proc_part_staff`
    FOREIGN KEY (`staff_amka`)
    REFERENCES `staff` (`amka`)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT `chk_proc_part_role`
    CHECK (`role_in_procedure` IN ('assistant_doctor', 'assistant_nurse', 'anesthesiologist', 'other'))
) ENGINE=InnoDB;



-- TABLE: drug
-- Reference table (EMA Article 57 database)

CREATE TABLE `drug` (
  `drug_id`   VARCHAR(30)  NOT NULL,
  `drug_name` VARCHAR(100) NOT NULL,

  PRIMARY KEY (`drug_id`)
) ENGINE=InnoDB;



-- TABLE: active_substance
-- Reference table (EMA Article 57 database)

CREATE TABLE `active_substance` (
  `substance_id`   INT          NOT NULL AUTO_INCREMENT,
  `substance_name` VARCHAR(100) NOT NULL,

  PRIMARY KEY (`substance_id`),
  UNIQUE KEY `uq_substance_name` (`substance_name`)
) ENGINE=InnoDB;



-- TABLE: drug_active_substance
-- Many-to-many: drug <-> active_substance

CREATE TABLE `drug_active_substance` (
  `drug_id`      VARCHAR(30) NOT NULL,
  `substance_id` INT         NOT NULL,

  PRIMARY KEY (`drug_id`, `substance_id`),
  KEY `idx_das_substance_id` (`substance_id`),

  CONSTRAINT `fk_das_drug`
    FOREIGN KEY (`drug_id`)
    REFERENCES `drug` (`drug_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_das_substance`
    FOREIGN KEY (`substance_id`)
    REFERENCES `active_substance` (`substance_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;



-- TABLE: patient_allergy
-- Patient allergies to active substances

CREATE TABLE `patient_allergy` (
  `patient_amka` BIGINT NOT NULL,
  `substance_id` INT    NOT NULL,
  `notes`        TEXT   NULL,

  PRIMARY KEY (`patient_amka`, `substance_id`),
  KEY `idx_patient_allergy_substance_id` (`substance_id`),

  CONSTRAINT `fk_pa_patient`
    FOREIGN KEY (`patient_amka`)
    REFERENCES `patient` (`amka`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pa_substance`
    FOREIGN KEY (`substance_id`)
    REFERENCES `active_substance` (`substance_id`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;



-- TABLE: prescription

CREATE TABLE `prescription` (
  `prescription_id`    INT          NOT NULL AUTO_INCREMENT,
  `doctor_amka`        BIGINT       NOT NULL,
  `patient_amka`       BIGINT       NOT NULL,
  `hospitalization_id` INT          NOT NULL,
  `drug_id`            VARCHAR(30)  NOT NULL,
  `dosage`             VARCHAR(50)  NULL,
  `frequency`          VARCHAR(50)  NULL,
  `start_date`         DATE         NOT NULL,
  `end_date`           DATE         NULL,

  PRIMARY KEY (`prescription_id`),
  -- "Κάθε συνδυασμός (ιατρός, ασθενής, φάρμακο, ημερομηνία έναρξης) είναι μοναδικός"
  UNIQUE KEY `uq_prescription_combo` (`doctor_amka`, `patient_amka`, `drug_id`, `start_date`),
  KEY `idx_prescription_doctor_amka`   (`doctor_amka`),
  KEY `idx_prescription_patient_amka`  (`patient_amka`),
  KEY `idx_prescription_hosp_id`       (`hospitalization_id`),
  KEY `idx_prescription_drug_id`       (`drug_id`),

  CONSTRAINT `fk_pres_doctor`
    FOREIGN KEY (`doctor_amka`)
    REFERENCES `doctor` (`amka`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_pres_patient`
    FOREIGN KEY (`patient_amka`)
    REFERENCES `patient` (`amka`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_pres_hospitalization`
    FOREIGN KEY (`hospitalization_id`)
    REFERENCES `hospitalization` (`hospitalization_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_pres_drug`
    FOREIGN KEY (`drug_id`)
    REFERENCES `drug` (`drug_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT `chk_pres_end_after_start`
    CHECK (`end_date` IS NULL OR `end_date` >= `start_date`)
) ENGINE=InnoDB;



-- TABLE: shift
-- One row = one shift slot (dept + date + type)

CREATE TABLE `shift` (
  `shift_id`      INT         NOT NULL AUTO_INCREMENT,
  `department_id` INT         NOT NULL,
  `shift_date`    DATE        NOT NULL,
  `shift_type`    VARCHAR(20) NOT NULL,

  PRIMARY KEY (`shift_id`),
  -- A department cannot have two shifts of the same type on the same date
  UNIQUE KEY `uq_shift_dept_date_type` (`department_id`, `shift_date`, `shift_type`),
  KEY `idx_shift_date_dept` (`shift_date`, `department_id`),

  CONSTRAINT `fk_shift_department`
    FOREIGN KEY (`department_id`)
    REFERENCES `department` (`department_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT `chk_shift_type`
    CHECK (`shift_type` IN ('morning', 'afternoon', 'night'))
) ENGINE=InnoDB;



-- TABLE: shift_assignment
-- Maps staff members to shifts

CREATE TABLE `shift_assignment` (
  `shift_id`   INT    NOT NULL,
  `staff_amka` BIGINT NOT NULL,

  PRIMARY KEY (`shift_id`, `staff_amka`),
  KEY `idx_shift_assignment_staff_amka` (`staff_amka`),

  CONSTRAINT `fk_sa_shift`
    FOREIGN KEY (`shift_id`)
    REFERENCES `shift` (`shift_id`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_sa_staff`
    FOREIGN KEY (`staff_amka`)
    REFERENCES `staff` (`amka`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;



-- TRIGGERS
-- User-defined constraints (business rules)


DELIMITER $$

-- -------------------------------------------------------------
-- TR1 & TR2: Doctor rank / supervisor rules (INSERT)
--   - Ειδικευόμενος MUST have a supervisor
--   - Διευθυντής MUST NOT have a supervisor
-- -------------------------------------------------------------
CREATE TRIGGER `trg_doctor_insert_rank_supervisor`
BEFORE INSERT ON `doctor`
FOR EACH ROW
BEGIN
  IF NEW.rank = 'Ειδικευόμενος' AND NEW.supervisor_amka IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ειδικευόμενος ιατρός πρέπει να έχει επόπτη.';
  END IF;

  IF NEW.rank = 'Διευθυντής' AND NEW.supervisor_amka IS NOT NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Διευθυντής δεν μπορεί να έχει επόπτη.';
  END IF;
END$$

-- Same rules on UPDATE
CREATE TRIGGER `trg_doctor_update_rank_supervisor`
BEFORE UPDATE ON `doctor`
FOR EACH ROW
BEGIN
  IF NEW.rank = 'Ειδικευόμενος' AND NEW.supervisor_amka IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ειδικευόμενος ιατρός πρέπει να έχει επόπτη.';
  END IF;

  IF NEW.rank = 'Διευθυντής' AND NEW.supervisor_amka IS NOT NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Διευθυντής δεν μπορεί να έχει επόπτη.';
  END IF;
END$$


-- -------------------------------------------------------------
-- TR3: Allergy check before prescription
--   Reject if any active substance of the drug is in patient's allergies
-- -------------------------------------------------------------
CREATE TRIGGER `trg_prescription_allergy_check`
BEFORE INSERT ON `prescription`
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1
    FROM `drug_active_substance` das
    JOIN `patient_allergy` pa ON pa.substance_id = das.substance_id
    WHERE das.drug_id     = NEW.drug_id
      AND pa.patient_amka = NEW.patient_amka
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Απαγορεύεται: ο ασθενής έχει αλλεργία σε δραστική ουσία του φαρμάκου.';
  END IF;
END$$


-- -------------------------------------------------------------
-- TR4: Maximum shifts per month - DOCTORS (max 15)
-- -------------------------------------------------------------
CREATE TRIGGER `trg_shift_max_monthly_doctor`
BEFORE INSERT ON `shift_assignment`
FOR EACH ROW
BEGIN
  DECLARE v_count  INT;
  DECLARE v_month  INT;
  DECLARE v_year   INT;
  DECLARE v_type   VARCHAR(20);

  SELECT s.shift_type, MONTH(s.shift_date), YEAR(s.shift_date)
  INTO   v_type, v_month, v_year
  FROM   `shift` s
  WHERE  s.shift_id = NEW.shift_id;

  -- Only check if staff member is a doctor
  IF EXISTS (SELECT 1 FROM `doctor` WHERE `amka` = NEW.staff_amka) THEN
    SELECT COUNT(*) INTO v_count
    FROM `shift_assignment` sa
    JOIN `shift` s ON s.shift_id = sa.shift_id
    WHERE sa.staff_amka    = NEW.staff_amka
      AND MONTH(s.shift_date) = v_month
      AND YEAR(s.shift_date)  = v_year;

    IF v_count >= 15 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ιατρός: υπέρβαση μέγιστου ορίου 15 βαρδιών/μήνα.';
    END IF;
  END IF;
END$$


-- -------------------------------------------------------------
-- TR5: Maximum shifts per month - NURSES (max 20)
-- -------------------------------------------------------------
CREATE TRIGGER `trg_shift_max_monthly_nurse`
BEFORE INSERT ON `shift_assignment`
FOR EACH ROW
BEGIN
  DECLARE v_count INT;
  DECLARE v_month INT;
  DECLARE v_year  INT;

  SELECT MONTH(s.shift_date), YEAR(s.shift_date)
  INTO   v_month, v_year
  FROM   `shift` s
  WHERE  s.shift_id = NEW.shift_id;

  IF EXISTS (SELECT 1 FROM `nurse` WHERE `amka` = NEW.staff_amka) THEN
    SELECT COUNT(*) INTO v_count
    FROM `shift_assignment` sa
    JOIN `shift` s ON s.shift_id = sa.shift_id
    WHERE sa.staff_amka     = NEW.staff_amka
      AND MONTH(s.shift_date) = v_month
      AND YEAR(s.shift_date)  = v_year;

    IF v_count >= 20 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Νοσηλευτής: υπέρβαση μέγιστου ορίου 20 βαρδιών/μήνα.';
    END IF;
  END IF;
END$$


-- -------------------------------------------------------------
-- TR6: Maximum shifts per month - ADMIN (max 25)
-- -------------------------------------------------------------
CREATE TRIGGER `trg_shift_max_monthly_admin`
BEFORE INSERT ON `shift_assignment`
FOR EACH ROW
BEGIN
  DECLARE v_count INT;
  DECLARE v_month INT;
  DECLARE v_year  INT;

  SELECT MONTH(s.shift_date), YEAR(s.shift_date)
  INTO   v_month, v_year
  FROM   `shift` s
  WHERE  s.shift_id = NEW.shift_id;

  IF EXISTS (SELECT 1 FROM `admin_staff` WHERE `amka` = NEW.staff_amka) THEN
    SELECT COUNT(*) INTO v_count
    FROM `shift_assignment` sa
    JOIN `shift` s ON s.shift_id = sa.shift_id
    WHERE sa.staff_amka     = NEW.staff_amka
      AND MONTH(s.shift_date) = v_month
      AND YEAR(s.shift_date)  = v_year;

    IF v_count >= 25 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Διοικητικός: υπέρβαση μέγιστου ορίου 25 βαρδιών/μήνα.';
    END IF;
  END IF;
END$$


-- -------------------------------------------------------------
-- TR7: Minimum 8-hour rest between consecutive shifts for same staff
-- -------------------------------------------------------------
CREATE TRIGGER `trg_shift_rest_period`
BEFORE INSERT ON `shift_assignment`
FOR EACH ROW
BEGIN
  DECLARE v_new_start  DATETIME;
  DECLARE v_new_end    DATETIME;
  DECLARE v_conflict   INT DEFAULT 0;

  -- Compute start/end of the new shift
  SELECT
    CASE s.shift_type
      WHEN 'morning'   THEN TIMESTAMP(s.shift_date, '07:00:00')
      WHEN 'afternoon' THEN TIMESTAMP(s.shift_date, '15:00:00')
      WHEN 'night'     THEN TIMESTAMP(s.shift_date, '23:00:00')
    END,
    CASE s.shift_type
      WHEN 'morning'   THEN TIMESTAMP(s.shift_date, '15:00:00')
      WHEN 'afternoon' THEN TIMESTAMP(s.shift_date, '23:00:00')
      WHEN 'night'     THEN TIMESTAMP(DATE_ADD(s.shift_date, INTERVAL 1 DAY), '07:00:00')
    END
  INTO v_new_start, v_new_end
  FROM `shift` s
  WHERE s.shift_id = NEW.shift_id;

  -- Check existing shifts for this staff member within ±16 hours window
  SELECT COUNT(*) INTO v_conflict
  FROM `shift_assignment` sa
  JOIN `shift` s ON s.shift_id = sa.shift_id
  WHERE sa.staff_amka = NEW.staff_amka
    AND (
      -- existing shift ends within 8h before new shift starts
      CASE s.shift_type
        WHEN 'morning'   THEN TIMESTAMP(s.shift_date, '15:00:00')
        WHEN 'afternoon' THEN TIMESTAMP(s.shift_date, '23:00:00')
        WHEN 'night'     THEN TIMESTAMP(DATE_ADD(s.shift_date, INTERVAL 1 DAY), '07:00:00')
      END > DATE_SUB(v_new_start, INTERVAL 8 HOUR)
      AND
      CASE s.shift_type
        WHEN 'morning'   THEN TIMESTAMP(s.shift_date, '07:00:00')
        WHEN 'afternoon' THEN TIMESTAMP(s.shift_date, '15:00:00')
        WHEN 'night'     THEN TIMESTAMP(s.shift_date, '23:00:00')
      END < v_new_start
    OR
      -- new shift ends within 8h before existing starts
      v_new_end > DATE_SUB(
        CASE s.shift_type
          WHEN 'morning'   THEN TIMESTAMP(s.shift_date, '07:00:00')
          WHEN 'afternoon' THEN TIMESTAMP(s.shift_date, '15:00:00')
          WHEN 'night'     THEN TIMESTAMP(s.shift_date, '23:00:00')
        END, INTERVAL 8 HOUR)
      AND v_new_start <
        CASE s.shift_type
          WHEN 'morning'   THEN TIMESTAMP(s.shift_date, '07:00:00')
          WHEN 'afternoon' THEN TIMESTAMP(s.shift_date, '15:00:00')
          WHEN 'night'     THEN TIMESTAMP(s.shift_date, '23:00:00')
        END
    );

  IF v_conflict > 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Παραβίαση: δεν έχουν παρέλθει 8 ώρες ανάπαυσης από την προηγούμενη βάρδια.';
  END IF;
END$$


-- -------------------------------------------------------------
-- TR8: Max 3 consecutive night shifts for same staff member
-- -------------------------------------------------------------
CREATE TRIGGER `trg_shift_consecutive_nights`
BEFORE INSERT ON `shift_assignment`
FOR EACH ROW
BEGIN
  DECLARE v_shift_type VARCHAR(20);
  DECLARE v_shift_date DATE;
  DECLARE v_night_count INT DEFAULT 0;

  SELECT s.shift_type, s.shift_date
  INTO   v_shift_type, v_shift_date
  FROM   `shift` s
  WHERE  s.shift_id = NEW.shift_id;

  IF v_shift_type = 'night' THEN
    -- Count consecutive night shifts in the 3 days before this one
    SELECT COUNT(*) INTO v_night_count
    FROM `shift_assignment` sa
    JOIN `shift` s ON s.shift_id = sa.shift_id
    WHERE sa.staff_amka  = NEW.staff_amka
      AND s.shift_type   = 'night'
      AND s.shift_date   BETWEEN DATE_SUB(v_shift_date, INTERVAL 3 DAY)
                             AND DATE_SUB(v_shift_date, INTERVAL 1 DAY);

    IF v_night_count >= 3 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Παραβίαση: δεν επιτρέπονται περισσότερες από 3 συνεχόμενες νυχτερινές βάρδιες.';
    END IF;
  END IF;
END$$


-- -------------------------------------------------------------
-- TR9: No two procedures in the same room at the same time
-- -------------------------------------------------------------
CREATE TRIGGER `trg_procedure_room_overlap`
BEFORE INSERT ON `procedure_occurrence`
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1
    FROM `procedure_occurrence` po
    WHERE po.room_id       = NEW.room_id
      AND po.occurrence_id <> NEW.occurrence_id
      AND po.start_datetime < NEW.end_datetime
      AND po.end_datetime   > NEW.start_datetime
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Παραβίαση: ο χώρος χρησιμοποιείται ήδη σε αυτό το χρονικό διάστημα.';
  END IF;
END$$


-- -------------------------------------------------------------
-- TR10: Same surgeon cannot participate in two procedures simultaneously
-- -------------------------------------------------------------
CREATE TRIGGER `trg_procedure_surgeon_overlap`
BEFORE INSERT ON `procedure_occurrence`
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1
    FROM `procedure_occurrence` po
    WHERE po.main_surgeon_amka = NEW.main_surgeon_amka
      AND po.occurrence_id    <> NEW.occurrence_id
      AND po.start_datetime    < NEW.end_datetime
      AND po.end_datetime      > NEW.start_datetime
  ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Παραβίαση: ο χειρουργός συμμετέχει ήδη σε άλλη επέμβαση αυτή την ώρα.';
  END IF;
END$$


-- -------------------------------------------------------------
-- TR11: Rating only allowed after discharge
-- -------------------------------------------------------------
CREATE TRIGGER `trg_rating_only_discharged`
BEFORE INSERT ON `rating`
FOR EACH ROW
BEGIN
  DECLARE v_discharge DATETIME;

  SELECT `discharge_date` INTO v_discharge
  FROM   `hospitalization`
  WHERE  `hospitalization_id` = NEW.hospitalization_id;

  IF v_discharge IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Αξιολόγηση επιτρέπεται μόνο μετά την έξοδο του ασθενή.';
  END IF;
END$$

DELIMITER ;


-- RESTORE SESSION SETTINGS

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;