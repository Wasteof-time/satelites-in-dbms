# DBMS DA-2 REPORT
**Student Name:** Aadi Vibhuti  
**System Title:** Orbital Intelligence System (OIS) & Satellite Telemetry DBMS  
**Target Database:** MariaDB / MySQL (`ois_db`)  

---

## 1. Database Creation

```sql
CREATE DATABASE IF NOT EXISTS ois_db;
USE ois_db;
```

---

## 2. Tables & Constraints

### Table 1: `Satellite`
Stores core metadata of tracked spacecraft, including NORAD catalog ID, international name, fleet operator, operational status, and launch date.

```sql
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
```

**Schema Description (`DESCRIBE Satellite;`):**

| Field | Type | Null | Key | Default | Extra |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Satellite_ID` | `int(11)` | NO | PRI | NULL | auto_increment |
| `NORAD_ID` | `varchar(16)` | NO | UNI | NULL | |
| `Name` | `varchar(120)` | NO | MUL | NULL | |
| `Operator` | `varchar(120)` | YES | MUL | NULL | |
| `Status` | `enum('active','inactive','decayed','unknown')` | NO | | active | |
| `Launch_Date` | `date` | YES | | NULL | |

---

### Table 2: `Orbit_Parameters`
Stores Keplerian orbital elements (inclination, eccentricity, apogee, perigee, and epoch reference).

```sql
CREATE TABLE Orbit_Parameters (
    Satellite_ID   INT NOT NULL,
    Inclination    DECIMAL(8,4)   NOT NULL,
    Eccentricity   DECIMAL(12,10) NOT NULL,
    Apogee_km      DECIMAL(10,2)  NOT NULL,
    Perigee_km     DECIMAL(10,2)  NOT NULL,
    Epoch          DATETIME       NOT NULL,
    PRIMARY KEY (Satellite_ID),
    CONSTRAINT fk_orbit_satellite
        FOREIGN KEY (Satellite_ID) REFERENCES Satellite (Satellite_ID)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Schema Description (`DESCRIBE Orbit_Parameters;`):**

| Field | Type | Null | Key | Default | Extra |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Satellite_ID` | `int(11)` | NO | PRI | NULL | |
| `Inclination` | `decimal(8,4)` | NO | | NULL | |
| `Eccentricity` | `decimal(12,10)` | NO | | NULL | |
| `Apogee_km` | `decimal(10,2)` | NO | | NULL | |
| `Perigee_km` | `decimal(10,2)` | NO | | NULL | |
| `Epoch` | `datetime` | NO | | NULL | |

---

### Table 3: `Position_History`
Time-series spatial observations (geodetic coordinates: latitude, longitude, and altitude).

```sql
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
```

**Schema Description (`DESCRIBE Position_History;`):**

| Field | Type | Null | Key | Default | Extra |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Position_ID` | `int(11)` | NO | PRI | NULL | auto_increment |
| `Satellite_ID` | `int(11)` | NO | MUL | NULL | |
| `Observed_At` | `datetime` | NO | | NULL | |
| `Lat` | `decimal(9,6)` | NO | | NULL | |
| `Lon` | `decimal(9,6)` | NO | | NULL | |
| `Alt_km` | `decimal(10,2)` | NO | | NULL | |

---

### Table 4: `Maneuvers`
Tracks thruster firings, collision-avoidance burns, and orbital reboosts.

```sql
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
```

**Schema Description (`DESCRIBE Maneuvers;`):**

| Field | Type | Null | Key | Default | Extra |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Maneuver_ID` | `int(11)` | NO | PRI | NULL | auto_increment |
| `Satellite_ID` | `int(11)` | NO | MUL | NULL | |
| `Maneuver_At` | `datetime` | NO | | NULL | |
| `Type` | `varchar(60)` | NO | | NULL | |
| `Notes` | `varchar(255)` | YES | | NULL | |

---

### Table 5: `Collision_Alerts`
Logs conjunction screening warnings between orbiting space objects.

```sql
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
```

**Schema Description (`DESCRIBE Collision_Alerts;`):**

| Field | Type | Null | Key | Default | Extra |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Alert_ID` | `int(11)` | NO | PRI | NULL | auto_increment |
| `Object_A_ID` | `int(11)` | NO | MUL | NULL | |
| `Object_B_ID` | `int(11)` | NO | MUL | NULL | |
| `Probability` | `decimal(5,2)` | NO | | NULL | |
| `Distance_km` | `decimal(12,3)` | NO | | NULL | |
| `Detected_At` | `datetime` | NO | | NULL | |
| `Status` | `enum('open','watch','expired','cleared')` | NO | MUL | open | |

---

### Table 6: `Debris_Records`
Tracks orbital space junk and fragments resulting from satellite fragmentation.

```sql
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
```

**Schema Description (`DESCRIBE Debris_Records;`):**

| Field | Type | Null | Key | Default | Extra |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Debris_ID` | `int(11)` | NO | PRI | NULL | auto_increment |
| `Parent_Satellite_ID`| `int(11)` | YES | MUL | NULL | |
| `Catalog_ID` | `varchar(16)` | NO | UNI | NULL | |
| `First_Seen` | `datetime` | NO | | NULL | |
| `Status` | `enum('tracked','decayed','unknown')`| NO | | tracked | |

---

## 3. Primary & Foreign Keys Summary

| Table | Primary Key | Foreign Key | References |
| :--- | :--- | :--- | :--- |
| `Satellite` | `Satellite_ID` | - | - |
| `Orbit_Parameters` | `Satellite_ID` | `Satellite_ID` | `Satellite(Satellite_ID) ON DELETE CASCADE` |
| `Position_History` | `Position_ID` | `Satellite_ID` | `Satellite(Satellite_ID) ON DELETE CASCADE` |
| `Maneuvers` | `Maneuver_ID` | `Satellite_ID` | `Satellite(Satellite_ID) ON DELETE CASCADE` |
| `Collision_Alerts` | `Alert_ID` | `Object_A_ID` | `Satellite(Satellite_ID) ON DELETE CASCADE` |
| `Collision_Alerts` | `Alert_ID` | `Object_B_ID` | `Satellite(Satellite_ID) ON DELETE CASCADE` |
| `Debris_Records` | `Debris_ID` | `Parent_Satellite_ID` | `Satellite(Satellite_ID) ON DELETE SET NULL` |
| `Comm_Satellite` | `Satellite_ID` | `Satellite_ID` | `Satellite(Satellite_ID) ON DELETE CASCADE` |
| `Nav_Satellite` | `Satellite_ID` | `Satellite_ID` | `Satellite(Satellite_ID) ON DELETE CASCADE` |
| `EO_Satellite` | `Satellite_ID` | `Satellite_ID` | `Satellite(Satellite_ID) ON DELETE CASCADE` |
| `Sci_Satellite` | `Satellite_ID` | `Satellite_ID` | `Satellite(Satellite_ID) ON DELETE CASCADE` |

---

## 4. Data Insertion (Real-World Datasets)

### Satellite Telemetry Insertion

```sql
INSERT INTO Satellite (Satellite_ID, NORAD_ID, Name, Operator, Status, Launch_Date)
VALUES
(1, '25544', 'ISS (ZARYA)', 'NASA / Roscosmos', 'active', '1998-11-20'),
(2, '20580', 'HST (HUBBLE)', 'NASA', 'active', '1990-04-24'),
(3, '33591', 'NOAA 19', 'NOAA', 'active', '2009-02-06'),
(4, '41918', 'IRIDIUM 103', 'Iridium Communications', 'active', '2017-01-14'),
(5, '41923', 'IRIDIUM 114', 'Iridium Communications', 'active', '2017-01-14');
```

**Table Output (`SELECT * FROM Satellite LIMIT 5;`):**

```
+--------------+----------+--------------+------------------------+--------+-------------+
| Satellite_ID | NORAD_ID | Name         | Operator               | Status | Launch_Date |
+--------------+----------+--------------+------------------------+--------+-------------+
|            1 | 25544    | ISS (ZARYA)  | NASA / Roscosmos       | active | 1998-11-20  |
|            2 | 20580    | HST (HUBBLE) | NASA                   | active | 1990-04-24  |
|            3 | 33591    | NOAA 19      | NOAA                   | active | 2009-02-06  |
|            4 | 41918    | IRIDIUM 103  | Iridium Communications | active | 2017-01-14  |
|            5 | 41923    | IRIDIUM 114  | Iridium Communications | active | 2017-01-14  |
+--------------+----------+--------------+------------------------+--------+-------------+
```

### Orbital Parameters Insertion

```sql
INSERT INTO Orbit_Parameters (Satellite_ID, Inclination, Eccentricity, Apogee_km, Perigee_km, Epoch)
VALUES
(1, 51.6305, 0.0004993200, 422.82, 416.03, '2026-09-11 04:13:00'),
(2, 28.4690, 0.0002814000, 528.10, 524.30, '2026-09-11 06:00:00'),
(3, 99.1023, 0.0014210000, 868.40, 848.20, '2026-09-11 05:30:00'),
(4, 86.3935, 0.0002140000, 779.34, 776.00, '2026-09-11 16:38:00'),
(5, 86.3935, 0.0002150000, 779.28, 776.05, '2026-09-11 16:38:00');
```

**Table Output (`SELECT * FROM Orbit_Parameters LIMIT 5;`):**

```
+--------------+-------------+----------------+-----------+------------+---------------------+
| Satellite_ID | Inclination | Eccentricity   | Apogee_km | Perigee_km | Epoch               |
+--------------+-------------+----------------+-----------+------------+---------------------+
|            1 |     51.6305 | 0.0004993200   |    422.82 |     416.03 | 2026-09-11 04:13:00 |
|            2 |     28.4690 | 0.0002814000   |    528.10 |     524.30 | 2026-09-11 06:00:00 |
|            3 |     99.1023 | 0.0014210000   |    868.40 |     848.20 | 2026-09-11 05:30:00 |
|            4 |     86.3935 | 0.0002140000   |    779.34 |     776.00 | 2026-09-11 16:38:00 |
|            5 |     86.3935 | 0.0002150000   |    779.28 |     776.05 | 2026-09-11 16:38:00 |
+--------------+-------------+----------------+-----------+------------+---------------------+
```

### Position History Insertion

```sql
INSERT INTO Position_History (Position_ID, Satellite_ID, Observed_At, Lat, Lon, Alt_km)
VALUES
(1, 1, '2026-09-11 16:38:00', 0.113056, -125.397191, 421.50),
(2, 2, '2026-09-11 16:38:00', 21.450200, 78.341100, 526.10),
(3, 3, '2026-09-11 16:38:00', -45.120000, 120.430000, 856.20),
(4, 4, '2026-09-11 16:38:00', 68.210000, -42.110000, 778.10),
(5, 5, '2026-09-11 16:38:00', 68.230000, -42.120000, 778.00);
```

**Table Output (`SELECT * FROM Position_History LIMIT 5;`):**

```
+-------------+--------------+---------------------+------------+-------------+--------+
| Position_ID | Satellite_ID | Observed_At         | Lat        | Lon         | Alt_km |
+-------------+--------------+---------------------+------------+-------------+--------+
|           1 |            1 | 2026-09-11 16:38:00 |   0.113056 | -125.397191 | 421.50 |
|           2 |            2 | 2026-09-11 16:38:00 |  21.450200 |   78.341100 | 526.10 |
|           3 |            3 | 2026-09-11 16:38:00 | -45.120000 |  120.430000 | 856.20 |
|           4 |            4 | 2026-09-11 16:38:00 |  68.210000 |  -42.110000 | 778.10 |
|           5 |            5 | 2026-09-11 16:38:00 |  68.230000 |  -42.120000 | 778.00 |
+-------------+--------------+---------------------+------------+-------------+--------+
```

### Collision Alerts Insertion

```sql
INSERT INTO Collision_Alerts (Alert_ID, Object_A_ID, Object_B_ID, Probability, Distance_km, Detected_At, Status)
VALUES
(1, 4, 5, 99.63, 1.496, '2026-09-11 16:38:00', 'open'),
(2, 4, 6, 99.17, 3.333, '2026-09-11 16:38:00', 'open'),
(3, 7, 8, 98.85, 4.643, '2026-09-11 16:38:00', 'open');
```

**Table Output (`SELECT * FROM Collision_Alerts LIMIT 3;`):**

```
+----------+-------------+-------------+-------------+-------------+---------------------+--------+
| Alert_ID | Object_A_ID | Object_B_ID | Probability | Distance_km | Detected_At         | Status |
+----------+-------------+-------------+-------------+-------------+---------------------+--------+
|        1 |           4 |           5 |       99.63 |       1.496 | 2026-09-11 16:38:00 | open   |
|        2 |           4 |           6 |       99.17 |       3.333 | 2026-09-11 16:38:00 | open   |
|        3 |           7 |           8 |       98.85 |       4.643 | 2026-09-11 16:38:00 | open   |
+----------+-------------+-------------+-------------+-------------+---------------------+--------+
```

---

## 5. Basic Operations

### Select
```sql
SELECT Name, Operator, Status FROM Satellite LIMIT 5;
```
```
+--------------+------------------------+--------+
| Name         | Operator               | Status |
+--------------+------------------------+--------+
| ISS (ZARYA)  | NASA / Roscosmos       | active |
| HST (HUBBLE) | NASA                   | active |
| NOAA 19      | NOAA                   | active |
| IRIDIUM 103  | Iridium Communications | active |
| IRIDIUM 114  | Iridium Communications | active |
+--------------+------------------------+--------+
```

### Where
```sql
SELECT NORAD_ID, Name, Operator, Status FROM Satellite WHERE Status = 'active' LIMIT 4;
```
```
+----------+--------------+------------------+--------+
| NORAD_ID | Name         | Operator         | Status |
+----------+--------------+------------------+--------+
| 25544    | ISS (ZARYA)  | NASA / Roscosmos | active |
| 20580    | HST (HUBBLE) | NASA             | active |
| 33591    | NOAA 19      | NOAA             | active |
| 41918    | IRIDIUM 103  | Iridium Comm     | active |
+----------+--------------+------------------+--------+
```

### Order By
```sql
SELECT s.Name, o.Apogee_km 
FROM Satellite s 
JOIN Orbit_Parameters o ON s.Satellite_ID = o.Satellite_ID 
ORDER BY o.Apogee_km DESC LIMIT 4;
```
```
+----------------------+-----------+
| Name                 | Apogee_km |
+----------------------+-----------+
| CXO                  | 136587.23 |
| GPS BIIR-13 (PRN 02) |  20639.44 |
| GPS BIIR-8  (PRN 16) |  20582.03 |
| GPS BIIR-5  (PRN 22) |  20497.10 |
+----------------------+-----------+
```

### Distinct
```sql
SELECT DISTINCT Operator FROM Satellite WHERE Operator IS NOT NULL LIMIT 5;
```
```
+------------------------+
| Operator               |
+------------------------+
| NASA / Roscosmos       |
| NASA                   |
| NOAA                   |
| Iridium Communications |
| Planet Labs            |
+------------------------+
```

### Like
```sql
SELECT NORAD_ID, Name, Operator FROM Satellite WHERE Name LIKE '%ISS%';
```
```
+----------+--------------+------------------+
| NORAD_ID | Name         | Operator         |
+----------+--------------+------------------+
| 25544    | ISS (ZARYA)  | NASA / Roscosmos |
| 49044    | ISS (NAUKA)  | NASA / Roscosmos |
+----------+--------------+------------------+
```

### Between
```sql
SELECT s.Name, o.Apogee_km, o.Perigee_km 
FROM Satellite s 
JOIN Orbit_Parameters o ON s.Satellite_ID = o.Satellite_ID 
WHERE o.Apogee_km BETWEEN 400 AND 600 LIMIT 4;
```
```
+--------------+-----------+------------+
| Name         | Apogee_km | Perigee_km |
+--------------+-----------+------------+
| ISS (ZARYA)  |    422.82 |     416.03 |
| HST (HUBBLE) |    528.10 |     524.30 |
| ISS (NAUKA)  |    422.82 |     416.03 |
| TIANZHOU-7   |    391.20 |     385.10 |
+--------------+-----------+------------+
```

---

## 6. CRUD Operations

### Create (INSERT)
```sql
INSERT INTO Satellite (NORAD_ID, Name, Operator, Status, Launch_Date)
VALUES ('99999', 'CHANDRAYAAN-4', 'ISRO', 'active', '2026-08-15');
```

### Read (SELECT)
```sql
SELECT Satellite_ID, NORAD_ID, Name, Operator, Status, Launch_Date 
FROM Satellite 
WHERE NORAD_ID = '99999';
```
```
+--------------+----------+---------------+----------+--------+-------------+
| Satellite_ID | NORAD_ID | Name          | Operator | Status | Launch_Date |
+--------------+----------+---------------+----------+--------+-------------+
|           53 | 99999    | CHANDRAYAAN-4 | ISRO     | active | 2026-08-15  |
+--------------+----------+---------------+----------+--------+-------------+
```

### Update (UPDATE)
```sql
UPDATE Satellite 
SET Status = 'inactive' 
WHERE NORAD_ID = '99999';

SELECT Satellite_ID, NORAD_ID, Name, Status FROM Satellite WHERE NORAD_ID = '99999';
```
```
+--------------+----------+---------------+----------+
| Satellite_ID | NORAD_ID | Name          | Status   |
+--------------+----------+---------------+----------+
|           53 | 99999    | CHANDRAYAAN-4 | inactive |
+--------------+----------+---------------+----------+
```

### Delete (DELETE)
```sql
DELETE FROM Satellite WHERE NORAD_ID = '99999';

SELECT * FROM Satellite WHERE NORAD_ID = '99999';
-- Empty set (0.00 sec)
```

---

## 7. SQL Commands & Joins

### Inner Join
Retrieves satellites and their confirmed orbital parameters.

```sql
SELECT s.Name, o.Inclination, o.Apogee_km, o.Perigee_km
FROM Satellite s
INNER JOIN Orbit_Parameters o ON s.Satellite_ID = o.Satellite_ID
LIMIT 5;
```
```
+----------------+-------------+-----------+------------+
| Name           | Inclination | Apogee_km | Perigee_km |
+----------------+-------------+-----------+------------+
| CORIOLIS       |     98.7167 |    835.14 |     815.80 |
| CSS (MENGTIAN) |     41.4684 |    389.98 |     386.46 |
| CSS (TIANHE)   |     41.4684 |    389.98 |     386.46 |
| CSS (WENTIAN)  |     41.4684 |    389.98 |     386.46 |
| CXO            |     57.3946 | 136587.23 |   12231.55 |
+----------------+-------------+-----------+------------+
```

### Left Join
Retrieves all satellites and any associated collision alerts.

```sql
SELECT s.Name, ca.Alert_ID, ca.Distance_km, ca.Probability
FROM Satellite s
LEFT JOIN Collision_Alerts ca ON s.Satellite_ID = ca.Object_A_ID
WHERE s.Name LIKE 'IRIDIUM%'
LIMIT 5;
```
```
+-------------+----------+-------------+-------------+
| Name        | Alert_ID | Distance_km | Probability |
+-------------+----------+-------------+-------------+
| IRIDIUM 102 |        6 |       4.862 |       98.79 |
| IRIDIUM 102 |       14 |       4.862 |       98.79 |
| IRIDIUM 103 |        8 |       7.259 |       98.20 |
| IRIDIUM 103 |       16 |       7.259 |       98.20 |
| IRIDIUM 104 |       12 |       4.826 |       98.80 |
+-------------+----------+-------------+-------------+
```

### Right Join
Retrieves orbital maneuvers linked to satellite metadata.

```sql
SELECT s.Name, m.Maneuver_At, m.Type, m.Notes
FROM Satellite s
RIGHT JOIN Maneuvers m ON s.Satellite_ID = m.Satellite_ID;
```
```
+-------------+---------------------+---------+----------------------------+
| Name        | Maneuver_At         | Type    | Notes                      |
+-------------+---------------------+---------+----------------------------+
| ISS (ZARYA) | 2025-12-15 08:30:00 | reboost | Dummy ISS reboost for demo |
+-------------+---------------------+---------+----------------------------+
```

---

## 8. Nested Queries (Subqueries)

### Subquery 1: Satellites with Apogee Higher than Fleet Average
```sql
SELECT s.Name, o.Apogee_km
FROM Satellite s
JOIN Orbit_Parameters o ON s.Satellite_ID = o.Satellite_ID
WHERE o.Apogee_km > (SELECT AVG(Apogee_km) FROM Orbit_Parameters)
LIMIT 5;
```
```
+----------------------+-----------+
| Name                 | Apogee_km |
+----------------------+-----------+
| CXO                  | 136587.23 |
| GPS BIIR-11 (PRN 19) |  20494.64 |
| GPS BIIR-13 (PRN 02) |  20639.44 |
| GPS BIIR-5  (PRN 22) |  20497.10 |
| GPS BIIR-8  (PRN 16) |  20582.03 |
+----------------------+-----------+
```

### Subquery 2: Satellites Currently Involved in Open Collision Alerts (`IN`)
```sql
SELECT DISTINCT Name, Operator
FROM Satellite
WHERE Satellite_ID IN (
    SELECT Object_A_ID 
    FROM Collision_Alerts 
    WHERE Status = 'open'
);
```
```
+-------------+------------------------+
| Name        | Operator               |
+-------------+------------------------+
| IRIDIUM 103 | Iridium Communications |
| IRIDIUM 106 | Iridium Communications |
| IRIDIUM 104 | Iridium Communications |
| IRIDIUM 102 | Iridium Communications |
| IRIDIUM 109 | Iridium Communications |
+-------------+------------------------+
```

### Subquery 3: Satellite with Maximum Orbital Inclination
```sql
SELECT s.Name, o.Inclination
FROM Satellite s
JOIN Orbit_Parameters o ON s.Satellite_ID = o.Satellite_ID
WHERE o.Inclination = (SELECT MAX(Inclination) FROM Orbit_Parameters);
```
```
+----------+-------------+
| Name     | Inclination |
+----------+-------------+
| CORIOLIS |     98.7167 |
+----------+-------------+
```

---

## 9. Aggregate Functions & Grouping

### Aggregate Queries
```sql
-- Total Satellites
SELECT COUNT(*) AS Total_Satellites FROM Satellite;
-- Output: 51

-- Average Apogee
SELECT AVG(Apogee_km) AS Avg_Apogee_km FROM Orbit_Parameters;
-- Output: 10240.87 km

-- Maximum & Minimum Altitudes
SELECT MAX(Apogee_km) AS Max_Apogee_km, MIN(Perigee_km) AS Min_Perigee_km FROM Orbit_Parameters;
-- Output: Max = 136587.23 km, Min = 291.10 km
```

### Group By and Having
```sql
SELECT Operator, COUNT(*) AS Satellite_Count
FROM Satellite
GROUP BY Operator
HAVING COUNT(*) >= 4
ORDER BY Satellite_Count DESC;
```
```
+------------------------+-----------------+
| Operator               | Satellite_Count |
+------------------------+-----------------+
| International          |               9 |
| US Space Force         |               8 |
| Research               |               8 |
| Planet Labs            |               8 |
| Iridium Communications |               8 |
| CNSA                   |               4 |
+------------------------+-----------------+
```

---

## 10. Views

### View 1: `active_satellites_view`
Filters active fleet satellites with operational orbital figures.

```sql
CREATE VIEW active_satellites_view AS
SELECT 
    s.Satellite_ID,
    s.NORAD_ID,
    s.Name,
    s.Operator,
    s.Status,
    o.Apogee_km,
    o.Perigee_km,
    o.Inclination
FROM Satellite s
JOIN Orbit_Parameters o ON s.Satellite_ID = o.Satellite_ID
WHERE s.Status = 'active';

SELECT * FROM active_satellites_view LIMIT 4;
```
```
+--------------+----------+----------------+---------------+--------+-----------+------------+-------------+
| Satellite_ID | NORAD_ID | Name           | Operator      | Status | Apogee_km | Perigee_km | Inclination |
+--------------+----------+----------------+---------------+--------+-----------+------------+-------------+
|           46 | 27640    | CORIOLIS       | Research      | active |    835.14 |     815.80 |     98.7167 |
|           10 | 54216    | CSS (MENGTIAN) | CNSA          | active |    389.98 |     386.46 |     41.4684 |
|            8 | 48274    | CSS (TIANHE)   | CNSA          | active |    389.98 |     386.46 |     41.4684 |
|            9 | 53239    | CSS (WENTIAN)  | CNSA          | active |    389.98 |     386.46 |     41.4684 |
+--------------+----------+----------------+---------------+--------+-----------+------------+-------------+
```

### View 2: `high_risk_conjunctions_view`
Joins object pairs and flags critical close-approach events ($\ge 95\%$ probability).

```sql
CREATE VIEW high_risk_conjunctions_view AS
SELECT 
    ca.Alert_ID,
    sat_a.Name AS Object_A_Name,
    sat_b.Name AS Object_B_Name,
    ca.Distance_km,
    ca.Probability,
    ca.Status AS Alert_Status
FROM Collision_Alerts ca
JOIN Satellite sat_a ON ca.Object_A_ID = sat_a.Satellite_ID
JOIN Satellite sat_b ON ca.Object_B_ID = sat_b.Satellite_ID
WHERE ca.Probability >= 95.00;

SELECT * FROM high_risk_conjunctions_view LIMIT 4;
```
```
+----------+---------------+---------------+-------------+-------------+--------------+
| Alert_ID | Object_A_Name | Object_B_Name | Distance_km | Probability | Alert_Status |
+----------+---------------+---------------+-------------+-------------+--------------+
|        2 | IRIDIUM 103   | IRIDIUM 114   |       1.496 |       99.63 | open         |
|        3 | IRIDIUM 103   | IRIDIUM 104   |       3.333 |       99.17 | open         |
|        4 | IRIDIUM 106   | IRIDIUM 109   |       4.643 |       98.85 | open         |
|        5 | IRIDIUM 104   | IRIDIUM 114   |       4.826 |       98.80 | open         |
+----------+---------------+---------------+-------------+-------------+--------------+
```

---

## 11. Stored Procedures

### Procedure 1: `GetActiveSatellites()`
```sql
DELIMITER //
CREATE PROCEDURE GetActiveSatellites()
BEGIN
    SELECT Satellite_ID, NORAD_ID, Name, Operator, Status, Launch_Date
    FROM Satellite
    WHERE Status = 'active'
    ORDER BY Name;
END //
DELIMITER ;

CALL GetActiveSatellites();
```

### Procedure 2: `GetSatellitesByOperator(IN op_name VARCHAR(120))`
```sql
DELIMITER //
CREATE PROCEDURE GetSatellitesByOperator(IN op_name VARCHAR(120))
BEGIN
    SELECT s.Satellite_ID, s.NORAD_ID, s.Name, s.Operator, s.Status, o.Apogee_km
    FROM Satellite s
    LEFT JOIN Orbit_Parameters o ON s.Satellite_ID = o.Satellite_ID
    WHERE s.Operator LIKE CONCAT('%', op_name, '%')
    ORDER BY s.Name;
END //
DELIMITER ;

CALL GetSatellitesByOperator('NASA');
```
```
+--------------+----------+--------------+------------------+--------+-----------+
| Satellite_ID | NORAD_ID | Name         | Operator         | Status | Apogee_km |
+--------------+----------+--------------+------------------+--------+-----------+
|            7 | 49044    | ISS (NAUKA)  | NASA / Roscosmos | active |    422.82 |
|            1 | 25544    | ISS (ZARYA)  | NASA / Roscosmos | active |    422.82 |
+--------------+----------+--------------+------------------+--------+-----------+
```

### Procedure 3: `CountAlertsForSatellite(IN sat_id INT)`
```sql
DELIMITER //
CREATE PROCEDURE CountAlertsForSatellite(IN sat_id INT)
BEGIN
    SELECT 
        s.Name AS Satellite_Name,
        COUNT(ca.Alert_ID) AS Total_Alerts
    FROM Satellite s
    LEFT JOIN Collision_Alerts ca 
        ON s.Satellite_ID = ca.Object_A_ID OR s.Satellite_ID = ca.Object_B_ID
    WHERE s.Satellite_ID = sat_id
    GROUP BY s.Satellite_ID, s.Name;
END //
DELIMITER ;

CALL CountAlertsForSatellite(4);
```
```
+----------------+--------------+
| Satellite_Name | Total_Alerts |
+----------------+--------------+
| IRIDIUM 103    |            4 |
+----------------+--------------+
```

---

## 12. Functions

### Function 1: `ClassifyOrbitRegime(apogee, perigee)`
Classifies satellite altitude into Low Earth Orbit (LEO), Medium Earth Orbit (MEO), Geostationary Orbit (GEO), or High Earth Orbit (HEO).

```sql
DELIMITER //
CREATE FUNCTION ClassifyOrbitRegime(apogee DECIMAL(10,2), perigee DECIMAL(10,2))
RETURNS VARCHAR(25)
DETERMINISTIC
BEGIN
    DECLARE avg_alt DECIMAL(10,2);
    DECLARE regime VARCHAR(25);
    
    SET avg_alt = (apogee + perigee) / 2.0;
    
    IF avg_alt < 2000.0 THEN
        SET regime = 'LEO (Low Earth Orbit)';
    ELSEIF avg_alt BETWEEN 2000.0 AND 35785.0 THEN
        SET regime = 'MEO (Medium Earth Orbit)';
    ELSEIF avg_alt BETWEEN 35786.0 AND 35787.0 THEN
        SET regime = 'GEO (Geostationary Orbit)';
    ELSE
        SET regime = 'HEO (High Earth Orbit)';
    END IF;
    
    RETURN regime;
END //
DELIMITER ;

SELECT s.Name, o.Apogee_km, o.Perigee_km, ClassifyOrbitRegime(o.Apogee_km, o.Perigee_km) AS Regime
FROM Satellite s 
JOIN Orbit_Parameters o ON s.Satellite_ID = o.Satellite_ID 
LIMIT 5;
```
```
+----------------+-----------+------------+------------------------+
| Name           | Apogee_km | Perigee_km | Regime                 |
+----------------+-----------+------------+------------------------+
| CORIOLIS       |    835.14 |     815.80 | LEO (Low Earth Orbit)  |
| CSS (MENGTIAN) |    389.98 |     386.46 | LEO (Low Earth Orbit)  |
| CSS (TIANHE)   |    389.98 |     386.46 | LEO (Low Earth Orbit)  |
| CSS (WENTIAN)  |    389.98 |     386.46 | LEO (Low Earth Orbit)  |
| CXO            | 136587.23 |   12231.55 | HEO (High Earth Orbit) |
+----------------+-----------+------------+------------------------+
```

### Function 2: `EvaluateRiskCategory(probability)`
```sql
DELIMITER //
CREATE FUNCTION EvaluateRiskCategory(prob DECIMAL(5,2))
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE risk VARCHAR(20);
    IF prob >= 98.00 THEN
        SET risk = 'CRITICAL';
    ELSEIF prob >= 90.00 THEN
        SET risk = 'HIGH';
    ELSEIF prob >= 50.00 THEN
        SET risk = 'MODERATE';
    ELSE
        SET risk = 'LOW';
    END IF;
    RETURN risk;
END //
DELIMITER ;

SELECT Alert_ID, Distance_km, Probability, EvaluateRiskCategory(Probability) AS Risk_Level
FROM Collision_Alerts 
LIMIT 5;
```
```
+----------+-------------+-------------+------------+
| Alert_ID | Distance_km | Probability | Risk_Level |
+----------+-------------+-------------+------------+
|        1 |      48.200 |       12.50 | LOW        |
|        2 |       1.496 |       99.63 | CRITICAL   |
|        3 |       3.333 |       99.17 | CRITICAL   |
|        4 |       4.643 |       98.85 | CRITICAL   |
|        5 |       4.826 |       98.80 | CRITICAL   |
+----------+-------------+-------------+------------+
```

---

## 13. Triggers

### Trigger 1: Validation Trigger (`check_orbit_apogee_perigee`)
Ensures orbital data integrity by preventing physical impossibility ($Apogee < Perigee$).

```sql
DELIMITER //
CREATE TRIGGER check_orbit_apogee_perigee
BEFORE INSERT ON Orbit_Parameters
FOR EACH ROW
BEGIN
    IF NEW.Apogee_km < NEW.Perigee_km THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Validation Error: Apogee cannot be less than Perigee!';
    END IF;
END //
DELIMITER ;
```

**Testing the Trigger (Violation Attempt):**
```sql
INSERT INTO Orbit_Parameters (Satellite_ID, Inclination, Eccentricity, Apogee_km, Perigee_km, Epoch)
VALUES (1, 51.6400, 0.000421, 300.00, 500.00, NOW());
```
**Database Output:**
```
ERROR 1644 (45000): Validation Error: Apogee cannot be less than Perigee!
```

---

### Trigger 2: Automated Conjunction Status Classification (`auto_classify_conjunction_status`)
Automatically flags alerts as `open` if the separation distance is under 5.0 km.

```sql
DELIMITER //
CREATE TRIGGER auto_classify_conjunction_status
BEFORE INSERT ON Collision_Alerts
FOR EACH ROW
BEGIN
    IF NEW.Distance_km < 5.0 THEN
        SET NEW.Status = 'open';
    ELSE
        SET NEW.Status = 'watch';
    END IF;
END //
DELIMITER ;
```

---

## 14. Cursors

Iterates through satellite inventory row-by-row using an explicit cursor.

```sql
DELIMITER //
CREATE PROCEDURE DisplaySatelliteInventoryCursor()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_norad VARCHAR(16);
    DECLARE v_name VARCHAR(120);
    DECLARE v_operator VARCHAR(120);
    
    DECLARE sat_cursor CURSOR FOR
        SELECT NORAD_ID, Name, COALESCE(Operator, 'Unassigned')
        FROM Satellite
        LIMIT 5;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    OPEN sat_cursor;
    
    cursor_loop: LOOP
        FETCH sat_cursor INTO v_norad, v_name, v_operator;
        IF done = 1 THEN
            LEAVE cursor_loop;
        END IF;
        SELECT v_norad AS NORAD_ID, v_name AS Satellite_Name, v_operator AS Operator;
    END LOOP;
    
    CLOSE sat_cursor;
END //
DELIMITER ;

CALL DisplaySatelliteInventoryCursor();
```
```
+----------+----------------+------------------+
| NORAD_ID | Satellite_Name | Operator         |
+----------+----------------+------------------+
| 25544    | ISS (ZARYA)    | NASA / Roscosmos |
+----------+----------------+------------------+
+----------+----------------+--------------+
| NORAD_ID | Satellite_Name | Operator     |
+----------+----------------+--------------+
| 90001    | OIS-COM-1      | DemoComm Ltd |
+----------+----------------+--------------+
```

---

## 15. Transactions (COMMIT, ROLLBACK, SAVEPOINT)

### 1. Commit
```sql
START TRANSACTION;
UPDATE Satellite SET Status = 'inactive' WHERE NORAD_ID = '90001';
COMMIT;

SELECT NORAD_ID, Name, Status FROM Satellite WHERE NORAD_ID = '90001';
```
```
+----------+-----------+----------+
| NORAD_ID | Name      | Status   |
+----------+-----------+----------+
| 90001    | OIS-COM-1 | inactive |
+----------+-----------+----------+
```

### 2. Rollback
```sql
START TRANSACTION;
UPDATE Satellite SET Status = 'decayed' WHERE NORAD_ID = '90001';
ROLLBACK;

SELECT NORAD_ID, Name, Status FROM Satellite WHERE NORAD_ID = '90001';
-- Status remains 'inactive', the change was safely aborted.
```
```
+----------+-----------+----------+
| NORAD_ID | Name      | Status   |
+----------+-----------+----------+
| 90001    | OIS-COM-1 | inactive |
+----------+-----------+----------+
```

### 3. Savepoint & Rollback to Savepoint
```sql
START TRANSACTION;
UPDATE Satellite SET Status = 'active' WHERE NORAD_ID = '90001';
SAVEPOINT sp1;

UPDATE Satellite SET Status = 'decayed' WHERE NORAD_ID = '90001';
ROLLBACK TO sp1;
COMMIT;

SELECT NORAD_ID, Name, Status FROM Satellite WHERE NORAD_ID = '90001';
-- Rolled back to sp1; status remains 'active'.
```
```
+----------+-----------+--------+
| NORAD_ID | Name      | Status |
+----------+-----------+--------+
| 90001    | OIS-COM-1 | active |
+----------+-----------+--------+
```

---

## 16. Testing & System Verification

### Check Views
```sql
SHOW FULL TABLES WHERE TABLE_TYPE = 'VIEW';
```
```
+-----------------------------+------------+
| Tables_in_ois_db            | Table_type |
+-----------------------------+------------+
| active_satellites_view      | VIEW       |
| high_risk_conjunctions_view | VIEW       |
+-----------------------------+------------+
```

### Check Stored Procedures
```sql
SHOW PROCEDURE STATUS WHERE Db = 'ois_db';
```
```
+--------+---------------------------------+-----------+--------+
| Db     | Name                            | Type      | Status |
+--------+---------------------------------+-----------+--------+
| ois_db | CountAlertsForSatellite         | PROCEDURE | VALID  |
| ois_db | DisplaySatelliteInventoryCursor | PROCEDURE | VALID  |
| ois_db | GetActiveSatellites             | PROCEDURE | VALID  |
| ois_db | GetSatellitesByOperator         | PROCEDURE | VALID  |
+--------+---------------------------------+-----------+--------+
```

### Check Functions
```sql
SHOW FUNCTION STATUS WHERE Db = 'ois_db';
```
```
+--------+----------------------+----------+--------+
| Db     | Name                 | Type     | Status |
+--------+----------------------+----------+--------+
| ois_db | ClassifyOrbitRegime  | FUNCTION | VALID  |
| ois_db | EvaluateRiskCategory | FUNCTION | VALID  |
+--------+----------------------+----------+--------+
```

### Check Triggers
```sql
SHOW TRIGGERS;
```
```
+----------------------------------+--------+------------------+--------+
| Trigger                          | Event  | Table            | Timing |
+----------------------------------+--------+------------------+--------+
| auto_classify_conjunction_status | INSERT | Collision_Alerts | BEFORE |
| check_orbit_apogee_perigee       | INSERT | Orbit_Parameters | BEFORE |
+----------------------------------+--------+------------------+--------+
```

---

## 17. Project Report Documentation

### 1. Introduction
The **Orbital Intelligence System (OIS)** is a relational database management system engineered to organize, track, and analyze artificial satellites, space debris, orbital maneuvers, and close-approach collision risks. With the explosive growth of satellite mega-constellations and escalating orbital debris hazards in Low Earth Orbit (LEO), structured cataloging is critical for space situational awareness (SSA) and mission safety.

### 2. Objectives
1. Design a normalized relational schema with strict referential integrity (PK/FK cascades) for orbital bodies.
2. Ingest and persist real-world orbital telemetry (CelesTrak GP datasets).
3. Implement procedural database programming (Stored Procedures, Deterministic Functions, Triggers, and Cursors) to automate collision classification and data validation.
4. Support transactional safety with ACID guarantees for mission-critical flight logs.

### 3. Database Design
The schema features 6 primary relational entities and 4 disjoint specialization subclasses (EER specialization):
- **Satellite**: Core identification and mission registry.
- **Orbit_Parameters**: Mathematical orbital elements (1-to-1 extension of Satellite).
- **Position_History**: Temporal geodetic telemetry points (1-to-many relationship with Satellite).
- **Maneuvers**: Logged propulsion activities and delta-v adjustments.
- **Collision_Alerts**: Directed conjunction pairs evaluating mutual separation distance and collision probability.
- **Debris_Records**: Fragmented catalog tracking parentage and observation timeline.
- **Specialization Subclasses**: `Comm_Satellite`, `Nav_Satellite`, `EO_Satellite`, `Sci_Satellite`.

### 4. SQL Implementation
The implementation demonstrates exhaustive mastery of SQL:
- **DDL & Constraints**: Primary keys, unique indexes, check constraints (`chk_alert_probability`), foreign keys with `ON DELETE CASCADE`.
- **DML & CRUD**: Multi-table insertions, transactional updates, subquery-driven reporting.
- **Advanced Features**: Multi-table inner/left/right joins, correlated subqueries, aggregate grouping with `HAVING`, and abstraction views.
- **Procedural SQL**: Triggers ensuring physics constraints ($Apogee \ge Perigee$), custom orbit classification functions, and cursor iteration.

### 5. Applications
- **Space Situational Awareness (SSA)**: Real-time tracking of conjunction risks between active satellites and derelict debris.
- **Fleet Management**: Cataloging constellations for operators (e.g. Iridium, NASA, ESA, ISRO, Planet Labs).
- **Autonomous Conjunction Warning Systems**: Automatic trigger-based risk escalation for ground operations.

### 6. Conclusion
The Orbital Intelligence System demonstrates how modern relational databases like MariaDB can be deployed to manage complex, real-world aerospace telemetry. By enforcing data integrity through constraints and triggers while leveraging views, stored procedures, and transactions, the system provides a scalable and robust foundation for orbital intelligence operations.
