-- =============================================================================
-- ORBITAL INTELLIGENCE SYSTEM (OIS) - ADVANCED SQL FEATURES DEMO
-- Views, Stored Procedures, Functions, Triggers, Cursors & Transactions
-- =============================================================================

USE ois_db;

-- -----------------------------------------------------------------------------
-- 1. VIEWS
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS active_satellites_view;
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

DROP VIEW IF EXISTS high_risk_conjunctions_view;
CREATE VIEW high_risk_conjunctions_view AS
SELECT 
    ca.Alert_ID,
    sat_a.Name AS Object_A_Name,
    sat_a.NORAD_ID AS NORAD_A,
    sat_b.Name AS Object_B_Name,
    sat_b.NORAD_ID AS NORAD_B,
    ca.Distance_km,
    ca.Probability,
    ca.Detected_At,
    ca.Status AS Alert_Status
FROM Collision_Alerts ca
JOIN Satellite sat_a ON ca.Object_A_ID = sat_a.Satellite_ID
JOIN Satellite sat_b ON ca.Object_B_ID = sat_b.Satellite_ID
WHERE ca.Probability >= 95.00;

-- -----------------------------------------------------------------------------
-- 2. STORED PROCEDURES
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS GetActiveSatellites;
DELIMITER //
CREATE PROCEDURE GetActiveSatellites()
BEGIN
    SELECT Satellite_ID, NORAD_ID, Name, Operator, Status, Launch_Date
    FROM Satellite
    WHERE Status = 'active'
    ORDER BY Name;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS GetSatellitesByOperator;
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

DROP PROCEDURE IF EXISTS CountAlertsForSatellite;
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

-- -----------------------------------------------------------------------------
-- 3. FUNCTIONS
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS ClassifyOrbitRegime;
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

DROP FUNCTION IF EXISTS EvaluateRiskCategory;
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

-- -----------------------------------------------------------------------------
-- 4. TRIGGERS
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS check_orbit_apogee_perigee;
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

DROP TRIGGER IF EXISTS auto_classify_conjunction_status;
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

-- -----------------------------------------------------------------------------
-- 5. CURSORS
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS DisplaySatelliteInventoryCursor;
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
