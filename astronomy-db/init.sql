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



-- =====================================================
-- ВСТАВКА ДАННЫХ В ТАБЛИЦЫ
-- =====================================================

-- 1. Вставка данных в galaxy_types
-- =====================================================
INSERT INTO galaxy_types (id, name, description, structure_shape, stellar_population, star_formation, size_mass, color, spatial_distribution, origin) VALUES
(1, 'Эллиптическая', 
 'Звездные системы эллипсоидной формы, содержащие старые желтые/красные звезды, практически лишенные газа и пыли, из-за чего в них прекращено звездообразование. Они не имеют спиральных рукавов, характеризуются гладкой структурой и низкой скоростью вращения. Это самые крупные и самые маленькие системы во Вселенной, часто встречающиеся в центрах скоплений.',
 'Имеют форму от круглой (E0) до сильно вытянутой (E7), где число указывает на степень сжатия. Газ и пыль практически отсутствуют, поэтому межзвездная среда разряжена.',
 'В основном старые звезды поздних спектральных классов (G, K, M). Возраст звездного населения составляет около 10^10 лет.',
 'Активные процессы формирования новых звезд отсутствуют.',
 'Диаметр варьируется от нескольких тысяч до сотен тысяч световых лет, масса — от 10^5 до 10^13 солнечных.',
 'Ядро часто имеет ярко-желтый или красный оттенок, а ближе к периферии цвет становится более голубым.',
 'Часто составляют большинство галактик в плотных скоплениях.',
 'Существует мнение, что эллиптические галактики образуются в результате столкновений и слияний спиральных галактик, при которых газ быстро расходуется или выбрасывается, а звездные орбиты перемешиваются.'),

(2, 'Линзовидная',
 'Промежуточный тип между эллиптическими и спиральными. Имеют диск и яркое ядро (балдж), как спиральные, но лишены спиральных рукавов и содержат очень мало газа и пыли.',
 'Дисковая структура без рукавов. Может присутствовать слабая пылевая полоса. Классифицируются как S0 или SB0 (если есть бар).',
 'Преимущественно старые звезды, так как газ для рождения новых исчерпан.',
 'Отсутствует или крайне слабое.',
 'Схожи со спиральными галактиками.',
 'Красновато-желтый цвет, так как нет молодых голубых звезд.',
 'Часто встречаются в скоплениях галактик.',
 'Вероятно, являются бывшими спиральными галактиками, которые потеряли или исчерпали свой межзвездный газ.'),

(3, 'Спиральная',
 'Дисковые галактики с ярко выраженными спиральными рукавами, отходящими непосредственно от центрального ядра (балджа). Содержат много газа и пыли, обладают быстрым вращением.',
 'Состоят из плоского вращающегося диска (спиральные рукава) и сферического гало. Рукава классифицируются по плотности упаковки: Sa (плотные, гладкие), Sb, Sc (рыхлые, клочковатые).',
 'Смешанное: в балдже и гало — старые звезды, в диске и рукавах — молодые горячие звезды.',
 'Очень активное, особенно в спиральных рукавах, где сконцентрирован газ.',
 'Диаметр от 20 000 до 150 000 световых лет. Масса от 10^9 до 10^12 солнечных масс.',
 'Ядро желто-оранжевое, рукава голубовато-белые из-за обилия горячих молодых звезд.',
 'Предпочитают области с меньшей плотностью, редко встречаются в центрах богатых скоплений.',
 'Формируются из гигантских облаков первичного газа. Спиральная структура поддерживается волнами плотности.'),

(4, 'Спиральная с перемычкой',
 'Подтип спиральных галактик, отличающийся наличием яркой звездной перемычки (бара), проходящей через центр. Спиральные рукава начинаются не от ядра, а от концов этой перемычки.',
 'Характерная структура: центральный балдж, пересеченный линейным баром, от которого закручиваются спиральные рукава. Классификация: SBa (плотные рукава), SBb, SBc (рыхлые).',
 'Смешанное. Старые звезды преобладают в балдже и баре. Молодые звезды — в рукавах.',
 'Очень активное. Бар играет ключевую роль, направляя потоки газа в центр, что часто провоцирует вспышки звездообразования.',
 'Аналогичны обычным спиральным галактикам.',
 'Перемычка имеет желтоватый цвет (старые звезды), рукава — голубоватый (молодые звезды).',
 'Составляют более половины всех спиральных галактик (например, Млечный Путь).',
 'Бар образуется в результате динамической неустойчивости вращающегося звездного диска.'),

