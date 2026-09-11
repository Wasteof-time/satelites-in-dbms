-- Sanity-check rows. Real CelesTrak ingest upserts NORAD 25544 (ISS)
-- and leaves the 9xxxx dummy catalog in place for type / alert demos.

INSERT INTO Satellite (NORAD_ID, Name, Operator, Status, Launch_Date) VALUES
    ('25544', 'ISS (ZARYA)',           'NASA / Roscosmos',      'active', '1998-11-20'),
    ('90001', 'OIS-COM-1',             'DemoComm Ltd',          'active', '2020-03-15'),
    ('90002', 'OIS-NAV-1',             'DemoNav Agency',        'active', '2019-06-01'),
    ('90003', 'OIS-EO-1',              'DemoEarth Imaging',     'active', '2021-09-12'),
    ('90004', 'OIS-SCI-1',             'Demo Science Institute','active', '2018-01-08');

INSERT INTO Orbit_Parameters
    (Satellite_ID, Inclination, Eccentricity, Apogee_km, Perigee_km, Epoch)
SELECT Satellite_ID, 51.6400, 0.0006700, 421.00, 417.00, '2026-01-01 12:00:00'
FROM Satellite WHERE NORAD_ID = '25544';

INSERT INTO Orbit_Parameters
    (Satellite_ID, Inclination, Eccentricity, Apogee_km, Perigee_km, Epoch)
SELECT Satellite_ID, 0.0500, 0.0002000, 35794.00, 35778.00, '2026-01-01 12:00:00'
FROM Satellite WHERE NORAD_ID = '90001';

INSERT INTO Orbit_Parameters
    (Satellite_ID, Inclination, Eccentricity, Apogee_km, Perigee_km, Epoch)
SELECT Satellite_ID, 55.0000, 0.0040000, 20200.00, 19900.00, '2026-01-01 12:00:00'
FROM Satellite WHERE NORAD_ID = '90002';

INSERT INTO Orbit_Parameters
    (Satellite_ID, Inclination, Eccentricity, Apogee_km, Perigee_km, Epoch)
SELECT Satellite_ID, 97.4000, 0.0012000, 512.00, 495.00, '2026-01-01 12:00:00'
FROM Satellite WHERE NORAD_ID = '90003';

INSERT INTO Orbit_Parameters
    (Satellite_ID, Inclination, Eccentricity, Apogee_km, Perigee_km, Epoch)
SELECT Satellite_ID, 51.6000, 0.0008000, 430.00, 410.00, '2026-01-01 12:00:00'
FROM Satellite WHERE NORAD_ID = '90004';

-- Two history rows each for ISS and the science dummy so trajectory works
-- even before the first live sync. Close ISS / OIS-SCI-1 pair for alerts.
INSERT INTO Position_History (Satellite_ID, Observed_At, Lat, Lon, Alt_km)
SELECT Satellite_ID, '2026-01-01 11:50:00', 25.100000, 40.000000, 418.00
FROM Satellite WHERE NORAD_ID = '25544';
INSERT INTO Position_History (Satellite_ID, Observed_At, Lat, Lon, Alt_km)
SELECT Satellite_ID, '2026-01-01 12:00:00', 27.400000, 42.500000, 419.00
FROM Satellite WHERE NORAD_ID = '25544';

INSERT INTO Position_History (Satellite_ID, Observed_At, Lat, Lon, Alt_km)
SELECT Satellite_ID, '2026-01-01 11:50:00', 25.300000, 40.200000, 420.00
FROM Satellite WHERE NORAD_ID = '90004';
INSERT INTO Position_History (Satellite_ID, Observed_At, Lat, Lon, Alt_km)
SELECT Satellite_ID, '2026-01-01 12:00:00', 27.600000, 42.700000, 421.00
FROM Satellite WHERE NORAD_ID = '90004';

INSERT INTO Position_History (Satellite_ID, Observed_At, Lat, Lon, Alt_km)
SELECT Satellite_ID, '2026-01-01 12:00:00',  0.100000,  75.000000, 35786.00
FROM Satellite WHERE NORAD_ID = '90001';
INSERT INTO Position_History (Satellite_ID, Observed_At, Lat, Lon, Alt_km)
SELECT Satellite_ID, '2026-01-01 12:00:00', 55.000000, -20.000000, 20100.00
FROM Satellite WHERE NORAD_ID = '90002';
INSERT INTO Position_History (Satellite_ID, Observed_At, Lat, Lon, Alt_km)
SELECT Satellite_ID, '2026-01-01 12:00:00', -12.000000, 130.000000, 500.00
FROM Satellite WHERE NORAD_ID = '90003';

INSERT INTO Maneuvers (Satellite_ID, Maneuver_At, Type, Notes)
SELECT Satellite_ID, '2025-12-15 08:30:00', 'reboost', 'Dummy ISS reboost for demo'
FROM Satellite WHERE NORAD_ID = '25544';

INSERT INTO Comm_Satellite (Satellite_ID, Band, Transponders)
SELECT Satellite_ID, 'Ku', 24 FROM Satellite WHERE NORAD_ID = '90001';

INSERT INTO Nav_Satellite (Satellite_ID, Constellation, Signal_Type)
SELECT Satellite_ID, 'DemoGNSS', 'L1/L2' FROM Satellite WHERE NORAD_ID = '90002';

INSERT INTO EO_Satellite (Satellite_ID, Sensor, Resolution_m)
SELECT Satellite_ID, 'Multispectral', 3.50 FROM Satellite WHERE NORAD_ID = '90003';

INSERT INTO Sci_Satellite (Satellite_ID, Mission, Instrument)
SELECT Satellite_ID, 'Microgravity lab', 'Various' FROM Satellite WHERE NORAD_ID = '25544';
INSERT INTO Sci_Satellite (Satellite_ID, Mission, Instrument)
SELECT Satellite_ID, 'Ionosphere probe', 'Langmuir' FROM Satellite WHERE NORAD_ID = '90004';

INSERT INTO Collision_Alerts
    (Object_A_ID, Object_B_ID, Probability, Distance_km, Detected_At, Status)
SELECT a.Satellite_ID, b.Satellite_ID, 12.50, 48.200, '2026-01-01 12:00:00', 'watch'
FROM Satellite a
JOIN Satellite b ON a.NORAD_ID = '25544' AND b.NORAD_ID = '90004';

INSERT INTO Debris_Records (Parent_Satellite_ID, Catalog_ID, First_Seen, Status)
SELECT Satellite_ID, '90051', '2015-06-01 00:00:00', 'tracked'
FROM Satellite WHERE NORAD_ID = '90001';

INSERT INTO Sync_Log (Synced_At, Source, Rows_Upserted, Status)
VALUES ('2026-01-01 12:00:00', 'seed', 5, 'success');
