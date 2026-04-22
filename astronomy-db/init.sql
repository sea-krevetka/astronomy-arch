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
-- База данных: astronomy_catalog
-- Описание: Каталог галактик, звезд, планет и спутников
-- =====================================================

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
-- 6. Таблица: feature_flags (Функциональные флаги)
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
-- 7. Таблица: users (Пользователи) - для безопасности
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
-- 8. Таблица: audit_log (Журнал действий)
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
-- Создание индексов для оптимизации запросов
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

CREATE INDEX idx_stars_galaxy_class ON stars(galaxy_id, spectral_class);
CREATE INDEX idx_planets_star_type ON planets(star_id, planet_type);

-- =====================================================
-- Создание представлений для удобных запросов
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
-- ВСТАВКА ДАННЫХ (с использованием CTE для получения ID)
-- =====================================================

-- 1. Вставка galaxy_types
INSERT INTO galaxy_types (name, description, structure_shape, stellar_population, star_formation, size_mass, color, spatial_distribution, origin) VALUES
('Эллиптическая', 'Звездные системы эллипсоидной формы...', 'Форма от круглой до сильно вытянутой', 'Старые звезды', 'Отсутствует', '1-200 кпк, 10^6-10^12 M☉', 'Красноватый', 'В центрах скоплений', 'Слияния галактик'),
('Линзовидная', 'Промежуточный тип между эллиптическими и спиральными', 'Дисковая структура без рукавов', 'Старые звезды', 'Отсутствует', 'Схожи со спиральными', 'Красновато-желтый', 'В скоплениях', 'Бывшие спиральные'),
('Спиральная', 'Дисковые галактики со спиральными рукавами', 'Плоский диск + сферическое гало', 'Смешанное', 'Активное', '20-150 кпк, 10^9-10^12 M☉', 'Голубовато-белый', 'Вне центров скоплений', 'Из газовых облаков'),
('Спиральная с перемычкой', 'Спиральные с баром через центр', 'Бар + спиральные рукава', 'Смешанное', 'Активное', 'Аналогичны спиральным', 'Перемычка желтая, рукава голубые', '>50% спиральных', 'Динамическая неустойчивость'),
('Неправильная', 'Без четкой структуры', 'Аморфная форма', 'Молодые звезды', 'Очень активное', 'До 50 кпк, до 10^10 M☉', 'Голубоватый', 'Повсеместно', 'Гравитационные возмущения');

-- 2. Вставка galaxies (используем подзапросы, но сначала вставляем galaxy_types)
WITH gt AS (SELECT id, name FROM galaxy_types)
INSERT INTO galaxies (name, galaxy_type_id, diameter_ly, star_count, mass_solar_masses, distance_from_earth_ly, age_billion_years, metallicity, rotation_speed_kms, discovery_year) VALUES
('Млечный Путь', (SELECT id FROM gt WHERE name = 'Спиральная с перемычкой'), 100000, '100-400 млрд', '1-2 трлн', 0, 13.6, 'Высокая', 220, 1610),
('Андромеда (M31)', (SELECT id FROM gt WHERE name = 'Спиральная'), 220000, '~1 трлн', '1.5 трлн', 2500000, 10.0, 'Средняя', 250, 964),
('Треугольник (M33)', (SELECT id FROM gt WHERE name = 'Спиральная'), 60000, '~40 млрд', '10-40 млрд', 3000000, 8.0, 'Низкая', 100, 1654),
('Болид (NGC 6822)', (SELECT id FROM gt WHERE name = 'Неправильная'), 7000, '~10 млн', '140 млн', 1600000, 5.0, 'Очень низкая', 57, 1884),
('Водоворот (M51)', (SELECT id FROM gt WHERE name = 'Спиральная'), 76000, '~160 млрд', '160 млрд', 23000000, 7.0, 'Средняя', 210, 1773);

