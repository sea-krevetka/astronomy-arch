-- =====================================================
-- Инициализация базы данных astronomy_catalog
-- Скрипт выполняется автоматически при первом запуске контейнера
-- =====================================================

-- Устанавливаем кодировку и временную зону
SET client_encoding = 'UTF8';
SET timezone = 'UTC';

-- Создаем расширения (если нужны)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- 1. Таблица: galaxy_types (Типы галактик)
-- =====================================================
DROP TABLE IF EXISTS galaxy_types CASCADE;
CREATE TABLE galaxy_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    structure_shape TEXT,
    stellar_population TEXT,
    star_formation TEXT,
    size_mass TEXT,
    color TEXT,
    spatial_distribution TEXT,
    origin TEXT
);

-- =====================================================
-- 2. Таблица: galaxies (Галактики)
-- =====================================================
DROP TABLE IF EXISTS galaxies CASCADE;
CREATE TABLE galaxies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    galaxy_type_id INTEGER REFERENCES galaxy_types(id) ON DELETE SET NULL,
    diameter_ly BIGINT,
    star_count VARCHAR(50),
    mass_solar_masses VARCHAR(50),
    distance_from_earth_ly BIGINT,
    age_billion_years NUMERIC(5,2),
    metallicity VARCHAR(50),
    rotation_speed_kms INTEGER,
    discovery_year INTEGER
);

-- =====================================================
-- 3. Таблица: stars (Звезды)
-- =====================================================
DROP TABLE IF EXISTS stars CASCADE;
CREATE TABLE stars (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    galaxy_id INTEGER REFERENCES galaxies(id) ON DELETE CASCADE,
    mass_solar NUMERIC(10,2),
    temperature_k INTEGER,
    luminosity_solar NUMERIC(20,2),
    radius_solar NUMERIC(10,2),
    spectral_class VARCHAR(20),
    distance_from_sun_ly NUMERIC(15,2),
    age_billion_years NUMERIC(10,2),
    apparent_magnitude NUMERIC(10,2)
);

-- =====================================================
-- 4. Таблица: planets (Планеты)
-- =====================================================
DROP TABLE IF EXISTS planets CASCADE;
CREATE TABLE planets (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    star_id INTEGER REFERENCES stars(id) ON DELETE CASCADE,
    planet_type VARCHAR(50),
    mass_earth NUMERIC(10,2),
    diameter_km INTEGER,
    orbital_period_days NUMERIC(10,2),
    distance_from_star_au NUMERIC(10,4),
    surface_temperature_c VARCHAR(50),
    satellites_count INTEGER,
    atmosphere_composition TEXT
);

-- =====================================================
-- 5. Таблица: satellites (Спутники)
-- =====================================================
DROP TABLE IF EXISTS satellites CASCADE;
CREATE TABLE satellites (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    planet_id INTEGER REFERENCES planets(id) ON DELETE CASCADE,
    satellite_type VARCHAR(50),
    diameter_km NUMERIC(10,2),
    mass_kg VARCHAR(50),
    orbital_period_days NUMERIC(10,2),
    distance_from_planet_km INTEGER,
    temperature_c VARCHAR(50),
    discovery_year INTEGER,
    discoverer VARCHAR(200)
);

-- =====================================================
-- 6. Таблица: small_bodies (Малые тела: астероиды, кометы)
-- =====================================================
DROP TABLE IF EXISTS small_bodies CASCADE;
CREATE TABLE small_bodies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    spk_id VARCHAR(50) UNIQUE,
    designation VARCHAR(200),
    body_type VARCHAR(20) CHECK (body_type IN ('Asteroid', 'Comet', 'Dwarf Planet')),
    epoch_jd NUMERIC(15, 5),
    eccentricity NUMERIC(15, 10),
    semi_major_axis_au NUMERIC(15, 8),
    perihelion_au NUMERIC(15, 8),
    aphelion_au NUMERIC(15, 8),
    inclination_deg NUMERIC(10, 6),
    arg_periapsis_deg NUMERIC(10, 6),
    long_asc_node_deg NUMERIC(10, 6),
    mean_anomaly_deg NUMERIC(10, 6),
    orbital_period_days NUMERIC(15, 4),
    diameter_km NUMERIC(10, 3),
    rotation_period_h NUMERIC(10, 4),
    albedo NUMERIC(6, 4),
    spectral_type VARCHAR(10),
    magnitude_h NUMERIC(6, 2),
    discovery_date DATE,
    discovery_site VARCHAR(200),
    discoverer VARCHAR(200),
    is_pha BOOLEAN DEFAULT false,
    data_source TEXT,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 7. Таблица: feature_flags (Функциональные флаги)