(5, 'Неправильная',
 'Галактики, не имеющие четко выраженной структуры (ни эллиптической, ни спиральной). Часто хаотичной, клочковатой формы.',
 'Отсутствуют ядро и правильные симметричные формы. Делятся на два подтипа: Irr I (с признаками структуры, например, обрывки рукавов) и Irr II (полностью хаотичная форма). Содержат много газа и пыли.',
 'Много молодых горячих звезд (население I), но также присутствуют и старые.',
 'Очень активное, часто вспыхивающее на всей площади галактики.',
 'Как правило, карликовые, меньше спиральных. Диаметр до 50 000 световых лет. Масса до 10^10 солнечных масс.',
 'Голубоватый цвет из-за обилия молодых звезд.',
 'Распространены повсеместно, но избегают центральных частей скоплений.',
 'Малые неправильные (Irr I) могут быть строительными блоками для более крупных галактик. Крупные неправильные (Irr II) часто образуются в результате гравитационных возмущений.')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    structure_shape = EXCLUDED.structure_shape,
    stellar_population = EXCLUDED.stellar_population,
    star_formation = EXCLUDED.star_formation,
    size_mass = EXCLUDED.size_mass,
    color = EXCLUDED.color,
    spatial_distribution = EXCLUDED.spatial_distribution,
    origin = EXCLUDED.origin;

-- 2. Вставка данных в galaxies
-- =====================================================
INSERT INTO galaxies (id, name, galaxy_type_id, diameter_ly, star_count, mass_solar_masses, distance_from_earth_ly, age_billion_years, metallicity, rotation_speed_kms, discovery_year) VALUES
(1, 'Млечный Путь', 4, 100000, '100-400 млрд', '1-2 трлн', 0, 13.6, 'Высокая', 220, 1610),
(2, 'Андромеда (M31)', 3, 220000, '~1 трлн', '1.5 трлн', 2500000, 10.0, 'Средняя', 250, 964),
(3, 'Треугольник (M33)', 3, 60000, '~40 млрд', '10-40 млрд', 3000000, 8.0, 'Низкая', 100, 1654),
(4, 'Болид (NGC 6822)', 5, 7000, '~10 млн', '140 млн', 1600000, 5.0, 'Очень низкая', 57, 1884),
(5, 'Водоворот (M51)', 3, 76000, '~160 млрд', '160 млрд', 23000000, 7.0, 'Средняя', 210, 1773),
(6, 'Сомбреро (M104)', 3, 50000, '~800 млрд', '800 млрд', 28000000, 11.0, 'Высокая', 340, 1781),
(7, 'Большое Магелланово Облако', 5, 14000, '~30 млрд', '10 млрд', 163000, 3.0, 'Низкая', 90, 964),
(8, 'Малое Магелланово Облако', 5, 7000, '~3 млрд', '7 млрд', 200000, 2.5, 'Низкая', 60, 964),
(9, 'Центавр A (NGC 5128)', 1, 60000, '~200 млрд', '1 трлн', 12000000, 12.0, 'Средняя', 220, 1826),
(10, 'Вертушка (M101)', 3, 170000, '~1 трлн', '100 млрд', 21000000, 8.5, 'Средняя', 150, 1781)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    galaxy_type_id = EXCLUDED.galaxy_type_id,
    diameter_ly = EXCLUDED.diameter_ly,
    star_count = EXCLUDED.star_count,
    mass_solar_masses = EXCLUDED.mass_solar_masses,
    distance_from_earth_ly = EXCLUDED.distance_from_earth_ly,
    age_billion_years = EXCLUDED.age_billion_years,
    metallicity = EXCLUDED.metallicity,
    rotation_speed_kms = EXCLUDED.rotation_speed_kms,
    discovery_year = EXCLUDED.discovery_year;

