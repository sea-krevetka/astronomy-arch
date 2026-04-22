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