-- =====================================================
DROP TABLE IF EXISTS feature_flags CASCADE;
CREATE TABLE feature_flags (
    id SERIAL PRIMARY KEY,
    flag_name VARCHAR(100) NOT NULL UNIQUE,
    is_enabled BOOLEAN DEFAULT false,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 8. Таблица: users (Пользователи)
-- =====================================================
DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- =====================================================
-- 9. Таблица: audit_log (Журнал действий)
-- =====================================================
DROP TABLE IF EXISTS audit_log CASCADE;
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100),
    table_name VARCHAR(100),
    record_id INTEGER,
    old_data JSONB,
    new_data JSONB,
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET
);

-- =====================================================
-- Создание индексов
-- =====================================================
CREATE INDEX idx_galaxies_name ON galaxies(name);
CREATE INDEX idx_galaxies_type_id ON galaxies(galaxy_type_id);
CREATE INDEX idx_galaxies_distance ON galaxies(distance_from_earth_ly);
CREATE INDEX idx_galaxies_discovery_year ON galaxies(discovery_year);

CREATE INDEX idx_stars_name ON stars(name);
CREATE INDEX idx_stars_galaxy_id ON stars(galaxy_id);
CREATE INDEX idx_stars_spectral_class ON stars(spectral_class);
CREATE INDEX idx_stars_distance ON stars(distance_from_sun_ly);

CREATE INDEX idx_planets_name ON planets(name);
CREATE INDEX idx_planets_star_id ON planets(star_id);
CREATE INDEX idx_planets_type ON planets(planet_type);

CREATE INDEX idx_satellites_name ON satellites(name);
CREATE INDEX idx_satellites_planet_id ON satellites(planet_id);
CREATE INDEX idx_satellites_discovery_year ON satellites(discovery_year);

CREATE INDEX idx_small_bodies_name ON small_bodies(name);
CREATE INDEX idx_small_bodies_type ON small_bodies(body_type);
CREATE INDEX idx_small_bodies_designation ON small_bodies(designation);
CREATE INDEX idx_small_bodies_pha ON small_bodies(is_pha);

CREATE INDEX idx_stars_galaxy_class ON stars(galaxy_id, spectral_class);
CREATE INDEX idx_planets_star_type ON planets(star_id, planet_type);

-- =====================================================
-- Создание представлений
-- =====================================================
DROP VIEW IF EXISTS view_galaxies_full;
CREATE VIEW view_galaxies_full AS
SELECT 
    g.id,
    g.name AS galaxy_name,
    gt.name AS galaxy_type,
    gt.description AS type_description,
    g.diameter_ly,
    g.star_count,
    g.mass_solar_masses,
    g.distance_from_earth_ly,
    g.age_billion_years,
    g.metallicity,
    g.rotation_speed_kms,
    g.discovery_year
FROM galaxies g
LEFT JOIN galaxy_types gt ON g.galaxy_type_id = gt.id;

DROP VIEW IF EXISTS view_stars_full;
CREATE VIEW view_stars_full AS
SELECT 
    s.id,
    s.name AS star_name,
    g.name AS galaxy_name,
    s.mass_solar,
    s.temperature_k,
    s.luminosity_solar,
    s.radius_solar,
    s.spectral_class,
    s.distance_from_sun_ly,
    s.age_billion_years,
    s.apparent_magnitude,
    (SELECT COUNT(*) FROM planets p WHERE p.star_id = s.id) AS planets_count
FROM stars s
LEFT JOIN galaxies g ON s.galaxy_id = g.id;

DROP VIEW IF EXISTS view_planets_full;
CREATE VIEW view_planets_full AS
SELECT 
    p.id,
    p.name AS planet_name,
    s.name AS star_name,
    s.spectral_class AS star_spectral_class,
    p.planet_type,
    p.mass_earth,
    p.diameter_km,
    p.orbital_period_days,
    p.distance_from_star_au,
    p.surface_temperature_c,
    p.satellites_count,
    p.atmosphere_composition
FROM planets p
LEFT JOIN stars s ON p.star_id = s.id;

