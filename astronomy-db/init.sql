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
-- Создано на основе дизайн-документа и предоставленных данных
-- =====================================================

-- Создание базы данных (выполнять отдельно, если БД еще не создана)
-- CREATE DATABASE astronomy_catalog;
-- \c astronomy_catalog;

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

COMMENT ON TABLE galaxy_types IS 'Типы галактик с их характеристиками';
COMMENT ON COLUMN galaxy_types.id IS 'Уникальный идентификатор типа галактики';
COMMENT ON COLUMN galaxy_types.name IS 'Название типа (Эллиптическая, Спиральная и т.д.)';
COMMENT ON COLUMN galaxy_types.description IS 'Общее описание типа галактик';
COMMENT ON COLUMN galaxy_types.structure_shape IS 'Структура и форма галактик';
COMMENT ON COLUMN galaxy_types.stellar_population IS 'Звездное население';
COMMENT ON COLUMN galaxy_types.star_formation IS 'Активность звездообразования';
COMMENT ON COLUMN galaxy_types.size_mass IS 'Размер и масса';
COMMENT ON COLUMN galaxy_types.color IS 'Цветовые характеристики';
COMMENT ON COLUMN galaxy_types.spatial_distribution IS 'Распределение в пространстве';
COMMENT ON COLUMN galaxy_types.origin IS 'Происхождение и эволюция';

-- =====================================================
-- 2. Таблица: galaxies (Галактики)
-- =====================================================
DROP TABLE IF EXISTS galaxies CASCADE;
CREATE TABLE galaxies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    galaxy_type_id INTEGER REFERENCES galaxy_types(id) ON DELETE SET NULL,
    diameter_ly BIGINT,                    -- Диаметр в световых годах
    star_count VARCHAR(50),                -- Количество звезд (с округлением)
    mass_solar_masses VARCHAR(50),         -- Масса в солнечных массах
    distance_from_earth_ly BIGINT,         -- Расстояние от Земли в световых годах
    age_billion_years NUMERIC(5,2),        -- Возраст в миллиардах лет
    metallicity VARCHAR(50),               -- Металличность
    rotation_speed_kms INTEGER,            -- Скорость вращения (км/с)
    discovery_year INTEGER                 -- Год открытия
);

COMMENT ON TABLE galaxies IS 'Каталог галактик';
COMMENT ON COLUMN galaxies.id IS 'Уникальный идентификатор галактики';
COMMENT ON COLUMN galaxies.name IS 'Название галактики';
COMMENT ON COLUMN galaxies.galaxy_type_id IS 'Ссылка на тип галактики';
COMMENT ON COLUMN galaxies.diameter_ly IS 'Диаметр в световых годах';
COMMENT ON COLUMN galaxies.star_count IS 'Количество звезд';
COMMENT ON COLUMN galaxies.mass_solar_masses IS 'Масса в солнечных массах';
COMMENT ON COLUMN galaxies.distance_from_earth_ly IS 'Расстояние от Земли в световых годах';
COMMENT ON COLUMN galaxies.age_billion_years IS 'Возраст в миллиардах лет';
COMMENT ON COLUMN galaxies.metallicity IS 'Металличность (высокая, средняя, низкая)';
COMMENT ON COLUMN galaxies.rotation_speed_kms IS 'Скорость вращения в км/с';
COMMENT ON COLUMN galaxies.discovery_year IS 'Год открытия';

-- =====================================================
-- 3. Таблица: stars (Звезды)
-- =====================================================
DROP TABLE IF EXISTS stars CASCADE;
CREATE TABLE stars (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    galaxy_id INTEGER REFERENCES galaxies(id) ON DELETE CASCADE,
    mass_solar NUMERIC(10,2),              -- Масса в массах Солнца
    temperature_k INTEGER,                 -- Температура в Кельвинах
    luminosity_solar NUMERIC(20,2),        -- Светимость в светимостях Солнца
    radius_solar NUMERIC(10,2),            -- Радиус в радиусах Солнца
    spectral_class VARCHAR(20),            -- Спектральный класс
    distance_from_sun_ly NUMERIC(15,2),    -- Расстояние от Солнца в световых годах
    age_billion_years NUMERIC(10,2),       -- Возраст в миллиардах лет
    apparent_magnitude NUMERIC(10,2)       -- Видимая звездная величина
);