-- 3. Вставка данных в stars
-- =====================================================
INSERT INTO stars (id, name, galaxy_id, mass_solar, temperature_k, luminosity_solar, radius_solar, spectral_class, distance_from_sun_ly, age_billion_years, apparent_magnitude) VALUES
(1, 'Солнце', 1, 1.0, 5778, 1.0, 1.0, 'G2V', 0, 4.6, -26.74),
(2, 'Сириус (α Большого Пса)', 1, 2.02, 9940, 25.4, 1.71, 'A1V', 8.6, 0.25, -1.46),
(3, 'Бетельгейзе (α Ориона)', 1, 18.5, 3500, 126000, 887, 'M1-2 Ia-Iab', 640, 0.01, 0.42),
(4, 'Проксима Центавра', 1, 0.12, 3042, 0.0017, 0.14, 'M5.5Ve', 4.24, 4.85, 11.13),
(5, 'Альфа Центавра A', 1, 1.01, 5790, 1.52, 1.22, 'G2V', 4.37, 5.3, -0.01),
(6, 'Вега (α Лиры)', 1, 2.01, 9602, 40, 2.36, 'A0Va', 25, 0.45, 0.03),
(7, 'Ригель (β Ориона)', 1, 21, 12100, 120000, 78, 'B8 Ia', 860, 0.008, 0.13),
(8, 'Арктур (α Волопаса)', 1, 1.08, 4286, 170, 25.4, 'K0 III', 37, 7.1, -0.05),
(9, 'Антарес (α Скорпиона)', 1, 12, 3570, 57500, 680, 'M1.5Iab-Ib', 550, 0.015, 1.06),
(10, 'Полярная звезда (α Малой Медведицы)', 1, 5.04, 6015, 2500, 37.5, 'F7Ib', 433, 0.07, 1.98),
(11, 'Процион (α Малого Пса)', 1, 1.5, 6530, 7, 2.0, 'F5IV-V', 11.4, 1.7, 0.34),
(12, 'Альдебаран (α Тельца)', 1, 1.7, 3910, 150, 44, 'K5III', 65, 6.4, 0.85),
(13, 'Спика (α Девы)', 1, 11, 25300, 21000, 7.5, 'B1V', 250, 0.12, 1.04),
(14, 'Поллукс (β Близнецов)', 1, 1.9, 4660, 32, 8.8, 'K0III', 34, 0.7, 1.14),
(15, 'Денеб (α Лебедя)', 1, 20, 8500, 196000, 200, 'A2Ia', 1400, 0.01, 1.25)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    galaxy_id = EXCLUDED.galaxy_id,
    mass_solar = EXCLUDED.mass_solar,
    temperature_k = EXCLUDED.temperature_k,
    luminosity_solar = EXCLUDED.luminosity_solar,
    radius_solar = EXCLUDED.radius_solar,
    spectral_class = EXCLUDED.spectral_class,
    distance_from_sun_ly = EXCLUDED.distance_from_sun_ly,
    age_billion_years = EXCLUDED.age_billion_years,
    apparent_magnitude = EXCLUDED.apparent_magnitude;

-- 4. Вставка данных в planets
-- =====================================================
INSERT INTO planets (id, name, star_id, planet_type, mass_earth, diameter_km, orbital_period_days, distance_from_star_au, surface_temperature_c, satellites_count, atmosphere_composition) VALUES
-- Солнечная система (звезда id=1)
(1, 'Меркурий', 1, 'Земная', 0.055, 4879, 88, 0.39, '-173 до 427', 0, 'Отсутствует'),
(2, 'Венера', 1, 'Земная', 0.815, 12104, 225, 0.72, '462', 0, 'CO₂ (96.5%), N₂'),
(3, 'Земля', 1, 'Земная', 1.0, 12742, 365.25, 1.0, '-88 до 58', 1, 'N₂ (78%), O₂ (21%)'),
(4, 'Марс', 1, 'Земная', 0.107, 6779, 687, 1.52, '-153 до 20', 2, 'CO₂ (95%), N₂, Ar'),
(5, 'Юпитер', 1, 'Газовый гигант', 317.8, 139820, 4333, 5.2, '-108', 95, 'H₂ (90%), He (10%)'),
(6, 'Сатурн', 1, 'Газовый гигант', 95.2, 116460, 10759, 9.5, '-139', 146, 'H₂ (96%), He (3%)'),
(7, 'Уран', 1, 'Ледяной гигант', 14.5, 50724, 30687, 19.2, '-197', 28, 'H₂, He, CH₄'),
(8, 'Нептун', 1, 'Ледяной гигант', 17.1, 49244, 60190, 30.1, '-201', 16, 'H₂, He, CH₄'),

-- Проксима Центавра (звезда id=4)
(9, 'Проксима Центавра b', 4, 'Земная', 1.27, 13000, 11.2, 0.05, '-39', 0, 'Неизвестна'),

