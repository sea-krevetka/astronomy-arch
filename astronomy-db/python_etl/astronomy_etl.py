#!/usr/bin/env python3
"""
Скрипт для загрузки данных о галактиках, звездах и планетах из астрономических баз данных.
"""

import psycopg2
from psycopg2 import OperationalError
from astroquery.simbad import Simbad
from astroquery.ipac.nexsci.nasa_exoplanet_archive import NasaExoplanetArchive
from typing import Dict, List, Optional, Tuple
import time
import logging

# Настройка логирования
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# =====================================================
# КОНФИГУРАЦИЯ ПОДКЛЮЧЕНИЯ К БД
# =====================================================

DB_CONFIG = {
    'dbname': 'astronomy_catalog',
    'user': 'astronomy_admin',
    'password': 'Astronomy2024!',
    'host': 'localhost',
    'port': 5433
}

# Список галактик для загрузки (с правильными идентификаторами SIMBAD)
GALAXIES_TO_LOAD = [
    {'name': 'Млечный Путь', 'simbad_id': 'NAME Milky Way', 'type': 4},
    {'name': 'Андромеда', 'simbad_id': 'M31', 'type': 3},
    {'name': 'Треугольник', 'simbad_id': 'M33', 'type': 3},
    {'name': 'Центавр A', 'simbad_id': 'NGC 5128', 'type': 1},
    {'name': 'Водоворот', 'simbad_id': 'M51', 'type': 3},
]

# =====================================================
# НАСТРОЙКА SIMBAD
# =====================================================

Simbad.add_votable_fields(
    'otype',
    'sp_type',
    'V',
    'B',
    'parallax',
    'pmra', 'pmdec',
    'rvz_radvel',
    'dim',
    'rvz_redshift',
    'mesdistance',
)

# =====================================================
# ФУНКЦИИ ДЛЯ РАБОТЫ С БАЗОЙ ДАННЫХ (без ON CONFLICT)
# =====================================================

def test_db_connection():
    """Тестирование подключения к БД"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()
        logger.info(f"✅ Подключено к PostgreSQL: {version[0][:50]}...")
        
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
            AND table_name IN ('galaxies', 'stars', 'planets', 'galaxy_types')
        """)
        tables = cursor.fetchall()
        logger.info(f"📊 Найдены таблицы: {[t[0] for t in tables]}")
        
        cursor.close()
        conn.close()
        return True
    except OperationalError as e:
        logger.error(f"❌ Не удалось подключиться: {e}")
        return False

def get_db_connection():
    """Создание соединения с PostgreSQL"""
    return psycopg2.connect(**DB_CONFIG)

def insert_galaxy_type(cursor, name: str, description: str = None) -> int:
    """Вставка типа галактики"""
    cursor.execute("""
        INSERT INTO galaxy_types (name, description)
        VALUES (%s, %s)
        ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
        RETURNING id
    """, (name, description))
    return cursor.fetchone()[0]