DROP VIEW IF EXISTS view_satellites_full;
CREATE VIEW view_satellites_full AS
SELECT 
    sat.id,
    sat.name AS satellite_name,
    p.name AS planet_name,
    sat.satellite_type,
    sat.diameter_km,
    sat.mass_kg,
    sat.orbital_period_days,
    sat.distance_from_planet_km,
    sat.temperature_c,
    sat.discovery_year,
    sat.discoverer
FROM satellites sat
LEFT JOIN planets p ON sat.planet_id = p.id;

-- =====================================================
-- Функции для работы с feature_flags
-- =====================================================
CREATE OR REPLACE FUNCTION is_feature_enabled(flag_name_param VARCHAR)
RETURNS BOOLEAN AS $$
DECLARE
    enabled BOOLEAN;
BEGIN
    SELECT is_enabled INTO enabled
    FROM feature_flags
    WHERE flag_name = flag_name_param;
    
    RETURN COALESCE(enabled, false);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION enable_feature(flag_name_param VARCHAR, description_param TEXT DEFAULT NULL)
RETURNS VOID AS $$
BEGIN
    INSERT INTO feature_flags (flag_name, is_enabled, description, updated_at)
    VALUES (flag_name_param, true, description_param, CURRENT_TIMESTAMP)
    ON CONFLICT (flag_name) 
    DO UPDATE SET is_enabled = true, updated_at = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION disable_feature(flag_name_param VARCHAR)
RETURNS VOID AS $$
BEGIN
    UPDATE feature_flags
    SET is_enabled = false, updated_at = CURRENT_TIMESTAMP
    WHERE flag_name = flag_name_param;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Функция для аудита
-- =====================================================
CREATE OR REPLACE FUNCTION log_audit()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (user_id, action, table_name, record_id, old_data, new_data)
    VALUES (
        COALESCE(current_setting('app.current_user_id', true)::INTEGER, 1),
        TG_OP,
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE NULL END,
        CASE WHEN TG_OP = 'INSERT' THEN to_jsonb(NEW) 
             WHEN TG_OP = 'UPDATE' THEN to_jsonb(NEW) 
             ELSE NULL END
    );
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ВСТАВКА ДАННЫХ
-- =====================================================

-- 1. Вставка galaxy_types
INSERT INTO galaxy_types (name, description, structure_shape, stellar_population, star_formation, size_mass, color, spatial_distribution, origin) VALUES
('Эллиптическая', 'Звездные системы эллипсоидной формы, содержащие старые желтые/красные звезды...', 'Форма от круглой до сильно вытянутой', 'Старые звезды', 'Отсутствует', '1-200 кпк, 10^6-10^12 M☉', 'Красноватый', 'В центрах скоплений', 'Слияния галактик'),
('Линзовидная', 'Промежуточный тип между эллиптическими и спиральными', 'Дисковая структура без рукавов', 'Старые звезды', 'Отсутствует', 'Схожи со спиральными', 'Красновато-желтый', 'В скоплениях', 'Бывшие спиральные'),
('Спиральная', 'Дисковые галактики со спиральными рукавами', 'Плоский диск + сферическое гало', 'Смешанное', 'Активное', '20-150 кпк, 10^9-10^12 M☉', 'Голубовато-белый', 'Вне центров скоплений', 'Из газовых облаков'),
('Спиральная с перемычкой', 'Спиральные с баром через центр', 'Бар + спиральные рукава', 'Смешанное', 'Активное', 'Аналогичны спиральным', 'Перемычка желтая, рукава голубые', '>50% спиральных', 'Динамическая неустойчивость'),
('Неправильная', 'Без четкой структуры', 'Аморфная форма', 'Молодые звезды', 'Очень активное', 'До 50 кпк, до 10^10 M☉', 'Голубоватый', 'Повсеместно', 'Гравитационные возмущения');