-- Экзопланеты
(10, 'HD 209458 b (Осирис)', 2, 'Газовый гигант', 0.69, 140000, 3.5, 0.047, '1000', 0, 'H₂, He, Na'),
(11, 'Kepler-22b', 5, 'Земная', 2.4, 24000, 290, 0.85, '22', 0, 'Неизвестна'),
(12, 'Kepler-452b', 5, 'Земная', 5.0, 28000, 385, 1.05, '10', 0, 'Неизвестна'),
(13, 'TRAPPIST-1e', 4, 'Земная', 0.77, 11000, 6.1, 0.028, '-40', 0, 'Неизвестна'),
(14, '55 Cancri e', 5, 'Земная', 8.6, 23000, 0.74, 0.015, '2000', 0, 'CO₂, H₂O'),
(15, 'GJ 1214 b', 4, 'Земная', 6.5, 27000, 1.58, 0.014, '280', 0, 'H₂O, He')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    star_id = EXCLUDED.star_id,
    planet_type = EXCLUDED.planet_type,
    mass_earth = EXCLUDED.mass_earth,
    diameter_km = EXCLUDED.diameter_km,
    orbital_period_days = EXCLUDED.orbital_period_days,
    distance_from_star_au = EXCLUDED.distance_from_star_au,
    surface_temperature_c = EXCLUDED.surface_temperature_c,
    satellites_count = EXCLUDED.satellites_count,
    atmosphere_composition = EXCLUDED.atmosphere_composition;

-- 5. Вставка данных в satellites
-- =====================================================
INSERT INTO satellites (id, name, planet_id, satellite_type, diameter_km, mass_kg, orbital_period_days, distance_from_planet_km, temperature_c, discovery_year, discoverer) VALUES
-- Спутники Земли (планета id=3)
(1, 'Луна', 3, 'Скалистый', 3474, '7.35×10²²', 27.3, 384400, '-173 до 127', NULL, '-'),

-- Спутники Марса (планета id=4)
(2, 'Фобос', 4, 'Скалистый', 22.2, '1.07×10¹⁶', 0.32, 9377, '-4 до -112', 1877, 'Асаф Холл'),
(3, 'Деймос', 4, 'Скалистый', 12.6, '1.48×10¹⁵', 1.26, 23460, '-112', 1877, 'Асаф Холл'),

-- Спутники Юпитера (планета id=5) - Галилеевы спутники и другие
(4, 'Ио', 5, 'Скалистый', 3643, '8.93×10²²', 1.77, 421700, '-130 до 1600', 1610, 'Галилео Галилей'),
(5, 'Европа', 5, 'Ледяной', 3122, '4.80×10²²', 3.55, 671000, '-160', 1610, 'Галилео Галилей'),
(6, 'Ганимед', 5, 'Ледяной', 5268, '1.48×10²³', 7.15, 1070000, '-160', 1610, 'Галилео Галилей'),
(7, 'Каллисто', 5, 'Ледяной', 4821, '1.08×10²³', 16.69, 1883000, '-140', 1610, 'Галилео Галилей'),
(8, 'Амальтея', 5, 'Скалистый', 250, '2.08×10¹⁸', 0.50, 181400, '-120', 1892, 'Эдвард Барнард'),
(9, 'Фива', 5, 'Скалистый', 98, '4.3×10¹⁷', 0.67, 221900, '-130', 1979, 'Вояджер'),

-- Спутники Сатурна (планета id=6)
(10, 'Титан', 6, 'Ледяной', 5150, '1.35×10²³', 15.95, 1221870, '-179', 1655, 'Христиан Гюйгенс'),
(11, 'Энцелад', 6, 'Ледяной', 504, '1.08×10²⁰', 1.37, 238000, '-198', 1789, 'Уильям Гершель'),
(12, 'Мимас', 6, 'Ледяной', 396, '3.75×10¹⁹', 0.94, 185400, '-200', 1789, 'Уильям Гершель'),
(13, 'Тефия', 6, 'Ледяной', 1060, '6.17×10²⁰', 1.89, 294600, '-187', 1684, 'Джованни Кассини'),
(14, 'Диона', 6, 'Ледяной', 1120, '1.10×10²¹', 2.74, 377400, '-186', 1684, 'Джованни Кассини'),
(15, 'Рея', 6, 'Ледяной', 1528, '2.31×10²¹', 4.52, 527000, '-174', 1672, 'Джованни Кассини'),
(16, 'Япет', 6, 'Ледяной', 1470, '1.81×10²¹', 79.33, 3561000, '-143', 1671, 'Джованни Кассини'),
(17, 'Феба', 6, 'Скалистый', 213, '8.3×10¹⁸', 548, 12952000, '-175', 1899, 'Уильям Пикеринг'),

