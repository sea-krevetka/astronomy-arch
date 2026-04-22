#!/usr/bin/env python3
"""
Celestial Bodies Data Importer for Astronomy Catalog
Fixed version - no ON CONFLICT issues
"""

import os
import requests
import json
import psycopg2
from datetime import datetime
import logging
from typing import Dict, List, Any, Optional
import argparse
import re
import time

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class CelestialDataImporter:
    """Import celestial data into PostgreSQL database"""
    
    def __init__(self, db_params: Dict):
        self.db_params = db_params
        
        # JPL body IDs mapping
        self.body_ids = {
            'Mercury': '199',
            'Venus': '299',
            'Earth': '399',
            'Mars': '499',
            'Jupiter': '599',
            'Saturn': '699',
            'Uranus': '799',
            'Neptune': '899'
        }
        
        # Default data for planets (since JPL API might be slow/unavailable)
        self.planets_default_data = {
            'Mercury': {
                'planet_type': 'Земная',
                'mass_earth': 0.055,
                'diameter_km': 4879,
                'orbital_period_days': 87.97,
                'distance_from_star_au': 0.387,
                'surface_temperature_c': '167°C',
                'satellites_count': 0,
                'atmosphere_composition': 'Кислород, натрий, гелий'
            },
            'Venus': {
                'planet_type': 'Земная',
                'mass_earth': 0.815,
                'diameter_km': 12104,
                'orbital_period_days': 224.7,
                'distance_from_star_au': 0.723,
                'surface_temperature_c': '462°C',
                'satellites_count': 0,
                'atmosphere_composition': 'Углекислый газ, азот'
            },
            'Earth': {
                'planet_type': 'Земная',
                'mass_earth': 1.0,
                'diameter_km': 12742,
                'orbital_period_days': 365.25,
                'distance_from_star_au': 1.0,
                'surface_temperature_c': '15°C',
                'satellites_count': 1,
                'atmosphere_composition': 'Азот, кислород, аргон'
            },
            'Mars': {
                'planet_type': 'Земная',
                'mass_earth': 0.107,
                'diameter_km': 6779,
                'orbital_period_days': 687.0,
                'distance_from_star_au': 1.524,
                'surface_temperature_c': '-65°C',
                'satellites_count': 2,
                'atmosphere_composition': 'Углекислый газ, аргон, азот'
            },
            'Jupiter': {
                'planet_type': 'Газовый гигант',
                'mass_earth': 317.8,
                'diameter_km': 139820,
                'orbital_period_days': 4333.0,
                'distance_from_star_au': 5.203,
                'surface_temperature_c': '-110°C',
                'satellites_count': 79,
                'atmosphere_composition': 'Водород, гелий'
            },
            'Saturn': {
                'planet_type': 'Газовый гигант',
                'mass_earth': 95.2,
                'diameter_km': 116460,
                'orbital_period_days': 10759.0,
                'distance_from_star_au': 9.537,
                'surface_temperature_c': '-140°C',
                'satellites_count': 82,
                'atmosphere_composition': 'Водород, гелий'
            },
            'Uranus': {
                'planet_type': 'Ледяной гигант',
                'mass_earth': 14.5,
                'diameter_km': 50724,
                'orbital_period_days': 30687.0,
                'distance_from_star_au': 19.191,
                'surface_temperature_c': '-195°C',
                'satellites_count': 27,
                'atmosphere_composition': 'Водород, гелий, метан'
            },
            'Neptune': {
                'planet_type': 'Ледяной гигант',
                'mass_earth': 17.1,
                'diameter_km': 49244,
                'orbital_period_days': 60190.0,
                'distance_from_star_au': 30.069,
                'surface_temperature_c': '-200°C',
                'satellites_count': 14,
                'atmosphere_composition': 'Водород, гелий, метан'
            }
        }
        
        # Satellites data
        self.satellites_data = {
            'Moon': {'planet': 'Earth', 'satellite_type': 'Скалистый', 'diameter_km': 3474, 
                    'mass_kg': '7.35e22', 'orbital_period_days': 27.3, 'distance_from_planet_km': 384400,
                    'temperature_c': '-20°C', 'discovery_year': None, 'discoverer': 'Prehistoric'},
            'Phobos': {'planet': 'Mars', 'satellite_type': 'Скалистый', 'diameter_km': 22.2,
                    'mass_kg': '1.06e16', 'orbital_period_days': 0.32, 'distance_from_planet_km': 9376,
                    'temperature_c': '-40°C', 'discovery_year': 1877, 'discoverer': 'Asaph Hall'},
            'Deimos': {'planet': 'Mars', 'satellite_type': 'Скалистый', 'diameter_km': 12.6,
                    'mass_kg': '1.48e15', 'orbital_period_days': 1.26, 'distance_from_planet_km': 23460,
                    'temperature_c': '-40°C', 'discovery_year': 1877, 'discoverer': 'Asaph Hall'},
            'Io': {'planet': 'Jupiter', 'satellite_type': 'Ледяной', 'diameter_km': 3643,
                    'mass_kg': '8.93e22', 'orbital_period_days': 1.77, 'distance_from_planet_km': 421800,
                    'temperature_c': '-130°C', 'discovery_year': 1610, 'discoverer': 'Galileo Galilei'},
            'Europa': {'planet': 'Jupiter', 'satellite_type': 'Ледяной', 'diameter_km': 3121,
                    'mass_kg': '4.80e22', 'orbital_period_days': 3.55, 'distance_from_planet_km': 671100,
                    'temperature_c': '-160°C', 'discovery_year': 1610, 'discoverer': 'Galileo Galilei'},
            'Ganymede': {'planet': 'Jupiter', 'satellite_type': 'Ледяной', 'diameter_km': 5268,
                    'mass_kg': '1.48e23', 'orbital_period_days': 7.15, 'distance_from_planet_km': 1070400,
                    'temperature_c': '-120°C', 'discovery_year': 1610, 'discoverer': 'Galileo Galilei'},
            'Callisto': {'planet': 'Jupiter', 'satellite_type': 'Ледяной', 'diameter_km': 4821,
                    'mass_kg': '1.08e23', 'orbital_period_days': 16.69, 'distance_from_planet_km': 1882700,
                    'temperature_c': '-130°C', 'discovery_year': 1610, 'discoverer': 'Galileo Galilei'},
            'Titan': {'planet': 'Saturn', 'satellite_type': 'Ледяной', 'diameter_km': 5150,
                    'mass_kg': '1.35e23', 'orbital_period_days': 15.95, 'distance_from_planet_km': 1221870,
                    'temperature_c': '-179°C', 'discovery_year': 1655, 'discoverer': 'Christiaan Huygens'},
            'Triton': {'planet': 'Neptune', 'satellite_type': 'Ледяной', 'diameter_km': 2707,
                    'mass_kg': '2.14e22', 'orbital_period_days': 5.88, 'distance_from_planet_km': 354759,
                    'temperature_c': '-235°C', 'discovery_year': 1846, 'discoverer': 'William Lassell'}
        }
        
        # Galaxy types data
        self.galaxy_types_data = [
            ('Спиральная', 'Галактики с плоским вращающимся диском, центральным балджем и спиральными рукавами',
             'Плоский диск со спиральными рукавами', 'Молодые и старые звезды', 'Активная в рукавах',
             'От 5 до 300 кпк, 10^9-10^12 M☉', 'Голубовато-белый в рукавах, желтоватый в центре',
             'Часто в группах и скоплениях', 'Формируются из вращающихся протогалактических облаков'),
            ('Эллиптическая', 'Галактики с гладким эллипсоидальным распределением звезд',
             'Эллипсоидальная, без диска', 'Старые звезды', 'Низкая или отсутствует',
             'От 1 до 200 кпк, 10^6-10^12 M☉', 'Красноватый', 'В центрах скоплений галактик',
             'Результат слияний спиральных галактик'),
            ('Неправильная', 'Галактики без правильной формы', 'Аморфная, без четкой структуры',
             'Смешанное население', 'Активная', 'От 1 до 10 кпк, 10^8-10^10 M☉',
             'Голубоватый', 'Часто в группах', 'Результат гравитационных взаимодействий')
        ]
    
    def get_db_connection(self):
        """Create database connection"""
        return psycopg2.connect(**self.db_params)
    
    def clear_all_data(self):
        """Clear all existing data before import"""
        try:
            with self.get_db_connection() as conn:
                with conn.cursor() as cur:
                    # Disable foreign key checks
                    cur.execute("SET session_replication_role = replica;")
                    
                    # Truncate all tables in correct order
                    cur.execute("TRUNCATE TABLE satellites CASCADE;")
                    cur.execute("TRUNCATE TABLE planets CASCADE;")
                    cur.execute("TRUNCATE TABLE stars CASCADE;")
                    cur.execute("TRUNCATE TABLE galaxies CASCADE;")
                    cur.execute("TRUNCATE TABLE galaxy_types CASCADE;")
                    
                    # Re-enable foreign key checks
                    cur.execute("SET session_replication_role = DEFAULT;")
                    
                    conn.commit()
                    logger.info("Existing data cleared successfully")
        except Exception as e:
            logger.error(f"Error clearing data: {e}")
            raise
    
    def initialize_galaxy_types(self):
        """Initialize galaxy types table"""
        try:
            with self.get_db_connection() as conn:
                with conn.cursor() as cur:
                    for gt in self.galaxy_types_data:
                        cur.execute("""
                            INSERT INTO galaxy_types (name, description, structure_shape, 
                                                    stellar_population, star_formation, 
                                                    size_mass, color, spatial_distribution, origin)
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                        """, gt)
                    conn.commit()
                    logger.info("Galaxy types initialized successfully")
        except Exception as e:
            logger.error(f"Error initializing galaxy types: {e}")
            raise
    
    def insert_galaxy_data(self):
        """Insert Milky Way galaxy data"""
        try:
            with self.get_db_connection() as conn:
                with conn.cursor() as cur:
                    # Get galaxy type ID
                    cur.execute("SELECT id FROM galaxy_types WHERE name = 'Спиральная'")
                    result = cur.fetchone()
                    if not result:
                        logger.error("Galaxy type 'Спиральная' not found")
                        return False
                    
                    galaxy_type_id = result[0]
                    
                    # Check if galaxy already exists
                    cur.execute("SELECT id FROM galaxies WHERE name = 'Milky Way'")
                    exists = cur.fetchone()
                    
                    if exists:
                        # Update existing
                        cur.execute("""
                            UPDATE galaxies 
                            SET galaxy_type_id = %s, diameter_ly = %s, star_count = %s,
                                mass_solar_masses = %s, distance_from_earth_ly = %s,
                                age_billion_years = %s, metallicity = %s, 
                                rotation_speed_kms = %s, discovery_year = %s
                            WHERE name = 'Milky Way'
                        """, (galaxy_type_id, 105000, '100-400 миллиардов', '1.5 трлн',
                              0, 13.6, 'Средняя', 220, -3500))
                    else:
                        # Insert new
                        cur.execute("""
                            INSERT INTO galaxies (name, galaxy_type_id, diameter_ly, star_count,
                                                mass_solar_masses, distance_from_earth_ly,
                                                age_billion_years, metallicity, rotation_speed_kms,
                                                discovery_year)
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                        """, ('Milky Way', galaxy_type_id, 105000, '100-400 миллиардов', 
                              '1.5 трлн', 0, 13.6, 'Средняя', 220, -3500))
                    
                    conn.commit()
                    logger.info("Milky Way galaxy data inserted successfully")
                    return True
                    
        except Exception as e:
            logger.error(f"Error inserting galaxy data: {e}")
            return False
    
    def insert_star_data(self):
        """Insert Sun data"""
        try:
            with self.get_db_connection() as conn:
                with conn.cursor() as cur:
                    # Get Milky Way galaxy ID
                    cur.execute("SELECT id FROM galaxies WHERE name = 'Milky Way'")
                    result = cur.fetchone()
                    if not result:
                        logger.error("Milky Way galaxy not found")
                        return False
                    
                    galaxy_id = result[0]
                    
                    # Check if star already exists
                    cur.execute("SELECT id FROM stars WHERE name = 'Sun'")
                    exists = cur.fetchone()
                    
                    if exists:
                        # Update existing
                        cur.execute("""
                            UPDATE stars 
                            SET galaxy_id = %s, mass_solar = %s, temperature_k = %s,
                                luminosity_solar = %s, radius_solar = %s, spectral_class = %s,
                                distance_from_sun_ly = %s, age_billion_years = %s, 
                                apparent_magnitude = %s
                            WHERE name = 'Sun'
                        """, (galaxy_id, 1.0, 5778, 1.0, 1.0, 'G2V', 0, 4.603, -26.74))
                    else:
                        # Insert new
                        cur.execute("""
                            INSERT INTO stars (name, galaxy_id, mass_solar, temperature_k,
                                             luminosity_solar, radius_solar, spectral_class,
                                             distance_from_sun_ly, age_billion_years, apparent_magnitude)
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                        """, ('Sun', galaxy_id, 1.0, 5778, 1.0, 1.0, 'G2V', 0, 4.603, -26.74))
                    
                    conn.commit()
                    logger.info("Sun data inserted successfully")
                    return True
                    
        except Exception as e:
            logger.error(f"Error inserting star data: {e}")
            return False
    
    def insert_planet_data(self):
        """Insert all planets data"""
        try:
            with self.get_db_connection() as conn:
                with conn.cursor() as cur:
                    # Get Sun star ID
                    cur.execute("SELECT id FROM stars WHERE name = 'Sun'")
                    result = cur.fetchone()
                    if not result:
                        logger.error("Sun star not found")
                        return False
                    
                    sun_id = result[0]
                    
                    for planet_name, planet_data in self.planets_default_data.items():
                        # Check if planet already exists
                        cur.execute("SELECT id FROM planets WHERE name = %s", (planet_name,))
                        exists = cur.fetchone()
                        
                        if exists:
                            # Update existing
                            cur.execute("""
                                UPDATE planets 
                                SET star_id = %s, planet_type = %s, mass_earth = %s,
                                    diameter_km = %s, orbital_period_days = %s,
                                    distance_from_star_au = %s, surface_temperature_c = %s,
                                    satellites_count = %s, atmosphere_composition = %s
                                WHERE name = %s
                            """, (sun_id, planet_data['planet_type'], planet_data['mass_earth'],
                                  planet_data['diameter_km'], planet_data['orbital_period_days'],
                                  planet_data['distance_from_star_au'], planet_data['surface_temperature_c'],
                                  planet_data['satellites_count'], planet_data['atmosphere_composition'],
                                  planet_name))
                        else:
                            # Insert new
                            cur.execute("""
                                INSERT INTO planets (name, star_id, planet_type, mass_earth, 
                                                   diameter_km, orbital_period_days, 
                                                   distance_from_star_au, surface_temperature_c,
                                                   satellites_count, atmosphere_composition)
                                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                            """, (planet_name, sun_id, planet_data['planet_type'], 
                                  planet_data['mass_earth'], planet_data['diameter_km'],
                                  planet_data['orbital_period_days'], planet_data['distance_from_star_au'],
                                  planet_data['surface_temperature_c'], planet_data['satellites_count'],
                                  planet_data['atmosphere_composition']))
                        
                        logger.info(f"Planet {planet_name} inserted/updated successfully")
                    
                    conn.commit()
                    return True
                    
        except Exception as e:
            logger.error(f"Error inserting planets: {e}")
            return False
    
    def insert_satellites_data(self):
        """Insert satellites data"""
        try:
            with self.get_db_connection() as conn:
                with conn.cursor() as cur:
                    for satellite_name, satellite_data in self.satellites_data.items():
                        # Get planet ID
                        cur.execute("SELECT id FROM planets WHERE name = %s", (satellite_data['planet'],))
                        result = cur.fetchone()
                        
                        if not result:
                            logger.warning(f"Planet {satellite_data['planet']} not found for satellite {satellite_name}")
                            continue
                        
                        planet_id = result[0]
                        
                        # Check if satellite already exists
                        cur.execute("SELECT id FROM satellites WHERE name = %s", (satellite_name,))
                        exists = cur.fetchone()
                        
                        if exists:
                            # Update existing
                            cur.execute("""
                                UPDATE satellites 
                                SET planet_id = %s, satellite_type = %s, diameter_km = %s,
                                    mass_kg = %s, orbital_period_days = %s,
                                    distance_from_planet_km = %s, temperature_c = %s,
                                    discovery_year = %s, discoverer = %s
                                WHERE name = %s
                            """, (planet_id, satellite_data['satellite_type'], 
                                  satellite_data['diameter_km'], satellite_data['mass_kg'],
                                  satellite_data['orbital_period_days'], satellite_data['distance_from_planet_km'],
                                  satellite_data['temperature_c'], satellite_data['discovery_year'],
                                  satellite_data['discoverer'], satellite_name))
                        else:
                            # Insert new
                            cur.execute("""
                                INSERT INTO satellites (name, planet_id, satellite_type, 
                                                      diameter_km, mass_kg, orbital_period_days,
                                                      distance_from_planet_km, temperature_c,
                                                      discovery_year, discoverer)
                                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                            """, (satellite_name, planet_id, satellite_data['satellite_type'],
                                  satellite_data['diameter_km'], satellite_data['mass_kg'],
                                  satellite_data['orbital_period_days'], satellite_data['distance_from_planet_km'],
                                  satellite_data['temperature_c'], satellite_data['discovery_year'],
                                  satellite_data['discoverer']))
                        
                        logger.info(f"Satellite {satellite_name} inserted/updated successfully")
                    
                    conn.commit()
                    return True
                    
        except Exception as e:
            logger.error(f"Error inserting satellites: {e}")
            return False
    
    def update_satellite_counts(self):
        """Update satellite counts for planets"""
        try:
            with self.get_db_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        UPDATE planets p
                        SET satellites_count = (
                            SELECT COUNT(*)
                            FROM satellites s
                            WHERE s.planet_id = p.id
                        )
                    """)
                    conn.commit()
                    logger.info("Satellite counts updated successfully")
        except Exception as e:
            logger.error(f"Error updating satellite counts: {e}")
    
    def import_all_data(self):
        """Import all data in correct order"""
        logger.info("Starting complete data import...")
        
        try:
            # Step 1: Clear existing data
            self.clear_all_data()
            
            # Step 2: Initialize base data
            self.initialize_galaxy_types()
            self.insert_galaxy_data()
            self.insert_star_data()
            
            # Step 3: Import planets
            logger.info("Importing planets...")
            self.insert_planet_data()
            
            # Step 4: Import satellites
            logger.info("Importing satellites...")
            self.insert_satellites_data()
            
            # Step 5: Update satellite counts
            self.update_satellite_counts()
            
            logger.info("✅ All data import completed successfully!")
            self.show_summary()
            
        except Exception as e:
            logger.error(f"Import failed: {e}")
            raise
    
    def show_summary(self):
        """Show import summary"""
        try:
            with self.get_db_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT COUNT(*) FROM galaxies")
                    galaxies_count = cur.fetchone()[0]
                    
                    cur.execute("SELECT COUNT(*) FROM stars")
                    stars_count = cur.fetchone()[0]
                    
                    cur.execute("SELECT COUNT(*) FROM planets")
                    planets_count = cur.fetchone()[0]
                    
                    cur.execute("SELECT COUNT(*) FROM satellites")
                    satellites_count = cur.fetchone()[0]
                    
                    logger.info("\n📊 Import Summary:")
                    logger.info(f"  Galaxies: {galaxies_count}")
                    logger.info(f"  Stars: {stars_count}")
                    logger.info(f"  Planets: {planets_count}")
                    logger.info(f"  Satellites: {satellites_count}")
                    
        except Exception as e:
            logger.error(f"Error showing summary: {e}")

def main():
    parser = argparse.ArgumentParser(description='Import celestial data from JPL Horizons')
    parser.add_argument('--db-host', default=os.getenv('DB_HOST', 'localhost'))
    parser.add_argument('--db-port', default=os.getenv('DB_PORT', '5433'))
    parser.add_argument('--db-name', default=os.getenv('DB_NAME', 'astronomy_catalog'))
    parser.add_argument('--db-user', default=os.getenv('DB_USER', 'astronomy_admin'))
    parser.add_argument('--db-password', required=True, help='Database password')
    parser.add_argument('--import-all', action='store_true', help='Import all data')
    
    args = parser.parse_args()
    
    db_params = {
        'host': args.db_host,
        'port': args.db_port,
        'dbname': args.db_name,
        'user': args.db_user,
        'password': args.db_password
    }
    
    importer = CelestialDataImporter(db_params)
    
    if args.import_all:
        importer.import_all_data()
    else:
        print("Please specify --import-all to import all data")

if __name__ == "__main__":
    main()