-- 2. Вставка galaxies
WITH gt AS (SELECT id, name FROM galaxy_types)
INSERT INTO galaxies (name, galaxy_type_id, diameter_ly, star_count, mass_solar_masses, distance_from_earth_ly, age_billion_years, metallicity, rotation_speed_kms, discovery_year) VALUES
('Млечный Путь', (SELECT id FROM gt WHERE name = 'Спиральная с перемычкой'), 100000, '100-400 млрд', '1-2 трлн', 0, 13.6, 'Высокая', 220, 1610),
('Андромеда (M31)', (SELECT id FROM gt WHERE name = 'Спиральная'), 220000, '~1 трлн', '1.5 трлн', 2500000, 10.0, 'Средняя', 250, 964),
('Треугольник (M33)', (SELECT id FROM gt WHERE name = 'Спиральная'), 60000, '~40 млрд', '10-40 млрд', 3000000, 8.0, 'Низкая', 100, 1654),
('Болид (NGC 6822)', (SELECT id FROM gt WHERE name = 'Неправильная'), 7000, '~10 млн', '140 млн', 1600000, 5.0, 'Очень низкая', 57, 1884),
('Водоворот (M51)', (SELECT id FROM gt WHERE name = 'Спиральная'), 76000, '~160 млрд', '160 млрд', 23000000, 7.0, 'Средняя', 210, 1773),
('Сомбреро (M104)', (SELECT id FROM gt WHERE name = 'Спиральная'), 50000, '~800 млрд', '800 млрд', 28000000, 11.0, 'Высокая', 340, 1781),
('Большое Магелланово Облако', (SELECT id FROM gt WHERE name = 'Неправильная'), 14000, '~30 млрд', '10 млрд', 163000, 3.0, 'Низкая', 90, 964),
('Малое Магелланово Облако', (SELECT id FROM gt WHERE name = 'Неправильная'), 7000, '~3 млрд', '7 млрд', 200000, 2.5, 'Низкая', 60, 964),
('Центавр A (NGC 5128)', (SELECT id FROM gt WHERE name = 'Эллиптическая'), 60000, '~200 млрд', '1 трлн', 12000000, 12.0, 'Средняя', 220, 1826),
('Вертушка (M101)', (SELECT id FROM gt WHERE name = 'Спиральная'), 170000, '~1 трлн', '100 млрд', 21000000, 8.5, 'Средняя', 150, 1781);

-- 3. Вставка stars
WITH g AS (SELECT id, name FROM galaxies)
INSERT INTO stars (name, galaxy_id, mass_solar, temperature_k, luminosity_solar, radius_solar, spectral_class, distance_from_sun_ly, age_billion_years, apparent_magnitude) VALUES
('Солнце', (SELECT id FROM g WHERE name = 'Млечный Путь'), 1.0, 5778, 1.0, 1.0, 'G2V', 0, 4.6, -26.74),
('Сириус (α Большого Пса)', (SELECT id FROM g WHERE name = 'Млечный Путь'), 2.02, 9940, 25.4, 1.71, 'A1V', 8.6, 0.25, -1.46),
('Бетельгейзе (α Ориона)', (SELECT id FROM g WHERE name = 'Млечный Путь'), 18.5, 3500, 126000, 887, 'M1-2 Ia-Iab', 640, 0.01, 0.42),
('Проксима Центавра', (SELECT id FROM g WHERE name = 'Млечный Путь'), 0.12, 3042, 0.0017, 0.14, 'M5.5Ve', 4.24, 4.85, 11.13),
('Альфа Центавра A', (SELECT id FROM g WHERE name = 'Млечный Путь'), 1.01, 5790, 1.52, 1.22, 'G2V', 4.37, 5.3, -0.01),
('Вега (α Лиры)', (SELECT id FROM g WHERE name = 'Млечный Путь'), 2.01, 9602, 40, 2.36, 'A0Va', 25, 0.45, 0.03),
('Ригель (β Ориона)', (SELECT id FROM g WHERE name = 'Млечный Путь'), 21, 12100, 120000, 78, 'B8 Ia', 860, 0.008, 0.13),
('Арктур (α Волопаса)', (SELECT id FROM g WHERE name = 'Млечный Путь'), 1.08, 4286, 170, 25.4, 'K0 III', 37, 7.1, -0.05),
('Антарес (α Скорпиона)', (SELECT id FROM g WHERE name = 'Млечный Путь'), 12, 3570, 57500, 680, 'M1.5Iab-Ib', 550, 0.015, 1.06),
('Полярная звезда (α Малой Медведицы)', (SELECT id FROM g WHERE name = 'Млечный Путь'), 5.04, 6015, 2500, 37.5, 'F7Ib', 433, 0.07, 1.98),
('Процион (α Малого Пса)', (SELECT id FROM g WHERE name = 'Млечный Путь'), 1.5, 6530, 7, 2.0, 'F5IV-V', 11.4, 1.7, 0.34),
('Альдебаран (α Тельца)', (SELECT id FROM g WHERE name = 'Млечный Путь'), 1.7, 3910, 150, 44, 'K5III', 65, 6.4, 0.85),
('Спика (α Девы)', (SELECT id FROM g WHERE name = 'Млечный Путь'), 11, 25300, 21000, 7.5, 'B1V', 250, 0.12, 1.04),
('Поллукс (β Близнецов)', (SELECT id FROM g WHERE name = 'Млечный Путь'), 1.9, 4660, 32, 8.8, 'K0III', 34, 0.7, 1.14),
('Денеб (α Лебедя)', (SELECT id FROM g WHERE name = 'Млечный Путь'), 20, 8500, 196000, 200, 'A2Ia', 1400, 0.01, 1.25);