-- Спутники Урана (планета id=7)
(18, 'Титания', 7, 'Ледяной', 1578, '3.53×10²¹', 8.71, 436300, '-190', 1787, 'Уильям Гершель'),
(19, 'Оберон', 7, 'Ледяной', 1523, '3.01×10²¹', 13.46, 583500, '-190', 1787, 'Уильям Гершель'),
(20, 'Умбриэль', 7, 'Ледяной', 1169, '1.17×10²¹', 4.14, 266000, '-193', 1851, 'Уильям Лассел'),
(21, 'Ариэль', 7, 'Ледяной', 1158, '1.35×10²¹', 2.52, 190900, '-193', 1851, 'Уильям Лассел'),
(22, 'Миранда', 7, 'Скалистый', 472, '6.6×10¹⁹', 1.41, 129900, '-187', 1948, 'Джерард Койпер'),

-- Спутники Нептуна (планета id=8)
(23, 'Тритон', 8, 'Ледяной', 2707, '2.14×10²²', 5.88, 354759, '-235', 1846, 'Уильям Лассел'),
(24, 'Нереида', 8, 'Скалистый', 340, '3.1×10¹⁹', 360.1, 5513800, '-222', 1949, 'Джерард Койпер'),
(25, 'Протей', 8, 'Скалистый', 420, '5.0×10¹⁹', 1.12, 117647, '-222', 1989, 'Вояджер')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    planet_id = EXCLUDED.planet_id,
    satellite_type = EXCLUDED.satellite_type,
    diameter_km = EXCLUDED.diameter_km,
    mass_kg = EXCLUDED.mass_kg,
    orbital_period_days = EXCLUDED.orbital_period_days,
    distance_from_planet_km = EXCLUDED.distance_from_planet_km,
    temperature_c = EXCLUDED.temperature_c,
    discovery_year = EXCLUDED.discovery_year,
    discoverer = EXCLUDED.discoverer;

-- 6. Вставка данных в feature_flags
-- =====================================================
INSERT INTO feature_flags (flag_name, is_enabled, description) VALUES
('ENABLE_PLANETS_MODULE', true, 'Включает функциональность работы с планетами (CRUD операции)'),
('ENABLE_ADVANCED_SEARCH', false, 'Включает расширенный поиск по химическому составу звезд'),
('ENABLE_STATISTICS', true, 'Включает сбор и отображение статистики по типам галактик'),
('ENABLE_EXOPLANETS', true, 'Включает отображение экзопланет'),
('ENABLE_SATELLITES_MODULE', true, 'Включает функциональность работы со спутниками')
ON CONFLICT (flag_name) DO UPDATE SET
    is_enabled = EXCLUDED.is_enabled,
    description = EXCLUDED.description,
    updated_at = CURRENT_TIMESTAMP;

-- 7. Вставка данных в users (тестовые пользователи)
-- =====================================================
-- ВНИМАНИЕ: В реальном проекте пароли должны быть хешированы!
INSERT INTO users (username, password_hash, email, role, created_at) VALUES
('admin', '$2b$10$5zZM5kZ5tV5Z5tV5Z5tV5u', 'admin@astronomy.org', 'admin', CURRENT_TIMESTAMP),
('astronomer', '$2b$10$5zZM5kZ5tV5Z5tV5Z5tV5u', 'astronomer@astronomy.org', 'user', CURRENT_TIMESTAMP),
('researcher', '$2b$10$5zZM5kZ5tV5Z5tV5Z5tV5u', 'researcher@astronomy.org', 'user', CURRENT_TIMESTAMP),
('student', '$2b$10$5zZM5kZ5tV5Z5tV5Z5tV5u', 'student@astronomy.org', 'user', CURRENT_TIMESTAMP)
ON CONFLICT (username) DO NOTHING;

-- =====================================================
-- Создание триггеров для аудита
-- =====================================================

-- Создаем триггеры для основных таблиц
CREATE TRIGGER trigger_audit_galaxies
    AFTER INSERT OR UPDATE OR DELETE ON galaxies
    FOR EACH ROW EXECUTE FUNCTION log_audit();

CREATE TRIGGER trigger_audit_stars
    AFTER INSERT OR UPDATE OR DELETE ON stars
    FOR EACH ROW EXECUTE FUNCTION log_audit();

