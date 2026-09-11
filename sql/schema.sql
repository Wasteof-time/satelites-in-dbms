-- Orbital Intelligence System — MariaDB schema
-- Apply against database ois_db (created by Docker / installer).

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS Collision_Alerts;
DROP TABLE IF EXISTS Debris_Records;
DROP TABLE IF EXISTS Maneuvers;
DROP TABLE IF EXISTS Position_History;
DROP TABLE IF EXISTS Orbit_Parameters;
DROP TABLE IF EXISTS Comm_Satellite;
DROP TABLE IF EXISTS Nav_Satellite;
DROP TABLE IF EXISTS EO_Satellite;
DROP TABLE IF EXISTS Sci_Satellite;
DROP TABLE IF EXISTS Sync_Log;
DROP TABLE IF EXISTS Satellite;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE Satellite (
    Satellite_ID   INT AUTO_INCREMENT PRIMARY KEY,
    NORAD_ID       VARCHAR(16)  NOT NULL,
    Name           VARCHAR(120) NOT NULL,
    Operator       VARCHAR(120) NULL,
    Status         ENUM('active', 'inactive', 'decayed', 'unknown')
                   NOT NULL DEFAULT 'active',
    Launch_Date    DATE NULL,
    UNIQUE KEY uq_satellite_norad (NORAD_ID),
    KEY idx_satellite_name (Name),
    KEY idx_satellite_operator (Operator)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Orbit_Parameters (
    Satellite_ID   INT NOT NULL,
    Inclination    DECIMAL(8,4)  NOT NULL,
    Eccentricity   DECIMAL(12,10) NOT NULL,
    Apogee_km      DECIMAL(10,2) NOT NULL,
    Perigee_km     DECIMAL(10,2) NOT NULL,
    Epoch          DATETIME NOT NULL,
    PRIMARY KEY (Satellite_ID),
    CONSTRAINT fk_orbit_satellite
        FOREIGN KEY (Satellite_ID) REFERENCES Satellite (Satellite_ID)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Position_History (
    Position_ID    INT AUTO_INCREMENT PRIMARY KEY,
    Satellite_ID   INT NOT NULL,
    Observed_At    DATETIME NOT NULL,
    Lat            DECIMAL(9,6)  NOT NULL,
    Lon            DECIMAL(9,6)  NOT NULL,
    Alt_km         DECIMAL(10,2) NOT NULL,
    KEY idx_position_sat_time (Satellite_ID, Observed_At),
    CONSTRAINT fk_position_satellite
        FOREIGN KEY (Satellite_ID) REFERENCES Satellite (Satellite_ID)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Maneuvers (
    Maneuver_ID    INT AUTO_INCREMENT PRIMARY KEY,
    Satellite_ID   INT NOT NULL,
    Maneuver_At    DATETIME NOT NULL,
    Type           VARCHAR(60)  NOT NULL,
    Notes          VARCHAR(255) NULL,
    KEY idx_maneuver_sat (Satellite_ID),
    CONSTRAINT fk_maneuver_satellite
        FOREIGN KEY (Satellite_ID) REFERENCES Satellite (Satellite_ID)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Collision_Alerts (
    Alert_ID       INT AUTO_INCREMENT PRIMARY KEY,
    Object_A_ID    INT NOT NULL,
    Object_B_ID    INT NOT NULL,
    Probability    DECIMAL(5,2) NOT NULL,
    Distance_km    DECIMAL(12,3) NOT NULL,
    Detected_At    DATETIME NOT NULL,
    Status         ENUM('open', 'watch', 'expired', 'cleared')
                   NOT NULL DEFAULT 'open',
    KEY idx_alert_pair (Object_A_ID, Object_B_ID),
    KEY idx_alert_status (Status, Detected_At),
    CONSTRAINT fk_alert_object_a
        FOREIGN KEY (Object_A_ID) REFERENCES Satellite (Satellite_ID)
        ON DELETE CASCADE,
    CONSTRAINT fk_alert_object_b
        FOREIGN KEY (Object_B_ID) REFERENCES Satellite (Satellite_ID)
        ON DELETE CASCADE,
    CONSTRAINT chk_alert_distinct CHECK (Object_A_ID <> Object_B_ID),
    CONSTRAINT chk_alert_probability CHECK (Probability >= 0 AND Probability <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Debris_Records (
    Debris_ID             INT AUTO_INCREMENT PRIMARY KEY,
    Parent_Satellite_ID   INT NULL,
    Catalog_ID            VARCHAR(16) NOT NULL,
    First_Seen            DATETIME NOT NULL,
    Status                ENUM('tracked', 'decayed', 'unknown')
                          NOT NULL DEFAULT 'tracked',
    UNIQUE KEY uq_debris_catalog (Catalog_ID),
    KEY idx_debris_parent (Parent_Satellite_ID),
    CONSTRAINT fk_debris_parent
        FOREIGN KEY (Parent_Satellite_ID) REFERENCES Satellite (Satellite_ID)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- EER specialization: disjoint subclasses. A satellite belongs in at most one.
CREATE TABLE Comm_Satellite (
    Satellite_ID   INT NOT NULL,
    Band           VARCHAR(40) NOT NULL,
    Transponders   INT NULL,
    PRIMARY KEY (Satellite_ID),
    CONSTRAINT fk_comm_satellite
        FOREIGN KEY (Satellite_ID) REFERENCES Satellite (Satellite_ID)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Nav_Satellite (
    Satellite_ID   INT NOT NULL,
    Constellation  VARCHAR(40) NOT NULL,
    Signal_Type    VARCHAR(40) NOT NULL,
    PRIMARY KEY (Satellite_ID),
    CONSTRAINT fk_nav_satellite
        FOREIGN KEY (Satellite_ID) REFERENCES Satellite (Satellite_ID)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE EO_Satellite (
    Satellite_ID   INT NOT NULL,
    Sensor         VARCHAR(60) NOT NULL,
    Resolution_m   DECIMAL(8,2) NULL,
    PRIMARY KEY (Satellite_ID),
    CONSTRAINT fk_eo_satellite
        FOREIGN KEY (Satellite_ID) REFERENCES Satellite (Satellite_ID)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Sci_Satellite (
    Satellite_ID   INT NOT NULL,
    Mission        VARCHAR(80) NOT NULL,
    Instrument     VARCHAR(80) NOT NULL,
    PRIMARY KEY (Satellite_ID),
    CONSTRAINT fk_sci_satellite
        FOREIGN KEY (Satellite_ID) REFERENCES Satellite (Satellite_ID)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Sync_Log (
    Sync_ID        INT AUTO_INCREMENT PRIMARY KEY,
    Synced_At      DATETIME NOT NULL,
    Source         VARCHAR(80) NOT NULL,
    Rows_Upserted  INT NOT NULL DEFAULT 0,
    Status         ENUM('success', 'partial', 'failed') NOT NULL,
    KEY idx_sync_time (Synced_At)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