-- 4. Вставка planets
WITH s AS (SELECT id, name FROM stars)
INSERT INTO planets (name, star_id, planet_type, mass_earth, diameter_km, orbital_period_days, distance_from_star_au, surface_temperature_c, satellites_count, atmosphere_composition) VALUES
('Меркурий', (SELECT id FROM s WHERE name = 'Солнце'), 'Земная', 0.055, 4879, 88, 0.39, '-173 до 427', 0, 'Отсутствует'),
('Венера', (SELECT id FROM s WHERE name = 'Солнце'), 'Земная', 0.815, 12104, 225, 0.72, '462', 0, 'CO₂ (96.5%), N₂'),
('Земля', (SELECT id FROM s WHERE name = 'Солнце'), 'Земная', 1.0, 12742, 365.25, 1.0, '-88 до 58', 1, 'N₂ (78%), O₂ (21%)'),
('Марс', (SELECT id FROM s WHERE name = 'Солнце'), 'Земная', 0.107, 6779, 687, 1.52, '-153 до 20', 2, 'CO₂ (95%), N₂, Ar'),
('Юпитер', (SELECT id FROM s WHERE name = 'Солнце'), 'Газовый гигант', 317.8, 139820, 4333, 5.2, '-108', 95, 'H₂ (90%), He (10%)'),
('Сатурн', (SELECT id FROM s WHERE name = 'Солнце'), 'Газовый гигант', 95.2, 116460, 10759, 9.5, '-139', 146, 'H₂ (96%), He (3%)'),
('Уран', (SELECT id FROM s WHERE name = 'Солнце'), 'Ледяной гигант', 14.5, 50724, 30687, 19.2, '-197', 28, 'H₂, He, CH₄'),
('Нептун', (SELECT id FROM s WHERE name = 'Солнце'), 'Ледяной гигант', 17.1, 49244, 60190, 30.1, '-201', 16, 'H₂, He, CH₄'),
('Проксима Центавра b', (SELECT id FROM s WHERE name = 'Проксима Центавра'), 'Земная', 1.27, 13000, 11.2, 0.05, '-39', 0, 'Неизвестна'),
('HD 209458 b (Осирис)', (SELECT id FROM s WHERE name = 'Сириус (α Большого Пса)'), 'Газовый гигант', 0.69, 140000, 3.5, 0.047, '1000', 0, 'H₂, He, Na'),
('Kepler-22b', (SELECT id FROM s WHERE name = 'Альфа Центавра A'), 'Земная', 2.4, 24000, 290, 0.85, '22', 0, 'Неизвестна'),
('Kepler-452b', (SELECT id FROM s WHERE name = 'Альфа Центавра A'), 'Земная', 5.0, 28000, 385, 1.05, '10', 0, 'Неизвестна'),
('TRAPPIST-1e', (SELECT id FROM s WHERE name = 'Проксима Центавра'), 'Земная', 0.77, 11000, 6.1, 0.028, '-40', 0, 'Неизвестна'),
('55 Cancri e', (SELECT id FROM s WHERE name = 'Альфа Центавра A'), 'Земная', 8.6, 23000, 0.74, 0.015, '2000', 0, 'CO₂, H₂O'),
('GJ 1214 b', (SELECT id FROM s WHERE name = 'Проксима Центавра'), 'Земная', 6.5, 27000, 1.58, 0.014, '280', 0, 'H₂O, He');