def insert_galaxy(cursor, galaxy_data: Dict) -> int:
    """Вставка галактики с проверкой существования (без ON CONFLICT)"""
    # Проверяем, существует ли уже такая галактика
    cursor.execute("SELECT id FROM galaxies WHERE name = %s", (galaxy_data['name'],))
    existing = cursor.fetchone()
    
    if existing:
        galaxy_id = existing[0]
        # Обновляем существующую запись
        cursor.execute("""
            UPDATE galaxies SET
                galaxy_type_id = %s,
                diameter_ly = %s,
                star_count = %s,
                mass_solar_masses = %s,
                distance_from_earth_ly = %s,
                metallicity = %s,
                rotation_speed_kms = %s,
                discovery_year = %s
            WHERE id = %s
        """, (
            galaxy_data.get('galaxy_type_id'),
            galaxy_data.get('diameter_ly'),
            galaxy_data.get('star_count'),
            galaxy_data.get('mass_solar_masses'),
            galaxy_data.get('distance_from_earth_ly'),
            galaxy_data.get('metallicity'),
            galaxy_data.get('rotation_speed_kms'),
            galaxy_data.get('discovery_year'),
            galaxy_id
        ))
        logger.info(f"  Обновлена существующая галактика (ID: {galaxy_id})")
        return galaxy_id
    else:
        # Вставляем новую галактику
        cursor.execute("""
            INSERT INTO galaxies (
                name, galaxy_type_id, diameter_ly, star_count,
                mass_solar_masses, distance_from_earth_ly,
                metallicity, rotation_speed_kms, discovery_year
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (
            galaxy_data['name'],
            galaxy_data.get('galaxy_type_id'),
            galaxy_data.get('diameter_ly'),
            galaxy_data.get('star_count'),
            galaxy_data.get('mass_solar_masses'),
            galaxy_data.get('distance_from_earth_ly'),
            galaxy_data.get('metallicity'),
            galaxy_data.get('rotation_speed_kms'),
            galaxy_data.get('discovery_year')
        ))
        galaxy_id = cursor.fetchone()[0]
        logger.info(f"  Добавлена новая галактика (ID: {galaxy_id})")
        return galaxy_id

def insert_star(cursor, star_data: Dict, galaxy_id: Optional[int] = None) -> Optional[int]:
    """Вставка звезды с проверкой существования"""
    try:
        # Проверяем, существует ли уже такая звезда
        cursor.execute("SELECT id FROM stars WHERE name = %s", (star_data['name'],))
        existing = cursor.fetchone()
        
        if existing:
            return existing[0]
        
        # Вставляем новую звезду
        cursor.execute("""
            INSERT INTO stars (
                name, galaxy_id, mass_solar, temperature_k,
                luminosity_solar, radius_solar, spectral_class,
                distance_from_sun_ly, apparent_magnitude
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (
            star_data['name'],
            galaxy_id,
            star_data.get('mass_solar'),
            star_data.get('temperature_k'),
            star_data.get('luminosity_solar'),
            star_data.get('radius_solar'),
            star_data.get('spectral_class'),
            star_data.get('distance_from_sun_ly'),
            star_data.get('apparent_magnitude')
        ))
        result = cursor.fetchone()
        return result[0] if result else None
    except Exception as e:
        logger.error(f"Ошибка при вставке звезды {star_data.get('name')}: {e}")
        return None

def insert_planet(cursor, planet_data: Dict, star_id: int) -> Optional[int]:
    """Вставка планеты с проверкой существования"""
    try:
        # Проверяем, существует ли уже такая планета
        cursor.execute("SELECT id FROM planets WHERE name = %s", (planet_data['name'],))
        existing = cursor.fetchone()
        
        if existing:
            return existing[0]
        
        cursor.execute("""
            INSERT INTO planets (
                name, star_id, planet_type, mass_earth,
                diameter_km, orbital_period_days, distance_from_star_au,
                surface_temperature_c, atmosphere_composition, satellites_count
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (
            planet_data['name'],
            star_id,
            planet_data.get('planet_type', 'Unknown'),
            planet_data.get('mass_earth'),
            planet_data.get('diameter_km'),
            planet_data.get('orbital_period_days'),
            planet_data.get('distance_from_star_au'),
            planet_data.get('surface_temperature_c'),
            planet_data.get('atmosphere_composition'),
            planet_data.get('satellites_count', 0)
        ))
        result = cursor.fetchone()
        return result[0] if result else None
    except Exception as e:
        logger.error(f"Ошибка при вставке планеты {planet_data.get('name')}: {e}")
        return None

# =====================================================
# ФУНКЦИИ ЗАГРУЗКИ ДАННЫХ
# =====================================================

def load_galaxy_from_simbad(galaxy_name: str, simbad_id: str) -> Dict:
    """Загрузка данных о галактике из SIMBAD"""
    logger.info(f"📡 Загрузка данных о галактике {simbad_id}...")
    
    try:
        result = Simbad.query_object(simbad_id)
        if result is None or len(result) == 0:
            logger.warning(f"Галактика {simbad_id} не найдена")
            return {'name': galaxy_name}
        
        row = result[0]
        galaxy_data = {
            'name': galaxy_name,
            'distance_from_earth_ly': None,
            'metallicity': None,
            'rotation_speed_kms': None,
            'diameter_ly': None
        }
        
        if 'MESDISTANCE' in row.colnames and row['MESDISTANCE']:
            try:
                dist_pc = float(row['MESDISTANCE'])
                galaxy_data['distance_from_earth_ly'] = int(dist_pc * 3.26156)
                logger.info(f"  📍 Расстояние: {galaxy_data['distance_from_earth_ly']:,} св. лет")
            except:
                pass
        
        if 'DIM' in row.colnames and row['DIM'] and galaxy_data['distance_from_earth_ly']:
            try:
                dim_arcmin = float(row['DIM'])
                dim_rad = dim_arcmin / 60 * 3.14159 / 180
                galaxy_data['diameter_ly'] = int(galaxy_data['distance_from_earth_ly'] * dim_rad)
                logger.info(f"  📏 Диаметр: ~{galaxy_data['diameter_ly']:,} св. лет")
            except:
                pass
        
        return galaxy_data
    except Exception as e:
        logger.error(f"Ошибка: {e}")
        return {'name': galaxy_name}

def get_galaxy_coordinates(simbad_id: str) -> Tuple[Optional[float], Optional[float]]:
    """Получение координат галактики"""
    try:
        result = Simbad.query_object(simbad_id)
        if result is None or len(result) == 0:
            return None, None
        
        ra, dec = None, None
        
        if 'RA' in result.colnames and result['RA'][0]:
            ra_str = str(result['RA'][0])
            try:
                parts = ra_str.split()
                if len(parts) == 3:
                    ra = float(parts[0]) + float(parts[1])/60 + float(parts[2])/3600
                    ra = ra * 15
                else:
                    ra = float(ra_str)
            except:
                pass
        
        if 'DEC' in result.colnames and result['DEC'][0]:
            dec_str = str(result['DEC'][0])
            try:
                parts = dec_str.split()
                if len(parts) == 3:
                    dec = abs(float(parts[0])) + float(parts[1])/60 + float(parts[2])/3600
                    if dec_str.startswith('-'):
                        dec = -dec
                else:
                    dec = float(dec_str)
            except:
                pass
        
        return ra, dec
    except Exception as e:
        logger.error(f"Ошибка получения координат: {e}")
        return None, None

def load_stars_near_coordinates(ra: float, dec: float, radius_deg: float = 0.3, limit: int = 15) -> List[Dict]:
    """Загрузка звезд в окрестности координат"""
    stars = []
    
    try:
        coord_str = f"{ra} {dec}"
        result = Simbad.query_region(coord_str, radius=f"{radius_deg}d")
        
        if result is None:
            return stars
        
        star_count = 0
        for row in result:
            if star_count >= limit:
                break
                
            otype = str(row.get('OTYPE', '')) if 'OTYPE' in row.colnames else ''
            
            if 'Star' in otype or 'star' in otype.upper():
                star_data = {
                    'name': row.get('MAIN_ID', f"Star_{ra}_{dec}_{star_count}") if 'MAIN_ID' in row.colnames else f"Star_{ra}_{dec}_{star_count}",
                    'spectral_class': row.get('SP_TYPE', None) if 'SP_TYPE' in row.colnames else None,
                    'apparent_magnitude': None,
                    'distance_from_sun_ly': None,
                    'mass_solar': None,
                    'temperature_k': None,
                    'luminosity_solar': None,
                    'radius_solar': None
                }
                
                if 'FLUX_V' in row.colnames and row['FLUX_V']:
                    try:
                        star_data['apparent_magnitude'] = float(row['FLUX_V'])
                    except:
                        pass
                
                if 'PARALLAX' in row.colnames and row['PARALLAX']:
                    try:
                        parallax_mas = float(row['PARALLAX'])
                        if parallax_mas > 0:
                            dist_pc = 1000 / parallax_mas
                            star_data['distance_from_sun_ly'] = round(dist_pc * 3.26156, 2)
                    except:
                        pass
                
                if star_data['spectral_class']:
                    spectral = star_data['spectral_class'].upper()
                    temp_map = {'O': 30000, 'B': 15000, 'A': 9000, 'F': 6500, 'G': 5500, 'K': 4500, 'M': 3500}
                    for key in temp_map:
                        if spectral.startswith(key):
                            star_data['temperature_k'] = temp_map[key]
                            break
                
                stars.append(star_data)
                star_count += 1
        
        logger.info(f"  ⭐ Найдено {len(stars)} звезд")
        return stars
    except Exception as e:
        logger.error(f"Ошибка поиска звезд: {e}")
        return stars

def load_exoplanets_for_star(star_name: str) -> List[Dict]:
    """Загрузка экзопланет"""
    planets = []
    
    try:
        clean_name = star_name.replace('*', '').replace('(', '').replace(')', '').strip()
        simple_name = clean_name.split()[0].replace(',', '')
        
        try:
            table = NasaExoplanetArchive.query_criteria(
                table="ps",
                select="pl_name,hostname,pl_masse,pl_rade,pl_orbper,pl_orbsmax,pl_eqt",
                where=f"hostname like '%{simple_name}%'"
            )
        except:
            return planets
        
        if table is None or len(table) == 0:
            return planets
        
        for row in table:
            try:
                mass = float(row['pl_masse']) if row['pl_masse'] else None
                planet_data = {
                    'name': row['pl_name'],
                    'planet_type': 'Газовый гигант' if mass and mass > 10 else 'Земная',
                    'mass_earth': mass,
                    'diameter_km': float(row['pl_rade']) * 12742 if row['pl_rade'] else None,
                    'orbital_period_days': float(row['pl_orbper']) if row['pl_orbper'] else None,
                    'distance_from_star_au': float(row['pl_orbsmax']) if row['pl_orbsmax'] else None,
                    'surface_temperature_c': (float(row['pl_eqt']) - 273.15) if row['pl_eqt'] else None,
                    'atmosphere_composition': None,
                    'satellites_count': 0
                }
                planets.append(planet_data)
            except:
                continue
        
        if planets:
            logger.info(f"    🪐 Найдено {len(planets)} планет")
        
    except Exception as e:
        logger.debug(f"Не удалось загрузить планеты: {e}")
    
    return planets

# =====================================================
# ОСНОВНАЯ ФУНКЦИЯ
# =====================================================

def main():
    """Основная функция"""
    logger.info("=" * 60)
    logger.info("🌌 Загрузка астрономических данных в БД astronomy_catalog")
    logger.info("=" * 60)
    
    if not test_db_connection():
        return
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # 1. Заполнение типов галактик
        logger.info("\n📋 1. Заполнение galaxy_types...")
        default_types = [
            ('Эллиптическая', 'Эллиптические галактики без спиральной структуры'),
            ('Линзовидная', 'Промежуточный тип между эллиптическими и спиральными'),
            ('Спиральная', 'Дисковые галактики со спиральными рукавами'),
            ('Спиральная с перемычкой', 'Спиральные галактики с баром'),
            ('Неправильная', 'Галактики неправильной формы')
        ]
        
        for type_name, type_desc in default_types:
            type_id = insert_galaxy_type(cursor, type_name, type_desc)
            logger.info(f"  ✅ {type_name} (ID: {type_id})")
        
        conn.commit()
        
        # 2. Загрузка галактик
        logger.info("\n🌌 2. Загрузка галактик...")
        
        for gal in GALAXIES_TO_LOAD:
            logger.info(f"\n--- {gal['name']} ({gal['simbad_id']}) ---")
            
            gal_data = load_galaxy_from_simbad(gal['name'], gal['simbad_id'])
            gal_data['galaxy_type_id'] = gal['type']
            gal_data['discovery_year'] = None
            gal_data['star_count'] = None
            gal_data['mass_solar_masses'] = None
            gal_data['metallicity'] = None
            gal_data['rotation_speed_kms'] = None
            
            galaxy_id = insert_galaxy(cursor, gal_data)
            conn.commit()
            
            # Получаем звезды в окрестности
            ra, dec = get_galaxy_coordinates(gal['simbad_id'])
            
            if ra and dec:
                logger.info(f"  📍 Координаты: RA={ra:.4f}°, DEC={dec:.4f}°")
                stars = load_stars_near_coordinates(ra, dec, radius_deg=0.3, limit=10)
                
                for star in stars:
                    star_id = insert_star(cursor, star, galaxy_id)
                    conn.commit()
                    
                    if star_id:
                        logger.info(f"    ⭐ {star['name']} (ID: {star_id})")
                        
                        time.sleep(0.5)
                        planets = load_exoplanets_for_star(star['name'])
                        
                        for planet in planets:
                            planet_id = insert_planet(cursor, planet, star_id)
                            if planet_id:
                                logger.info(f"      🪐 {planet['name']} (ID: {planet_id})")
                        
                        conn.commit()
                    
                    time.sleep(0.3)
            else:
                logger.warning("  ⚠️ Не удалось получить координаты")
            
            time.sleep(0.5)
        
        # 3. Статистика
        logger.info("\n" + "=" * 60)
        logger.info("📊 3. СТАТИСТИКА ЗАГРУЖЕННЫХ ДАННЫХ")
        logger.info("=" * 60)
        
        cursor.execute("""
            SELECT 
                (SELECT COUNT(*) FROM galaxies) as galaxies,
                (SELECT COUNT(*) FROM stars) as stars,
                (SELECT COUNT(*) FROM planets) as planets
        """)
        stats = cursor.fetchone()
        
        logger.info(f"  🌌 Галактик: {stats[0]}")
        logger.info(f"  ⭐ Звезд: {stats[1]}")
        logger.info(f"  🪐 Планет: {stats[2]}")
        
        logger.info("\n✨ Загрузка успешно завершена!")
        
    except Exception as e:
        logger.error(f"❌ Ошибка: {e}")
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()
        logger.info("🔌 Соединение с БД закрыто")

if __name__ == "__main__":
    main()