COMMENT ON TABLE stars IS 'Каталог звезд';
COMMENT ON COLUMN stars.id IS 'Уникальный идентификатор звезды';
COMMENT ON COLUMN stars.name IS 'Название звезды';
COMMENT ON COLUMN stars.galaxy_id IS 'Ссылка на галактику';
COMMENT ON COLUMN stars.mass_solar IS 'Масса в массах Солнца';
COMMENT ON COLUMN stars.temperature_k IS 'Температура поверхности в Кельвинах';
COMMENT ON COLUMN stars.luminosity_solar IS 'Светимость в светимостях Солнца';
COMMENT ON COLUMN stars.radius_solar IS 'Радиус в радиусах Солнца';
COMMENT ON COLUMN stars.spectral_class IS 'Спектральный класс (G2V, M5.5Ve и т.д.)';
COMMENT ON COLUMN stars.distance_from_sun_ly IS 'Расстояние от Солнца в световых годах';
COMMENT ON COLUMN stars.age_billion_years IS 'Возраст в миллиардах лет';
COMMENT ON COLUMN stars.apparent_magnitude IS 'Видимая звездная величина';

-- =====================================================
-- 4. Таблица: planets (Планеты)
-- =====================================================
DROP TABLE IF EXISTS planets CASCADE;
CREATE TABLE planets (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    star_id INTEGER REFERENCES stars(id) ON DELETE CASCADE,
    planet_type VARCHAR(50),               -- Тип планеты (Земная, Газовый гигант, Ледяной гигант)
    mass_earth NUMERIC(10,2),              -- Масса в массах Земли
    diameter_km INTEGER,                   -- Диаметр в километрах
    orbital_period_days NUMERIC(10,2),     -- Период обращения в днях
    distance_from_star_au NUMERIC(10,4),   -- Расстояние от звезды в а.е.
    surface_temperature_c VARCHAR(50),     -- Температура поверхности (°C)
    satellites_count INTEGER,              -- Количество спутников
    atmosphere_composition TEXT            -- Состав атмосферы
);

COMMENT ON TABLE planets IS 'Каталог планет';
COMMENT ON COLUMN planets.id IS 'Уникальный идентификатор планеты';
COMMENT ON COLUMN planets.name IS 'Название планеты';
COMMENT ON COLUMN planets.star_id IS 'Ссылка на звезду';
COMMENT ON COLUMN planets.planet_type IS 'Тип планеты';
COMMENT ON COLUMN planets.mass_earth IS 'Масса в массах Земли';
COMMENT ON COLUMN planets.diameter_km IS 'Диаметр в километрах';
COMMENT ON COLUMN planets.orbital_period_days IS 'Период обращения в днях';
COMMENT ON COLUMN planets.distance_from_star_au IS 'Расстояние от звезды в астрономических единицах';
COMMENT ON COLUMN planets.surface_temperature_c IS 'Температура поверхности в градусах Цельсия';
COMMENT ON COLUMN planets.satellites_count IS 'Количество спутников';
COMMENT ON COLUMN planets.atmosphere_composition IS 'Состав атмосферы';

-- =====================================================
-- 5. Таблица: satellites (Спутники)
-- =====================================================
DROP TABLE IF EXISTS satellites CASCADE;
CREATE TABLE satellites (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    planet_id INTEGER REFERENCES planets(id) ON DELETE CASCADE,
    satellite_type VARCHAR(50),            -- Тип спутника (Скалистый, Ледяной и т.д.)
    diameter_km NUMERIC(10,2),             -- Диаметр в километрах
    mass_kg VARCHAR(50),                   -- Масса в килограммах
    orbital_period_days NUMERIC(10,2),     -- Период обращения в днях
    distance_from_planet_km INTEGER,       -- Расстояние от планеты в километрах
    temperature_c VARCHAR(50),             -- Температура поверхности (°C)
    discovery_year INTEGER,                -- Год открытия
    discoverer VARCHAR(200)                -- Первооткрыватель
);

COMMENT ON TABLE satellites IS 'Каталог спутников планет';
COMMENT ON COLUMN satellites.id IS 'Уникальный идентификатор спутника';
COMMENT ON COLUMN satellites.name IS 'Название спутника';
COMMENT ON COLUMN satellites.planet_id IS 'Ссылка на планету';
COMMENT ON COLUMN satellites.satellite_type IS 'Тип спутника';
COMMENT ON COLUMN satellites.diameter_km IS 'Диаметр в километрах';
COMMENT ON COLUMN satellites.mass_kg IS 'Масса в килограммах';
COMMENT ON COLUMN satellites.orbital_period_days IS 'Период обращения в днях';
COMMENT ON COLUMN satellites.distance_from_planet_km IS 'Расстояние от планеты в километрах';
COMMENT ON COLUMN satellites.temperature_c IS 'Температура поверхности';
COMMENT ON COLUMN satellites.discovery_year IS 'Год открытия';
COMMENT ON COLUMN satellites.discoverer IS 'Первооткрыватель';

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