-- 5. Вставка satellites
WITH p AS (SELECT id, name FROM planets)
INSERT INTO satellites (name, planet_id, satellite_type, diameter_km, mass_kg, orbital_period_days, distance_from_planet_km, temperature_c, discovery_year, discoverer) VALUES
('Луна', (SELECT id FROM p WHERE name = 'Земля'), 'Скалистый', 3474, '7.35×10²²', 27.3, 384400, '-173 до 127', NULL, '-'),
('Фобос', (SELECT id FROM p WHERE name = 'Марс'), 'Скалистый', 22.2, '1.07×10¹⁶', 0.32, 9377, '-4 до -112', 1877, 'Асаф Холл'),
('Деймос', (SELECT id FROM p WHERE name = 'Марс'), 'Скалистый', 12.6, '1.48×10¹⁵', 1.26, 23460, '-112', 1877, 'Асаф Холл'),
('Ио', (SELECT id FROM p WHERE name = 'Юпитер'), 'Скалистый', 3643, '8.93×10²²', 1.77, 421700, '-130 до 1600', 1610, 'Галилео Галилей'),
('Европа', (SELECT id FROM p WHERE name = 'Юпитер'), 'Ледяной', 3122, '4.80×10²²', 3.55, 671000, '-160', 1610, 'Галилео Галилей'),
('Ганимед', (SELECT id FROM p WHERE name = 'Юпитер'), 'Ледяной', 5268, '1.48×10²³', 7.15, 1070000, '-160', 1610, 'Галилео Галилей'),
('Каллисто', (SELECT id FROM p WHERE name = 'Юпитер'), 'Ледяной', 4821, '1.08×10²³', 16.69, 1883000, '-140', 1610, 'Галилео Галилей'),
('Амальтея', (SELECT id FROM p WHERE name = 'Юпитер'), 'Скалистый', 250, '2.08×10¹⁸', 0.50, 181400, '-120', 1892, 'Эдвард Барнард'),
('Фива', (SELECT id FROM p WHERE name = 'Юпитер'), 'Скалистый', 98, '4.3×10¹⁷', 0.67, 221900, '-130', 1979, 'Вояджер'),
('Титан', (SELECT id FROM p WHERE name = 'Сатурн'), 'Ледяной', 5150, '1.35×10²³', 15.95, 1221870, '-179', 1655, 'Христиан Гюйгенс'),
('Энцелад', (SELECT id FROM p WHERE name = 'Сатурн'), 'Ледяной', 504, '1.08×10²⁰', 1.37, 238000, '-198', 1789, 'Уильям Гершель'),
('Мимас', (SELECT id FROM p WHERE name = 'Сатурн'), 'Ледяной', 396, '3.75×10¹⁹', 0.94, 185400, '-200', 1789, 'Уильям Гершель'),
('Тефия', (SELECT id FROM p WHERE name = 'Сатурн'), 'Ледяной', 1060, '6.17×10²⁰', 1.89, 294600, '-187', 1684, 'Джованни Кассини'),
('Диона', (SELECT id FROM p WHERE name = 'Сатурн'), 'Ледяной', 1120, '1.10×10²¹', 2.74, 377400, '-186', 1684, 'Джованни Кассини'),
('Рея', (SELECT id FROM p WHERE name = 'Сатурн'), 'Ледяной', 1528, '2.31×10²¹', 4.52, 527000, '-174', 1672, 'Джованни Кассини'),
('Япет', (SELECT id FROM p WHERE name = 'Сатурн'), 'Ледяной', 1470, '1.81×10²¹', 79.33, 3561000, '-143', 1671, 'Джованни Кассини'),
('Феба', (SELECT id FROM p WHERE name = 'Сатурн'), 'Скалистый', 213, '8.3×10¹⁸', 548, 12952000, '-175', 1899, 'Уильям Пикеринг'),
('Титания', (SELECT id FROM p WHERE name = 'Уран'), 'Ледяной', 1578, '3.53×10²¹', 8.71, 436300, '-190', 1787, 'Уильям Гершель'),
('Оберон', (SELECT id FROM p WHERE name = 'Уран'), 'Ледяной', 1523, '3.01×10²¹', 13.46, 583500, '-190', 1787, 'Уильям Гершель'),
('Умбриэль', (SELECT id FROM p WHERE name = 'Уран'), 'Ледяной', 1169, '1.17×10²¹', 4.14, 266000, '-193', 1851, 'Уильям Лассел'),
('Ариэль', (SELECT id FROM p WHERE name = 'Уран'), 'Ледяной', 1158, '1.35×10²¹', 2.52, 190900, '-193', 1851, 'Уильям Лассел'),
('Миранда', (SELECT id FROM p WHERE name = 'Уран'), 'Скалистый', 472, '6.6×10¹⁹', 1.41, 129900, '-187', 1948, 'Джерард Койпер'),
('Тритон', (SELECT id FROM p WHERE name = 'Нептун'), 'Ледяной', 2707, '2.14×10²²', 5.88, 354759, '-235', 1846, 'Уильям Лассел'),
('Нереида', (SELECT id FROM p WHERE name = 'Нептун'), 'Скалистый', 340, '3.1×10¹⁹', 360.1, 5513800, '-222', 1949, 'Джерард Койпер'),
('Протей', (SELECT id FROM p WHERE name = 'Нептун'), 'Скалистый', 420, '5.0×10¹⁹', 1.12, 117647, '-222', 1989, 'Вояджер');

