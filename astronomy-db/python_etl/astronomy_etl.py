#!/usr/bin/env python3
"""
Астрономический каталог - загрузка данных из внешних источников
Адаптировано для работы с Docker-контейнерами (astronomy-postgres)
"""

import os
import sys
import time
import logging
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, asdict
from datetime import datetime
import json

import psycopg2
from psycopg2.extras import execute_values, Json
import pandas as pd
import numpy as np
from astroquery.simbad import Simbad
from astroquery.ned import Ned
from astroquery.gaia import Gaia
import requests
from tqdm import tqdm

# =====================================================
# Конфигурация - соответствует docker-compose.yml
# =====================================================

# База данных - используем настройки из docker-compose
DB_CONFIG = {
    'host': os.getenv('POSTGRES_HOST', 'localhost'),  # 'postgres' если скрипт внутри сети Docker
    'port': int(os.getenv('POSTGRES_PORT', '5433')),   # Проброшенный порт 5433
    'database': os.getenv('POSTGRES_DB', 'astronomy_catalog'),
    'user': os.getenv('POSTGRES_USER', 'astronomy_admin'),
    'password': os.getenv('POSTGRES_PASSWORD', 'Astronomy2024!')
}

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('astronomy_etl.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Кэш для уже загруженных объектов
CACHE_DIR = os.path.expanduser('~/.astronomy_cache')
os.makedirs(CACHE_DIR, exist_ok=True)

# =====================================================
# Модели данных (соответствуют таблицам БД)
# =====================================================

@dataclass
class GalaxyType:
    """Тип галактики"""
    name: str
    description: Optional[str] = None
    structure_shape: Optional[str] = None
    stellar_population: Optional[str] = None
    star_formation: Optional[str] = None
    size_mass: Optional[str] = None
    color: Optional[str] = None
    spatial_distribution: Optional[str] = None
    origin: Optional[str] = None


@dataclass
class Galaxy:
    """Галактика"""
    name: str
    galaxy_type_name: Optional[str] = None
    diameter_ly: Optional[int] = None
    star_count: Optional[str] = None
    mass_solar_masses: Optional[str] = None
    distance_from_earth_ly: Optional[int] = None
    age_billion_years: Optional[float] = None
    metallicity: Optional[str] = None
    rotation_speed_kms: Optional[int] = None
    discovery_year: Optional[int] = None
    ned_id: Optional[str] = None


@dataclass
class Star:
    """Звезда"""
    name: str
    galaxy_id: Optional[int] = None
    galaxy_name: Optional[str] = None
    mass_solar: Optional[float] = None
    temperature_k: Optional[int] = None
    luminosity_solar: Optional[float] = None
    radius_solar: Optional[float] = None
    spectral_class: Optional[str] = None
    distance_from_sun_ly: Optional[float] = None
    age_billion_years: Optional[float] = None
    apparent_magnitude: Optional[float] = None
    gaia_source_id: Optional[str] = None


@dataclass
class Planet:
    """Планета"""
    name: str
    star_name: str
    planet_type: Optional[str] = None
    mass_earth: Optional[float] = None
    diameter_km: Optional[int] = None
    orbital_period_days: Optional[float] = None
    distance_from_star_au: Optional[float] = None
    surface_temperature_c: Optional[str] = None
    satellites_count: Optional[int] = None
    atmosphere_composition: Optional[str] = None


@dataclass
class Satellite:
    """Спутник планеты"""
    name: str
    planet_name: str
    satellite_type: Optional[str] = None
    diameter_km: Optional[float] = None
    mass_kg: Optional[str] = None
    orbital_period_days: Optional[float] = None
    distance_from_planet_km: Optional[int] = None
    temperature_c: Optional[str] = None
    discovery_year: Optional[int] = None
    discoverer: Optional[str] = None


# =====================================================
# Класс для работы с базой данных
# =====================================================

class AstronomyDatabase:
    """Класс для взаимодействия с PostgreSQL БД в Docker"""
    
    def __init__(self, config: Dict):
        self.config = config
        self.conn = None
        self._connect()
    
    def _connect(self):
        """Установка соединения с БД"""
        try:
            logger.info(f"Connecting to PostgreSQL at {self.config['host']}:{self.config['port']}")
            logger.info(f"Database: {self.config['database']}, User: {self.config['user']}")
            
            self.conn = psycopg2.connect(**self.config)
            self.conn.autocommit = False
            logger.info("✅ Connected to PostgreSQL database")
            
            # Проверка существования таблиц
            self._verify_schema()
            
        except Exception as e:
            logger.error(f"❌ Failed to connect to database: {e}")
            logger.error("Make sure Docker container is running: docker-compose up -d")
            raise
    
    def _verify_schema(self):
        """Проверка, что таблицы созданы"""
        with self.conn.cursor() as cur:
            cur.execute("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name IN ('galaxies', 'stars', 'planets', 'satellites')
            """)
            tables = [row[0] for row in cur.fetchall()]
            
            if len(tables) < 4:
                logger.warning(f"⚠️  Found tables: {tables}")
                logger.warning("Expected tables: galaxies, stars, planets, satellites")
                logger.warning("Make sure init.sql was executed on container startup")
            else:
                logger.info(f"✅ Schema verified: {', '.join(tables)}")
    
    def close(self):
        """Закрытие соединения"""
        if self.conn:
            self.conn.close()
            logger.info("Database connection closed")
    
    def get_galaxy_type_id(self, type_name: str) -> Optional[int]:
        """Получение ID типа галактики по названию"""
        if not type_name:
            return None
        
        # Нормализация названия (английские типы -> русские)
        type_mapping = {
            'Elliptical': 'Эллиптическая',
            'Elliptical Galaxy': 'Эллиптическая',
            'E': 'Эллиптическая',
            'Spiral': 'Спиральная',
            'Spiral Galaxy': 'Спиральная',
            'S': 'Спиральная',
            'Lenticular': 'Линзовидная',
            'Lenticular Galaxy': 'Линзовидная',
            'S0': 'Линзовидная',
            'Barred Spiral': 'Спиральная с перемычкой',
            'SB': 'Спиральная с перемычкой',
            'Irregular': 'Неправильная',
            'Irr': 'Неправильная'
        }
        
        mapped_type = type_mapping.get(type_name, type_name)
        
        with self.conn.cursor() as cur:
            cur.execute("SELECT id FROM galaxy_types WHERE name = %s", (mapped_type,))
            result = cur.fetchone()
            if not result:
                logger.warning(f"Galaxy type '{mapped_type}' not found in galaxy_types table")
            return result[0] if result else None
    
    def insert_galaxy_type(self, galaxy_type: GalaxyType) -> Optional[int]:
        """Вставка типа галактики, возвращает ID"""
        with self.conn.cursor() as cur:
            cur.execute("""
                INSERT INTO galaxy_types (name, description, structure_shape, 
                                          stellar_population, star_formation, 
                                          size_mass, color, spatial_distribution, origin)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (name) DO UPDATE SET
                    description = EXCLUDED.description
                RETURNING id
            """, (
                galaxy_type.name, galaxy_type.description,
                galaxy_type.structure_shape, galaxy_type.stellar_population,
                galaxy_type.star_formation, galaxy_type.size_mass,
                galaxy_type.color, galaxy_type.spatial_distribution,
                galaxy_type.origin
            ))
            result = cur.fetchone()
            self.conn.commit()
            return result[0] if result else None
    
    def insert_galaxy(self, galaxy: Galaxy) -> Optional[int]:
        """Вставка галактики, возвращает ID"""
        galaxy_type_id = self.get_galaxy_type_id(galaxy.galaxy_type_name)
        
        with self.conn.cursor() as cur:
            try:
                cur.execute("""
                    INSERT INTO galaxies (name, galaxy_type_id, diameter_ly, star_count,
                                          mass_solar_masses, distance_from_earth_ly,
                                          age_billion_years, metallicity, rotation_speed_kms,
                                          discovery_year)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (name) DO NOTHING
                    RETURNING id
                """, (
                    galaxy.name, galaxy_type_id,
                    galaxy.diameter_ly, galaxy.star_count,
                    galaxy.mass_solar_masses, galaxy.distance_from_earth_ly,
                    galaxy.age_billion_years, galaxy.metallicity,
                    galaxy.rotation_speed_kms, galaxy.discovery_year
                ))
                result = cur.fetchone()
                self.conn.commit()
                if result:
                    logger.debug(f"Inserted galaxy: {galaxy.name} (ID: {result[0]})")
                return result[0] if result else None
            except Exception as e:
                logger.error(f"Error inserting galaxy {galaxy.name}: {e}")
                self.conn.rollback()
                return None
    
    def get_galaxy_id_by_name(self, name: str) -> Optional[int]:
        """Получение ID галактики по имени"""
        if not name:
            return None
        with self.conn.cursor() as cur:
            cur.execute("SELECT id FROM galaxies WHERE name = %s", (name,))
            result = cur.fetchone()
            return result[0] if result else None
    
    def insert_star(self, star: Star) -> Optional[int]:
        """Вставка звезды, возвращает ID"""
        galaxy_id = star.galaxy_id
        if not galaxy_id and star.galaxy_name:
            galaxy_id = self.get_galaxy_id_by_name(star.galaxy_name)
        
        with self.conn.cursor() as cur:
            try:
                cur.execute("""
                    INSERT INTO stars (name, galaxy_id, mass_solar, temperature_k,
                                       luminosity_solar, radius_solar, spectral_class,
                                       distance_from_sun_ly, age_billion_years, apparent_magnitude)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (name) DO NOTHING
                    RETURNING id
                """, (
                    star.name, galaxy_id, star.mass_solar, star.temperature_k,
                    star.luminosity_solar, star.radius_solar, star.spectral_class,
                    star.distance_from_sun_ly, star.age_billion_years, star.apparent_magnitude
                ))
                result = cur.fetchone()
                self.conn.commit()
                if result:
                    logger.debug(f"Inserted star: {star.name} (ID: {result[0]})")
                return result[0] if result else None
            except Exception as e:
                logger.error(f"Error inserting star {star.name}: {e}")
                self.conn.rollback()
                return None
    
    def get_star_id_by_name(self, name: str) -> Optional[int]:
        """Получение ID звезды по имени"""
        if not name:
            return None
        with self.conn.cursor() as cur:
            cur.execute("SELECT id FROM stars WHERE name = %s", (name,))
            result = cur.fetchone()
            return result[0] if result else None
    
    def insert_planet(self, planet: Planet) -> Optional[int]:
        """Вставка планеты"""
        star_id = self.get_star_id_by_name(planet.star_name)
        if not star_id:
            logger.warning(f"Star '{planet.star_name}' not found for planet '{planet.name}'")
            return None
        
        with self.conn.cursor() as cur:
            try:
                cur.execute("""
                    INSERT INTO planets (name, star_id, planet_type, mass_earth,
                                         diameter_km, orbital_period_days,
                                         distance_from_star_au, surface_temperature_c,
                                         satellites_count, atmosphere_composition)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (name) DO NOTHING
                    RETURNING id
                """, (
                    planet.name, star_id, planet.planet_type, planet.mass_earth,
                    planet.diameter_km, planet.orbital_period_days,
                    planet.distance_from_star_au, planet.surface_temperature_c,
                    planet.satellites_count, planet.atmosphere_composition
                ))
                result = cur.fetchone()
                self.conn.commit()
                if result:
                    logger.debug(f"Inserted planet: {planet.name} (ID: {result[0]})")
                return result[0] if result else None
            except Exception as e:
                logger.error(f"Error inserting planet {planet.name}: {e}")
                self.conn.rollback()
                return None
    
    def insert_satellite(self, satellite: Satellite) -> Optional[int]:
        """Вставка спутника"""
        with self.conn.cursor() as cur:
            cur.execute("SELECT id FROM planets WHERE name = %s", (satellite.planet_name,))
            planet_result = cur.fetchone()
            if not planet_result:
                logger.warning(f"Planet '{satellite.planet_name}' not found for satellite '{satellite.name}'")
                return None
            
            planet_id = planet_result[0]
            
            try:
                cur.execute("""
                    INSERT INTO satellites (name, planet_id, satellite_type, diameter_km,
                                            mass_kg, orbital_period_days, distance_from_planet_km,
                                            temperature_c, discovery_year, discoverer)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (name) DO NOTHING
                    RETURNING id
                """, (
                    satellite.name, planet_id, satellite.satellite_type,
                    satellite.diameter_km, satellite.mass_kg, satellite.orbital_period_days,
                    satellite.distance_from_planet_km, satellite.temperature_c,
                    satellite.discovery_year, satellite.discoverer
                ))
                result = cur.fetchone()
                self.conn.commit()
                if result:
                    logger.debug(f"Inserted satellite: {satellite.name} (ID: {result[0]})")
                return result[0] if result else None
            except Exception as e:
                logger.error(f"Error inserting satellite {satellite.name}: {e}")
                self.conn.rollback()
                return None
    
    def get_statistics(self) -> Dict[str, int]:
        """Получение статистики по таблицам"""
        with self.conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    (SELECT COUNT(*) FROM galaxy_types) as galaxy_types_count,
                    (SELECT COUNT(*) FROM galaxies) as galaxy_count,
                    (SELECT COUNT(*) FROM stars) as star_count,
                    (SELECT COUNT(*) FROM planets) as planet_count,
                    (SELECT COUNT(*) FROM satellites) as satellite_count
            """)
            result = cur.fetchone()
            return {
                'galaxy_types': result[0],
                'galaxies': result[1],
                'stars': result[2],
                'planets': result[3],
                'satellites': result[4]
            }


# =====================================================
# Загрузчики данных из внешних источников
# =====================================================

class NEDGalaxyLoader:
    """Загрузчик галактик из NED"""
    
    def __init__(self):
        self.cache_file = os.path.join(CACHE_DIR, 'ned_galaxies.json')
    
    def _parse_galaxy_type(self, raw_type: str) -> Optional[str]:
        """Преобразование типа из NED в формат БД"""
        if not raw_type:
            return None
        raw_type = raw_type.strip().lower()
        
        if 'elliptical' in raw_type or 'e0' in raw_type or 'e7' in raw_type:
            return 'Elliptical'
        elif 'spiral' in raw_type:
            if 'barred' in raw_type or 'sb' in raw_type:
                return 'Barred Spiral'
            return 'Spiral'
        elif 'lenticular' in raw_type or 's0' in raw_type:
            return 'Lenticular'
        elif 'irregular' in raw_type or 'irr' in raw_type:
            return 'Irregular'
        return None
    
    def load_galaxies(self, galaxy_names: List[str]) -> List[Galaxy]:
        """Загрузка данных о галактиках из NED"""
        galaxies = []
        
        for name in tqdm(galaxy_names, desc="Loading galaxies from NED"):
            try:
                logger.info(f"Querying NED for: {name}")
                result = Ned.query_object(name)
                if result is None or len(result) == 0:
                    logger.warning(f"No data found for galaxy: {name}")
                    continue
                
                row = result[0]
                
                galaxy = Galaxy(
                    name=name,
                    galaxy_type_name=self._parse_galaxy_type(row.get('Type', None)),
                    ned_id=str(row.get('Object Name', name))
                )
                galaxies.append(galaxy)
                logger.info(f"  ✓ Loaded: {name} (Type: {galaxy.galaxy_type_name})")
                
                time.sleep(0.5)
                
            except Exception as e:
                logger.error(f"Error loading galaxy {name}: {e}")
                continue
        
        logger.info(f"✅ Loaded {len(galaxies)} galaxies from NED")
        return galaxies


class GaiaStarLoader:
    """Загрузчик звезд из Gaia DR3"""
    
    def __init__(self):
        Gaia.ROW_LIMIT = 5000
    
    def load_stars_by_names(self, star_names: List[str]) -> List[Star]:
        """Загрузка звезд по названиям"""
        stars = []
        
        for name in tqdm(star_names, desc="Loading stars from Gaia"):
            try:
                # Используем Simbad для получения информации
                simbad_result = Simbad.query_object(name)
                if simbad_result is None or len(simbad_result) == 0:
                    logger.warning(f"Star {name} not found in Simbad")
                    continue
                
                # Извлечение данных из Simbad
                row = simbad_result[0]
                
                star = Star(
                    name=name,
                    mass_solar=None,  # Simbad не всегда дает массу
                    temperature_k=None,
                    luminosity_solar=None,
                    radius_solar=None,
                    spectral_class=row.get('SP_TYPE', None),
                    distance_from_sun_ly=self._parse_distance(row.get('Distance', None)),
                    apparent_magnitude=row.get('FLUX_V', None)
                )
                stars.append(star)
                logger.info(f"  ✓ Loaded: {name} (Spectral: {star.spectral_class})")
                
                time.sleep(0.3)
                
            except Exception as e:
                logger.error(f"Error loading star {name}: {e}")
                continue
        
        logger.info(f"✅ Loaded {len(stars)} stars")
        return stars
    
    def _parse_distance(self, dist_value) -> Optional[float]:
        """Парсинг расстояния"""
        if dist_value is None:
            return None
        try:
            return float(dist_value)
        except (ValueError, TypeError):
            return None


class ExoplanetLoader:
    """Загрузчик экзопланет из NASA Exoplanet Archive"""
    
    def __init__(self):
        self.base_url = "https://exoplanetarchive.ipac.caltech.edu/cgi-bin/nstedAPI/nph-nstedAPI"
    
    def load_exoplanets(self, max_planets: int = 100) -> List[Planet]:
        """Загрузка подтвержденных экзопланет"""
        params = {
            'table': 'exoplanets',
            'format': 'json',
            'select': 'pl_name,hostname,pl_type,pl_massj,pl_rade,pl_orbper,pl_orbsmax,pl_eqt',
            'where': 'pl_confirmed=1'
        }
        
        try:
            logger.info(f"Fetching exoplanets from NASA Exoplanet Archive...")
            response = requests.get(self.base_url, params=params, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            planets = []
            for item in data[:max_planets]:
                planet = Planet(
                    name=item.get('pl_name', ''),
                    star_name=item.get('hostname', ''),
                    planet_type=self._parse_planet_type(item.get('pl_type', '')),
                    mass_earth=self._mass_jupiter_to_earth(item.get('pl_massj')),
                    diameter_km=self._radius_earth_to_km(item.get('pl_rade')),
                    orbital_period_days=item.get('pl_orbper'),
                    distance_from_star_au=item.get('pl_orbsmax'),
                    surface_temperature_c=self._kelvin_to_celsius(item.get('pl_eqt'))
                )
                if planet.name and planet.star_name:
                    planets.append(planet)
            
            logger.info(f"✅ Loaded {len(planets)} exoplanets")
            return planets
            
        except Exception as e:
            logger.error(f"Error loading exoplanets: {e}")
            return []
    
    def _mass_jupiter_to_earth(self, mass_jupiter: Optional[float]) -> Optional[float]:
        if mass_jupiter is None:
            return None
        return mass_jupiter * 317.8
    
    def _radius_earth_to_km(self, radius_earth: Optional[float]) -> Optional[int]:
        if radius_earth is None:
            return None
        return int(radius_earth * 6371)
    
    def _kelvin_to_celsius(self, kelvin: Optional[float]) -> Optional[str]:
        if kelvin is None:
            return None
        celsius = kelvin - 273.15
        return f"{celsius:.0f}"
    
    def _parse_planet_type(self, pl_type: str) -> Optional[str]:
        if not pl_type:
            return None
        pl_type = pl_type.lower()
        if 'terrestrial' in pl_type or 'rocky' in pl_type:
            return 'Земная'
        elif 'jupiter' in pl_type or 'giant' in pl_type:
            return 'Газовый гигант'
        elif 'neptune' in pl_type or 'ice' in pl_type:
            return 'Ледяной гигант'
        return 'Земная'


class SatelliteLoader:
    """Загрузчик спутников"""
    
    def load_satellites(self) -> List[Satellite]:
        """Загрузка данных о спутниках Солнечной системы"""
        satellites_data = [
            Satellite(name='Луна', planet_name='Земля', satellite_type='Скалистый',
                      diameter_km=3474, mass_kg='7.35×10²²', orbital_period_days=27.3,
                      distance_from_planet_km=384400, temperature_c='-173 до 127',
                      discovery_year=None, discoverer='-'),
            Satellite(name='Фобос', planet_name='Марс', satellite_type='Скалистый',
                      diameter_km=22.2, mass_kg='1.07×10¹⁶', orbital_period_days=0.32,
                      distance_from_planet_km=9377, temperature_c='-4 до -112',
                      discovery_year=1877, discoverer='Асаф Холл'),
            Satellite(name='Деймос', planet_name='Марс', satellite_type='Скалистый',
                      diameter_km=12.6, mass_kg='1.48×10¹⁵', orbital_period_days=1.26,
                      distance_from_planet_km=23460, temperature_c='-112',
                      discovery_year=1877, discoverer='Асаф Холл'),
            Satellite(name='Ио', planet_name='Юпитер', satellite_type='Скалистый',
                      diameter_km=3643, mass_kg='8.93×10²²', orbital_period_days=1.77,
                      distance_from_planet_km=421700, temperature_c='-130 до 1600',
                      discovery_year=1610, discoverer='Галилео Галилей'),
            Satellite(name='Европа', planet_name='Юпитер', satellite_type='Ледяной',
                      diameter_km=3122, mass_kg='4.80×10²²', orbital_period_days=3.55,
                      distance_from_planet_km=671000, temperature_c='-160',
                      discovery_year=1610, discoverer='Галилео Галилей'),
            Satellite(name='Ганимед', planet_name='Юпитер', satellite_type='Ледяной',
                      diameter_km=5268, mass_kg='1.48×10²³', orbital_period_days=7.15,
                      distance_from_planet_km=1070000, temperature_c='-160',
                      discovery_year=1610, discoverer='Галилео Галилей'),
            Satellite(name='Каллисто', planet_name='Юпитер', satellite_type='Ледяной',
                      diameter_km=4821, mass_kg='1.08×10²³', orbital_period_days=16.69,
                      distance_from_planet_km=1883000, temperature_c='-140',
                      discovery_year=1610, discoverer='Галилео Галилей'),
            Satellite(name='Титан', planet_name='Сатурн', satellite_type='Ледяной',
                      diameter_km=5150, mass_kg='1.35×10²³', orbital_period_days=15.95,
                      distance_from_planet_km=1221870, temperature_c='-179',
                      discovery_year=1655, discoverer='Христиан Гюйгенс'),
            Satellite(name='Тритон', planet_name='Нептун', satellite_type='Ледяной',
                      diameter_km=2707, mass_kg='2.14×10²²', orbital_period_days=5.88,
                      distance_from_planet_km=354759, temperature_c='-235',
                      discovery_year=1846, discoverer='Уильям Лассел'),
        ]
        
        logger.info(f"✅ Loaded {len(satellites_data)} satellites")
        return satellites_data


# =====================================================
# Основной ETL процесс
# =====================================================

class AstronomyETL:
    """Основной класс ETL для загрузки астрономических данных"""
    
    def __init__(self, db_config: Dict):
        self.db = AstronomyDatabase(db_config)
        self.ned_loader = NEDGalaxyLoader()
        self.gaia_loader = GaiaStarLoader()
        self.exoplanet_loader = ExoplanetLoader()
        self.satellite_loader = SatelliteLoader()
    
    def run(self, galaxy_names: List[str], star_names: List[str] = None, 
            load_exoplanets: bool = True, load_satellites: bool = True):
        """Запуск полного ETL процесса"""
        logger.info("=" * 60)
        logger.info("🚀 Starting Astronomy ETL Process")
        logger.info("=" * 60)
        
        try:
            # Шаг 1: Загрузка галактик из NED
            logger.info("\n📡 Step 1: Loading galaxies from NED")
            logger.info("-" * 40)
            galaxies = self.ned_loader.load_galaxies(galaxy_names)
            
            for galaxy in galaxies:
                self.db.insert_galaxy(galaxy)
            
            # Шаг 2: Загрузка звезд
            logger.info("\n⭐ Step 2: Loading stars")
            logger.info("-" * 40)
            if star_names:
                stars = self.gaia_loader.load_stars_by_names(star_names)
                for star in stars:
                    self.db.insert_star(star)
            else:
                logger.info("No star names provided, skipping star loading")
            
            # Шаг 3: Загрузка экзопланет
            if load_exoplanets:
                logger.info("\n🪐 Step 3: Loading exoplanets")
                logger.info("-" * 40)
                planets = self.exoplanet_loader.load_exoplanets(max_planets=50)
                for planet in planets:
                    self.db.insert_planet(planet)
            
            # Шаг 4: Загрузка спутников
            if load_satellites:
                logger.info("\n🌙 Step 4: Loading satellites")
                logger.info("-" * 40)
                satellites = self.satellite_loader.load_satellites()
                for satellite in satellites:
                    self.db.insert_satellite(satellite)
            
            # Шаг 5: Итоговая статистика
            logger.info("\n📊 Step 5: Final Statistics")
            logger.info("-" * 40)
            stats = self.db.get_statistics()
            logger.info(f"  Galaxy Types: {stats['galaxy_types']}")
            logger.info(f"  Galaxies: {stats['galaxies']}")
            logger.info(f"  Stars: {stats['stars']}")
            logger.info(f"  Planets: {stats['planets']}")
            logger.info(f"  Satellites: {stats['satellites']}")
            
            logger.info("\n" + "=" * 60)
            logger.info("✅ ETL Process Completed Successfully!")
            logger.info("=" * 60)
            
        except Exception as e:
            logger.error(f"❌ ETL process failed: {e}")
            raise
        finally:
            self.db.close()


# =====================================================
# Точка входа
# =====================================================

def main():
    """Основная функция"""
    
    # Список галактик для загрузки
    galaxy_list = [
        'Млечный Путь',
        'Андромеда (M31)',
        'Треугольник (M33)',
        'Центавр A (NGC 5128)',
        'Водоворот (M51)'
    ]
    
    # Список звезд для загрузки
    star_list = [
        'Солнце',
        'Сириус',
        'Бетельгейзе',
        'Проксима Центавра',
        'Вега',
        'Альфа Центавра A'
    ]
    
    # Вывод конфигурации
    logger.info("Configuration:")
    logger.info(f"  PostgreSQL: {DB_CONFIG['host']}:{DB_CONFIG['port']}")
    logger.info(f"  Database: {DB_CONFIG['database']}")
    logger.info(f"  User: {DB_CONFIG['user']}")
    logger.info(f"  Galaxies to load: {len(galaxy_list)}")
    logger.info(f"  Stars to load: {len(star_list)}")
    
    # Запуск ETL
    etl = AstronomyETL(DB_CONFIG)
    etl.run(
        galaxy_names=galaxy_list,
        star_names=star_list,
        load_exoplanets=True,
        load_satellites=True
    )


if __name__ == "__main__":
    main()