COMMENT ON TABLE feature_flags IS 'Флаги функций для управления доступом к возможностям';

-- =====================================================
-- 7. Таблица: users (Пользователи) - для безопасности
-- =====================================================
DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    role VARCHAR(50) DEFAULT 'user',       -- 'admin' или 'user'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

COMMENT ON TABLE users IS 'Пользователи системы';
COMMENT ON COLUMN users.role IS 'Роль пользователя: admin или user';

-- =====================================================
-- 8. Таблица: audit_log (Журнал действий)
-- =====================================================
DROP TABLE IF EXISTS audit_log CASCADE;
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100),                   -- INSERT, UPDATE, DELETE, SELECT
    table_name VARCHAR(100),
    record_id INTEGER,
    old_data JSONB,
    new_data JSONB,
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET
);

COMMENT ON TABLE audit_log IS 'Журнал аудита действий пользователей';

-- =====================================================
-- Создание индексов для оптимизации запросов
-- =====================================================

-- Индексы для galaxies
CREATE INDEX idx_galaxies_name ON galaxies(name);
CREATE INDEX idx_galaxies_type_id ON galaxies(galaxy_type_id);
CREATE INDEX idx_galaxies_distance ON galaxies(distance_from_earth_ly);
CREATE INDEX idx_galaxies_discovery_year ON galaxies(discovery_year);

-- Индексы для stars
CREATE INDEX idx_stars_name ON stars(name);
CREATE INDEX idx_stars_galaxy_id ON stars(galaxy_id);
CREATE INDEX idx_stars_spectral_class ON stars(spectral_class);
CREATE INDEX idx_stars_distance ON stars(distance_from_sun_ly);

-- Индексы для planets
CREATE INDEX idx_planets_name ON planets(name);
CREATE INDEX idx_planets_star_id ON planets(star_id);
CREATE INDEX idx_planets_type ON planets(planet_type);

-- Индексы для satellites
CREATE INDEX idx_satellites_name ON satellites(name);
CREATE INDEX idx_satellites_planet_id ON satellites(planet_id);
CREATE INDEX idx_satellites_discovery_year ON satellites(discovery_year);

-- Составные индексы
CREATE INDEX idx_stars_galaxy_class ON stars(galaxy_id, spectral_class);
CREATE INDEX idx_planets_star_type ON planets(star_id, planet_type);

-- =====================================================
-- Создание представлений для удобных запросов
-- =====================================================

-- Представление: полная информация о галактиках с типами
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

COMMENT ON VIEW view_galaxies_full IS 'Полная информация о галактиках с описанием типов';

-- Представление: звезды с информацией о галактиках
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

COMMENT ON VIEW view_stars_full IS 'Полная информация о звездах с количеством планет';

-- Представление: планеты с информацией о звездах
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

COMMENT ON VIEW view_planets_full IS 'Полная информация о планетах с привязкой к звездам';

-- Представление: спутники с информацией о планетах
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

COMMENT ON VIEW view_satellites_full IS 'Полная информация о спутниках с привязкой к планетам';

-- =====================================================
-- Функции для работы с feature_flags
-- =====================================================

-- Функция проверки состояния feature flag
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

-- Функция включения feature flag
CREATE OR REPLACE FUNCTION enable_feature(flag_name_param VARCHAR, description_param TEXT DEFAULT NULL)
RETURNS VOID AS $$
BEGIN
    INSERT INTO feature_flags (flag_name, is_enabled, description, updated_at)
    VALUES (flag_name_param, true, description_param, CURRENT_TIMESTAMP)
    ON CONFLICT (flag_name) 
    DO UPDATE SET is_enabled = true, updated_at = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- Функция отключения feature flag
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
        current_setting('app.current_user_id', true)::INTEGER,
        TG_OP,
        TG_TABLE_NAME,
        NEW.id,
        CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE NULL END,
        CASE WHEN TG_OP = 'INSERT' THEN to_jsonb(NEW) 
             WHEN TG_OP = 'UPDATE' THEN to_jsonb(NEW) 
             ELSE NULL END
    );
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;