-- 6. Вставка small_bodies (астероиды, кометы, карликовые планеты)
INSERT INTO small_bodies (name, spk_id, designation, body_type, epoch_jd, eccentricity, semi_major_axis_au, perihelion_au, aphelion_au, inclination_deg, arg_periapsis_deg, long_asc_node_deg, mean_anomaly_deg, orbital_period_days, diameter_km, rotation_period_h, albedo, spectral_type, magnitude_h, discovery_date, discovery_site, discoverer, is_pha) VALUES
('1 Церера', '2000001', 'A801 AA', 'Dwarf Planet', 2459600.5, 0.0789, 2.7675, 2.5490, 2.9860, 10.594, 73.597, 80.305, 77.272, 1681.63, 939.4, 9.07, 0.090, 'C', 3.34, '1801-01-01', 'Палермо', 'Джузеппе Пьяцци', false),
('4 Веста', '2000004', 'A807 FA', 'Asteroid', 2459600.5, 0.0894, 2.3618, 2.1506, 2.5730, 7.143, 151.198, 103.851, 202.563, 1325.98, 525.4, 5.34, 0.423, 'V', 3.20, '1807-03-29', 'Бремен', 'Генрих Ольберс', false),
('433 Эрос', '2000433', '1898 DQ', 'Asteroid', 2459600.5, 0.2229, 1.4581, 1.1330, 1.7832, 10.828, 178.882, 304.368, 147.125, 643.08, 16.8, 5.27, 0.250, 'S', 11.16, '1898-08-13', 'Берлин', 'Карл Витт', false),
('99942 Апофис', '2099942', '2004 MN4', 'Asteroid', 2459600.5, 0.1910, 0.9220, 0.7460, 1.0980, 3.339, 126.590, 204.466, 63.915, 323.58, 0.370, 30.56, 0.230, 'Sq', 19.70, '2004-06-19', 'Китт-Пик', 'Рой Такер', true),
('1P/Галлея', '1000036', '1P/1682 Q1', 'Comet', 2459600.5, 0.9671, 17.8340, 0.5860, 35.0820, 162.262, 111.332, 58.420, 28.421, 27482.92, 11.0, 52.8, 0.040, 'Comet', 13.50, '1758-12-25', 'Лондон', 'Эдмунд Галлей', false),
('25143 Итокава', '2025143', '1998 SF36', 'Asteroid', 2459600.5, 0.2800, 1.3241, 0.9532, 1.6950, 1.621, 162.810, 69.082, 289.910, 556.08, 0.330, 12.13, 0.280, 'S', 19.20, '1998-09-26', 'Сокорро', 'LINEAR', true),
('2 Паллада', '2000002', 'A802 FA', 'Asteroid', 2459600.5, 0.2302, 2.7726, 2.1344, 3.4108, 34.841, 310.048, 173.057, 225.151, 1683.97, 512.0, 7.81, 0.101, 'B', 4.13, '1802-03-28', 'Бремен', 'Генрих Ольберс', false),
('67P/Чурюмова-Герасименко', '1000012', '67P/1969 R1', 'Comet', 2459600.5, 0.6410, 3.4628, 1.2432, 5.6824, 7.041, 12.780, 50.142, 53.979, 2354.21, 4.0, 12.40, 0.065, 'Comet', 15.40, '1969-09-11', 'Алма-Ата', 'Клим Чурюмов', false);

