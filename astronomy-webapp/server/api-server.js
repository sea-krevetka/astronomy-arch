const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('.'));

// Настройка подключения к PostgreSQL
const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5433,
    database: process.env.DB_NAME || 'astronomy_catalog',
    user: process.env.DB_USER || 'astronomy_admin',
    password: process.env.DB_PASSWORD || 'Astronomy2024!',
    max: 20, // максимальное количество клиентов в пуле
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
});

// Проверка подключения
pool.connect((err, client, release) => {
    if (err) {
        console.error('Ошибка подключения к БД:', err.stack);
    } else {
        console.log('✅ Подключено к PostgreSQL');
        release();
    }
});

// ===================== API ENDPOINTS =====================

// Получить все галактики
app.get('/api/galaxies', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT * FROM view_galaxies_full 
            ORDER BY id
        `);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Ошибка при получении галактик' });
    }
});

// Получить галактику по ID
app.get('/api/galaxies/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(`
            SELECT * FROM view_galaxies_full 
            WHERE id = $1
        `, [id]);
        
        if (result.rows.length === 0) {
            res.status(404).json({ error: 'Галактика не найдена' });
        } else {
            res.json(result.rows[0]);
        }
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Ошибка при получении галактики' });
    }
});

// Получить все звезды
app.get('/api/stars', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT * FROM view_stars_full 
            ORDER BY id
        `);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Ошибка при получении звезд' });
    }
});

// Получить звезды по галактике
app.get('/api/stars/galaxy/:galaxyId', async (req, res) => {
    try {
        const { galaxyId } = req.params;
        const result = await pool.query(`
            SELECT * FROM view_stars_full 
            WHERE galaxy_id = $1
            ORDER BY id
        `, [galaxyId]);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Ошибка при получении звезд' });
    }
});

// Получить все планеты
app.get('/api/planets', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT * FROM view_planets_full 
            ORDER BY id
        `);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Ошибка при получении планет' });
    }
});

// Получить планеты по звезде
app.get('/api/planets/star/:starId', async (req, res) => {
    try {
        const { starId } = req.params;
        const result = await pool.query(`
            SELECT * FROM view_planets_full 
            WHERE star_id = $1
            ORDER BY id
        `, [starId]);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Ошибка при получении планет' });
    }
});

// Получить все спутники
app.get('/api/satellites', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT * FROM view_satellites_full 
            ORDER BY id
        `);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Ошибка при получении спутников' });
    }
});

// Получить спутники по планете
app.get('/api/satellites/planet/:planetId', async (req, res) => {
    try {
        const { planetId } = req.params;
        const result = await pool.query(`
            SELECT * FROM view_satellites_full 
            WHERE planet_id = $1
            ORDER BY id
        `, [planetId]);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Ошибка при получении спутников' });
    }
});

// Получить все малые тела
app.get('/api/small-bodies', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT * FROM small_bodies 
            ORDER BY id
        `);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Ошибка при получении малых тел' });
    }
});

// Получить типы галактик
app.get('/api/galaxy-types', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT id, name, description, stellar_population, star_formation 
            FROM galaxy_types 
            ORDER BY id
        `);
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Ошибка при получении типов галактик' });
    }
});

// Статистика
app.get('/api/statistics', async (req, res) => {
    try {
        const stats = {};
        
        // Количество галактик по типам
        const galaxyTypes = await pool.query(`
            SELECT gt.name, COUNT(g.id) as count
            FROM galaxy_types gt
            LEFT JOIN galaxies g ON gt.id = g.galaxy_type_id
            GROUP BY gt.name
        `);
        stats.galaxy_by_type = galaxyTypes.rows;
        
        // Общая статистика
        const total = await pool.query(`
            SELECT 
                (SELECT COUNT(*) FROM galaxies) as total_galaxies,
                (SELECT COUNT(*) FROM stars) as total_stars,
                (SELECT COUNT(*) FROM planets) as total_planets,
                (SELECT COUNT(*) FROM satellites) as total_satellites,
                (SELECT COUNT(*) FROM small_bodies) as total_small_bodies
        `);
        stats.total = total.rows[0];
        
        // Самые крупные галактики
        const largest = await pool.query(`
            SELECT name, diameter_ly, star_count 
            FROM galaxies 
            ORDER BY diameter_ly DESC 
            LIMIT 5
        `);
        stats.largest_galaxies = largest.rows;
        
        res.json(stats);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Ошибка при получении статистики' });
    }
});

// Поиск
app.get('/api/search', async (req, res) => {
    try {
        const { q, type } = req.query;
        
        if (!q) {
            return res.status(400).json({ error: 'Введите поисковый запрос' });
        }
        
        let results = [];
        
        if (type === 'galaxies' || !type) {
            const galaxies = await pool.query(`
                SELECT id, name, 'galaxy' as type, diameter_ly as info
                FROM galaxies 
                WHERE name ILIKE $1
                LIMIT 10
            `, [`%${q}%`]);
            results.push(...galaxies.rows);
        }
        
        if (type === 'stars' || !type) {
            const stars = await pool.query(`
                SELECT id, name, 'star' as type, spectral_class as info
                FROM stars 
                WHERE name ILIKE $1
                LIMIT 10
            `, [`%${q}%`]);
            results.push(...stars.rows);
        }
        
        if (type === 'planets' || !type) {
            const planets = await pool.query(`
                SELECT id, name, 'planet' as type, planet_type as info
                FROM planets 
                WHERE name ILIKE $1
                LIMIT 10
            `, [`%${q}%`]);
            results.push(...planets.rows);
        }
        
        if (type === 'small-bodies' || !type) {
            const smallBodies = await pool.query(`
                SELECT id, name, 'small-body' as type, body_type as info
                FROM small_bodies 
                WHERE name ILIKE $1
                LIMIT 10
            `, [`%${q}%`]);
            results.push(...smallBodies.rows);
        }
        
        res.json(results);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Ошибка при поиске' });
    }
});

// Запуск сервера
app.listen(port, () => {
    console.log(`🚀 Сервер запущен на http://localhost:${port}`);
});