-- 3. Вставка stars
WITH g AS (SELECT id FROM galaxies WHERE name = 'Млечный Путь')
INSERT INTO stars (name, galaxy_id, mass_solar, temperature_k, luminosity_solar, radius_solar, spectral_class, distance_from_sun_ly, age_billion_years, apparent_magnitude) VALUES
('Солнце', (SELECT id FROM g), 1.0, 5778, 1.0, 1.0, 'G2V', 0, 4.6, -26.74),
('Сириус', (SELECT id FROM g), 2.02, 9940, 25.4, 1.71, 'A1V', 8.6, 0.25, -1.46),
('Бетельгейзе', (SELECT id FROM g), 18.5, 3500, 126000, 887, 'M1-2 Ia-Iab', 640, 0.01, 0.42),
('Проксима Центавра', (SELECT id FROM g), 0.12, 3042, 0.0017, 0.14, 'M5.5Ve', 4.24, 4.85, 11.13),
('Альфа Центавра A', (SELECT id FROM g), 1.01, 5790, 1.52, 1.22, 'G2V', 4.37, 5.3, -0.01);

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
('Проксима Центавра b', (SELECT id FROM s WHERE name = 'Проксима Центавра'), 'Земная', 1.27, 13000, 11.2, 0.05, '-39', 0, 'Неизвестна');

-- 5. Вставка satellites
WITH p AS (SELECT id, name FROM planets)
INSERT INTO satellites (name, planet_id, satellite_type, diameter_km, mass_kg, orbital_period_days, distance_from_planet_km, temperature_c, discovery_year, discoverer) VALUES
('Луна', (SELECT id FROM p WHERE name = 'Земля'), 'Скалистый', 3474, '7.35e22', 27.3, 384400, '-173 до 127', NULL, NULL),
('Фобос', (SELECT id FROM p WHERE name = 'Марс'), 'Скалистый', 22.2, '1.07e16', 0.32, 9377, '-4 до -112', 1877, 'Асаф Холл'),
('Деймос', (SELECT id FROM p WHERE name = 'Марс'), 'Скалистый', 12.6, '1.48e15', 1.26, 23460, '-112', 1877, 'Асаф Холл'),
('Ио', (SELECT id FROM p WHERE name = 'Юпитер'), 'Скалистый', 3643, '8.93e22', 1.77, 421700, '-130 до 1600', 1610, 'Галилео Галилей'),
('Европа', (SELECT id FROM p WHERE name = 'Юпитер'), 'Ледяной', 3122, '4.80e22', 3.55, 671000, '-160', 1610, 'Галилео Галилей'),
('Ганимед', (SELECT id FROM p WHERE name = 'Юпитер'), 'Ледяной', 5268, '1.48e23', 7.15, 1070000, '-160', 1610, 'Галилео Галилей'),
('Каллисто', (SELECT id FROM p WHERE name = 'Юпитер'), 'Ледяной', 4821, '1.08e23', 16.69, 1883000, '-140', 1610, 'Галилео Галилей'),
('Титан', (SELECT id FROM p WHERE name = 'Сатурн'), 'Ледяной', 5150, '1.35e23', 15.95, 1221870, '-179', 1655, 'Христиан Гюйгенс'),
('Энцелад', (SELECT id FROM p WHERE name = 'Сатурн'), 'Ледяной', 504, '1.08e20', 1.37, 238000, '-198', 1789, 'Уильям Гершель'),
('Тритон', (SELECT id FROM p WHERE name = 'Нептун'), 'Ледяной', 2707, '2.14e22', 5.88, 354759, '-235', 1846, 'Уильям Лассел');

-- 6. Вставка feature_flags
INSERT INTO feature_flags (flag_name, is_enabled, description) VALUES
('ENABLE_PLANETS_MODULE', true, 'Включает функциональность работы с планетами'),
('ENABLE_ADVANCED_SEARCH', false, 'Включает расширенный поиск'),
('ENABLE_STATISTICS', true, 'Включает сбор статистики'),
('ENABLE_EXOPLANETS', true, 'Включает отображение экзопланет'),
('ENABLE_SATELLITES_MODULE', true, 'Включает функциональность работы со спутниками')
ON CONFLICT (flag_name) DO UPDATE SET
    is_enabled = EXCLUDED.is_enabled,
    description = EXCLUDED.description,
    updated_at = CURRENT_TIMESTAMP;

-- 7. Вставка users
INSERT INTO users (username, password_hash, email, role, created_at) VALUES
('admin', '$2b$10$5zZM5kZ5tV5Z5tV5Z5tV5u', 'admin@astronomy.org', 'admin', CURRENT_TIMESTAMP),
('astronomer', '$2b$10$5zZM5kZ5tV5Z5tV5Z5tV5u', 'astronomer@astronomy.org', 'user', CURRENT_TIMESTAMP)
ON CONFLICT (username) DO NOTHING;

-- 8. Обновление satellite_counts в planets
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
SELECT 'feature_flags', COUNT(*) FROM feature_flags
UNION ALL
SELECT 'users', COUNT(*) FROM users;