CREATE TRIGGER trigger_audit_planets
    AFTER INSERT OR UPDATE OR DELETE ON planets
    FOR EACH ROW EXECUTE FUNCTION log_audit();

CREATE TRIGGER trigger_audit_satellites
    AFTER INSERT OR UPDATE OR DELETE ON satellites
    FOR EACH ROW EXECUTE FUNCTION log_audit();

CREATE TRIGGER trigger_audit_galaxy_types
    AFTER INSERT OR UPDATE OR DELETE ON galaxy_types
    FOR EACH ROW EXECUTE FUNCTION log_audit();

-- =====================================================
-- Проверочные запросы для верификации данных
-- =====================================================

-- Проверка количества записей
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
SELECT 'users', COUNT(*) FROM users;

-- Вывод статистики
SELECT 
    (SELECT COUNT(*) FROM galaxies) as total_galaxies,
    (SELECT COUNT(*) FROM stars) as total_stars,
    (SELECT COUNT(*) FROM planets) as total_planets,
    (SELECT COUNT(*) FROM satellites) as total_satellites;

-- Проверка представлений
SELECT * FROM view_galaxies_full LIMIT 5;
SELECT * FROM view_stars_full LIMIT 5;
SELECT * FROM view_planets_full LIMIT 5;
SELECT * FROM view_satellites_full LIMIT 5;

-- =====================================================
-- 9. Таблица: small_bodies (Малые тела: астероиды, кометы)
-- =====================================================
DROP TABLE IF EXISTS small_bodies CASCADE;
CREATE TABLE small_bodies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,                -- Основное имя (напр., 1 Ceres)
    spk_id VARCHAR(50) UNIQUE,                 -- JPL SPK-ID (уникальный идентификатор)
    designation VARCHAR(200),                  -- Обозначение (напр., 1998 SF36)
    body_type VARCHAR(20) CHECK (body_type IN ('Asteroid', 'Comet', 'Dwarf Planet')), -- Тип тела
    
    -- Орбитальные параметры (оскулирующие элементы)
    epoch_jd NUMERIC(15, 5),                   -- Эпоха в Юлианских днях
    eccentricity NUMERIC(15, 10),              -- Эксцентриситет (e)
    semi_major_axis_au NUMERIC(15, 8),         -- Большая полуось (a) в а.е.
    perihelion_au NUMERIC(15, 8),              -- Перигелий (q)
    aphelion_au NUMERIC(15, 8),                -- Афелий (Q)
    inclination_deg NUMERIC(10, 6),            -- Наклонение (i) в градусах
    arg_periapsis_deg NUMERIC(10, 6),          -- Аргумент перицентра (ω)
    long_asc_node_deg NUMERIC(10, 6),          -- Долгота восходящего узла (Ω)
    mean_anomaly_deg NUMERIC(10, 6),           -- Средняя аномалия (M)
    orbital_period_days NUMERIC(15, 4),        -- Период обращения в днях
    
    -- Физические параметры
    diameter_km NUMERIC(10, 3),                -- Диаметр в км
    rotation_period_h NUMERIC(10, 4),          -- Период вращения в часах
    albedo NUMERIC(6, 4),                      -- Геометрическое альбедо
    spectral_type VARCHAR(10),                 -- Спектральный класс (C, S, M и т.д.)
    magnitude_h NUMERIC(6, 2),                 -- Абсолютная звездная величина H
    
    -- Обстоятельства открытия
    discovery_date DATE,                       -- Дата открытия
    discovery_site VARCHAR(200),               -- Место открытия
    discoverer VARCHAR(200),                   -- Первооткрыватель
    
    -- Потенциальная опасность
    is_pha BOOLEAN DEFAULT false,              -- Potentially Hazardous Asteroid (PHA)
    
    data_source TEXT,                          -- Ссылка на страницу в SBDB
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE small_bodies IS 'Каталог малых тел Солнечной системы (астероиды, кометы, карликовые планеты)';
COMMENT ON COLUMN small_bodies.spk_id IS 'Уникальный идентификатор в системе JPL SPICE';
COMMENT ON COLUMN small_bodies.is_pha IS 'Флаг потенциально опасного астероида (PHA)';

-- Индексы для таблицы малых тел
CREATE INDEX idx_small_bodies_name ON small_bodies(name);
CREATE INDEX idx_small_bodies_type ON small_bodies(body_type);
CREATE INDEX idx_small_bodies_designation ON small_bodies(designation);
CREATE INDEX idx_small_bodies_pha ON small_bodies(is_pha);