-- 7. Вставка feature_flags
INSERT INTO feature_flags (flag_name, is_enabled, description) VALUES
('ENABLE_PLANETS_MODULE', true, 'Включает функциональность работы с планетами (CRUD операции)'),
('ENABLE_ADVANCED_SEARCH', false, 'Включает расширенный поиск по химическому составу звезд'),
('ENABLE_STATISTICS', true, 'Включает сбор и отображение статистики по типам галактик'),
('ENABLE_EXOPLANETS', true, 'Включает отображение экзопланет'),
('ENABLE_SATELLITES_MODULE', true, 'Включает функциональность работы со спутниками'),
('ENABLE_SMALL_BODIES_MODULE', true, 'Включает функциональность работы с малыми телами')
ON CONFLICT (flag_name) DO UPDATE SET
    is_enabled = EXCLUDED.is_enabled,
    description = EXCLUDED.description,
    updated_at = CURRENT_TIMESTAMP;

-- 8. Вставка users
INSERT INTO users (username, password_hash, email, role, created_at) VALUES
('admin', '$2b$10$5zZM5kZ5tV5Z5tV5Z5tV5u', 'admin@astronomy.org', 'admin', CURRENT_TIMESTAMP),
('astronomer', '$2b$10$5zZM5kZ5tV5Z5tV5Z5tV5u', 'astronomer@astronomy.org', 'user', CURRENT_TIMESTAMP),
('researcher', '$2b$10$5zZM5kZ5tV5Z5tV5Z5tV5u', 'researcher@astronomy.org', 'user', CURRENT_TIMESTAMP),
('student', '$2b$10$5zZM5kZ5tV5Z5tV5Z5tV5u', 'student@astronomy.org', 'user', CURRENT_TIMESTAMP)
ON CONFLICT (username) DO NOTHING;

-- 9. Обновление satellite_counts в planets
UPDATE planets p
SET satellites_count = (
    SELECT COUNT(*)
    FROM satellites s
    WHERE s.planet_id = p.id
);

-- =====================================================
-- Создание триггеров для аудита
-- =====================================================
DROP TRIGGER IF EXISTS trigger_audit_galaxies ON galaxies;
CREATE TRIGGER trigger_audit_galaxies
    AFTER INSERT OR UPDATE OR DELETE ON galaxies
    FOR EACH ROW EXECUTE FUNCTION log_audit();

DROP TRIGGER IF EXISTS trigger_audit_stars ON stars;
CREATE TRIGGER trigger_audit_stars
    AFTER INSERT OR UPDATE OR DELETE ON stars
    FOR EACH ROW EXECUTE FUNCTION log_audit();

DROP TRIGGER IF EXISTS trigger_audit_planets ON planets;
CREATE TRIGGER trigger_audit_planets
    AFTER INSERT OR UPDATE OR DELETE ON planets
    FOR EACH ROW EXECUTE FUNCTION log_audit();

DROP TRIGGER IF EXISTS trigger_audit_satellites ON satellites;
CREATE TRIGGER trigger_audit_satellites
    AFTER INSERT OR UPDATE OR DELETE ON satellites
    FOR EACH ROW EXECUTE FUNCTION log_audit();

DROP TRIGGER IF EXISTS trigger_audit_small_bodies ON small_bodies;
CREATE TRIGGER trigger_audit_small_bodies
    AFTER INSERT OR UPDATE OR DELETE ON small_bodies
    FOR EACH ROW EXECUTE FUNCTION log_audit();

DROP TRIGGER IF EXISTS trigger_audit_galaxy_types ON galaxy_types;
CREATE TRIGGER trigger_audit_galaxy_types
    AFTER INSERT OR UPDATE OR DELETE ON galaxy_types
    FOR EACH ROW EXECUTE FUNCTION log_audit();

-- =====================================================
-- Проверочные запросы
-- =====================================================
SELECT 'galaxy_types' as table_name, COUNT(*) as count FROM galaxy_types
UNION ALL
SELECT 'galaxies', COUNT(*) FROM galaxies
UNION ALL
SELECT 'stars', COUNT(*) FROM stars
UNION ALL
SELECT 'planets', COUNT(*) FROM planets
UNION ALL
SELECT 'satellites', COUNT(*) FROM satellites
UNION ALL
SELECT 'small_bodies', COUNT(*) FROM small_bodies
UNION ALL
SELECT 'feature_flags', COUNT(*) FROM feature_flags
UNION ALL
SELECT 'users', COUNT(*) FROM users;