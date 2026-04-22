import requests
import psycopg2
import time
import os
import sys
from datetime import datetime
import logging
from typing import Optional, Dict, Any, List

# =====================================================
# Конфигурация подключения к БД
# =====================================================
DB_CONFIG = {
    'dbname': os.getenv('POSTGRES_DB', 'astronomy_catalog'),
    'user': os.getenv('POSTGRES_USER', 'astronomy_admin'),
    'password': os.getenv('POSTGRES_PASSWORD', 'Astronomy2024!'),
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('POSTGRES_PORT', '5433')
}

# =====================================================
# Настройка логирования
# =====================================================
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('sbdb_import.log', encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Базовый URL JPL SBDB API
API_URL = "https://ssd-api.jpl.nasa.gov/sbdb.api"

class SBDatabaseImporter:
    """Класс для импорта данных малых тел из JPL SBDB API"""
    
    def __init__(self, db_config: Dict[str, str]):
        self.db_config = db_config
        self.conn = None
        self.stats = {
            'total_processed': 0,
            'successful': 0,
            'failed': 0,
            'skipped': 0
        }
    
    def connect(self) -> bool:
        """Установка соединения с базой данных"""
        try:
            self.conn = psycopg2.connect(**self.db_config)
            logger.info(f"[OK] Подключение к БД {self.db_config['dbname']} на {self.db_config['host']}:{self.db_config['port']} успешно")
            return True
        except Exception as e:
            logger.error(f"[ERROR] Ошибка подключения к БД: {e}")
            return False
    
    def disconnect(self):
        """Закрытие соединения"""
        if self.conn:
            self.conn.close()
            logger.info("Соединение с БД закрыто")
    
    def _safe_get_dict_value(self, data: Any, key: str, default=None):
        """Безопасное получение значения из словаря или списка"""
        if isinstance(data, dict):
            return data.get(key, default)
        elif isinstance(data, list):
            # Если это список словарей, ищем первый с нужным ключом
            for item in data:
                if isinstance(item, dict) and key in item:
                    return item[key]
        return default
    
    def _parse_physical_parameters(self, phys_data: Any) -> Dict[str, Any]:
        """Парсинг физических параметров из разных форматов"""
        result = {
            'diameter': None,
            'rot_per': None,
            'albedo': None,
            'spec_T': None,
            'H': None
        }
        
        if phys_data is None:
            return result
        
        # Если это список (как в реальном API)
        if isinstance(phys_data, list):
            for param in phys_data:
                if not isinstance(param, dict):
                    continue
                    
                name = param.get('name', '').lower()
                value = param.get('value')
                
                if name == 'diameter':
                    result['diameter'] = value
                elif name == 'rot_per':
                    result['rot_per'] = value
                elif name == 'albedo':
                    result['albedo'] = value
                elif name == 'spec_t':
                    result['spec_T'] = value
                elif name == 'h':
                    result['H'] = value
        # Если это словарь (старый формат)
        elif isinstance(phys_data, dict):
            result['diameter'] = phys_data.get('diameter')
            result['rot_per'] = phys_data.get('rot_per')
            result['albedo'] = phys_data.get('albedo')
            result['spec_T'] = phys_data.get('spec_T')
            result['H'] = phys_data.get('H')
        
        return result
    
    def fetch_object_data(self, search_term: str) -> Optional[Dict[str, Any]]:
        """Запрашивает данные объекта через API JPL."""
        params = {
            'sstr': search_term.strip(),
            'phys-par': 'true',
            'discovery': 'true'
        }
        
        try:
            logger.info(f"[REQUEST] Запрос данных для: {search_term}")
            response = requests.get(API_URL, params=params, timeout=30)
            
            if response.status_code != 200:
                logger.error(f"[HTTP {response.status_code}] Ошибка для {search_term}: {response.text[:200]}")
                return None
            
            data = response.json()
            
            if 'error' in data:
                logger.error(f"[API ERROR] {search_term}: {data['error']}")
                return None
                
            return data
            
        except requests.exceptions.Timeout:
            logger.error(f"[TIMEOUT] Таймаут запроса для {search_term}")
        except requests.exceptions.RequestException as e:
            logger.error(f"[NETWORK] Сетевая ошибка для {search_term}: {e}")
        except ValueError as e:
            logger.error(f"[JSON] Ошибка парсинга для {search_term}: {e}")
        
        return None
    
    def parse_and_insert(self, data: Dict[str, Any]) -> bool:
        """Парсит JSON ответ API и вставляет/обновляет данные в таблице small_bodies."""
        if not data or 'object' not in data:
            logger.warning("Нет данных объекта в ответе API")
            return False
        
        obj = data['object']
        
        # Обработка случая, когда 'object' возвращается как список
        if isinstance(obj, list):
            if not obj:
                logger.warning("Пустой список объектов в ответе API")
                return False
            obj = obj[0]
        
        # Пропускаем объекты без орбитальных данных
        if 'orbit' not in data:
            logger.warning(f"Пропуск {obj.get('fullname')}: нет орбитальных данных")
            self.stats['skipped'] += 1
            return False
        
        orbit_data = data['orbit']
        
        # Определяем тип тела
        kind_map = {
            'an': 'Asteroid',
            'cn': 'Comet',
            'dn': 'Dwarf Planet'
        }
        body_type = kind_map.get(obj.get('kind'))
        
        # Парсим физические параметры (исправлено)
        phys_raw = data.get('phys_par')
        phys = self._parse_physical_parameters(phys_raw)
        
        # Данные об открытии
        disc = data.get('discovery', {})
        if isinstance(disc, list) and disc:
            disc = disc[0] if isinstance(disc[0], dict) else {}
        elif not isinstance(disc, dict):
            disc = {}
        
        # Формируем SQL для UPSERT
        sql = """
        INSERT INTO small_bodies (
            name, spk_id, designation, body_type,
            epoch_jd, eccentricity, semi_major_axis_au, perihelion_au, aphelion_au,
            inclination_deg, arg_periapsis_deg, long_asc_node_deg, mean_anomaly_deg,
            orbital_period_days, diameter_km, rotation_period_h, albedo,
            spectral_type, magnitude_h, discovery_date, discovery_site, discoverer,
            is_pha, data_source
        ) VALUES (
            %(name)s, %(spk_id)s, %(designation)s, %(body_type)s,
            %(epoch_jd)s, %(eccentricity)s, %(semi_major_axis_au)s, %(perihelion_au)s, %(aphelion_au)s,
            %(inclination_deg)s, %(arg_periapsis_deg)s, %(long_asc_node_deg)s, %(mean_anomaly_deg)s,
            %(orbital_period_days)s, %(diameter_km)s, %(rotation_period_h)s, %(albedo)s,
            %(spectral_type)s, %(magnitude_h)s, %(discovery_date)s, %(discovery_site)s, %(discoverer)s,
            %(is_pha)s, %(data_source)s
        )
        ON CONFLICT (spk_id) DO UPDATE SET
            name = EXCLUDED.name,
            designation = EXCLUDED.designation,
            body_type = EXCLUDED.body_type,
            epoch_jd = EXCLUDED.epoch_jd,
            eccentricity = EXCLUDED.eccentricity,
            semi_major_axis_au = EXCLUDED.semi_major_axis_au,
            perihelion_au = EXCLUDED.perihelion_au,
            aphelion_au = EXCLUDED.aphelion_au,
            inclination_deg = EXCLUDED.inclination_deg,
            arg_periapsis_deg = EXCLUDED.arg_periapsis_deg,
            long_asc_node_deg = EXCLUDED.long_asc_node_deg,
            mean_anomaly_deg = EXCLUDED.mean_anomaly_deg,
            orbital_period_days = EXCLUDED.orbital_period_days,
            diameter_km = EXCLUDED.diameter_km,
            rotation_period_h = EXCLUDED.rotation_period_h,
            albedo = EXCLUDED.albedo,
            spectral_type = EXCLUDED.spectral_type,
            magnitude_h = EXCLUDED.magnitude_h,
            discovery_date = EXCLUDED.discovery_date,
            discovery_site = EXCLUDED.discovery_site,
            discoverer = EXCLUDED.discoverer,
            is_pha = EXCLUDED.is_pha,
            data_source = EXCLUDED.data_source,
            last_updated = CURRENT_TIMESTAMP
        RETURNING id;
        """
        
        # Подготовка параметров
        designation = obj.get('des') or obj.get('designation')
        
        # Получаем абсолютную магнитуду (может быть в object или в phys)
        magnitude_h = phys.get('H') or obj.get('H')
        
        # Конвертируем строковые значения в числа где нужно
        try:
            diameter = float(phys['diameter']) if phys.get('diameter') else None
        except (TypeError, ValueError):
            diameter = None
            
        try:
            rot_period = float(phys['rot_per']) if phys.get('rot_per') else None
        except (TypeError, ValueError):
            rot_period = None
            
        try:
            albedo = float(phys['albedo']) if phys.get('albedo') else None
        except (TypeError, ValueError):
            albedo = None
        
        params = {
            'name': obj.get('fullname'),
            'spk_id': obj.get('spkid'),
            'designation': designation,
            'body_type': body_type,
            'epoch_jd': orbit_data.get('epoch'),
            'eccentricity': orbit_data.get('e'),
            'semi_major_axis_au': orbit_data.get('a'),
            'perihelion_au': orbit_data.get('q'),
            'aphelion_au': orbit_data.get('ad'),
            'inclination_deg': orbit_data.get('i'),
            'arg_periapsis_deg': orbit_data.get('w'),
            'long_asc_node_deg': orbit_data.get('om'),
            'mean_anomaly_deg': orbit_data.get('ma'),
            'orbital_period_days': orbit_data.get('per'),
            'diameter_km': diameter,
            'rotation_period_h': rot_period,
            'albedo': albedo,
            'spectral_type': phys.get('spec_T'),
            'magnitude_h': magnitude_h,
            'discovery_date': disc.get('date'),
            'discovery_site': disc.get('site'),
            'discoverer': disc.get('by'),
            'is_pha': obj.get('pha', False),
            'data_source': f"https://ssd.jpl.nasa.gov/tools/sbdb_lookup.html#/?sstr={obj.get('spkid', '')}"
        }
        
        try:
            with self.conn.cursor() as cur:
                cur.execute(sql, params)
                inserted_id = cur.fetchone()[0]
                self.conn.commit()
                
                pha_warning = " [PHA!]" if params['is_pha'] else ""
                logger.info(f"[OK] Сохранен: {obj.get('fullname')} (ID: {inserted_id}, Тип: {body_type}){pha_warning}")
                
                # Выводим дополнительную информацию
                if diameter:
                    logger.info(f"     Диаметр: {diameter:.2f} км")
                if magnitude_h:
                    logger.info(f"     Абс. величина H: {magnitude_h}")
                
                return True
                
        except psycopg2.Error as e:
            logger.error(f"[DB ERROR] {obj.get('fullname')}: {e.pgerror if hasattr(e, 'pgerror') else str(e)}")
            self.conn.rollback()
            return False
        except Exception as e:
            logger.error(f"[ERROR] {obj.get('fullname')}: {e}")
            self.conn.rollback()
            return False
    
    def import_objects(self, targets: list, delay: float = 1.5):
        """Импорт списка объектов"""
        logger.info(f"[START] Начало импорта {len(targets)} объектов")
        start_time = datetime.now()
        
        for idx, target in enumerate(targets, 1):
            logger.info(f"\n[{idx}/{len(targets)}] Обработка: {target}")
            
            data = self.fetch_object_data(target)
            
            if data:
                if self.parse_and_insert(data):
                    self.stats['successful'] += 1
                else:
                    self.stats['failed'] += 1
            else:
                self.stats['failed'] += 1
            
            self.stats['total_processed'] += 1
            
            if idx < len(targets):
                time.sleep(delay)
        
        elapsed_time = datetime.now() - start_time
        self.print_stats(elapsed_time)
    
    def print_stats(self, elapsed_time):
        """Вывод статистики импорта"""
        logger.info("\n" + "="*60)
        logger.info("СТАТИСТИКА ИМПОРТА")
        logger.info("="*60)
        logger.info(f"Время выполнения: {elapsed_time}")
        logger.info(f"Всего обработано: {self.stats['total_processed']}")
        logger.info(f"Успешно импортировано: {self.stats['successful']}")
        logger.info(f"Пропущено (нет данных): {self.stats['skipped']}")
        logger.info(f"Ошибок: {self.stats['failed']}")
        
        if self.stats['total_processed'] > 0:
            success_rate = (self.stats['successful'] / self.stats['total_processed']) * 100
            logger.info(f"Процент успеха: {success_rate:.1f}%")
        logger.info("="*60)

def get_sample_targets():
    """Возвращает список известных малых тел для демонстрации"""
    return [
        # Карликовые планеты и крупные астероиды
        "1",        # 1 Ceres
        "2",        # 2 Pallas
        "4",        # 4 Vesta
        
        # Известные астероиды
        "433",      # 433 Eros
        "243",      # 243 Ida
        
        # Потенциально опасные астероиды
        "99942",    # Apophis
        "101955",   # Bennu
        
        # Транснептуновые объекты
        "134340",   # Pluto
        
        # Известные кометы
        "1P",       # 1P/Halley
        "67P",      # 67P/Churyumov-Gerasimenko
    ]

def main():
    """Главная функция импорта"""
    
    # Проверяем аргументы командной строки
    if len(sys.argv) > 1:
        targets = sys.argv[1:]
        logger.info(f"Импорт указанных объектов: {', '.join(targets)}")
    else:
        targets = get_sample_targets()
        logger.info(f"Импорт демонстрационного набора ({len(targets)} объектов)")
    
    # Создаем и запускаем импортер
    importer = SBDatabaseImporter(DB_CONFIG)
    
    if not importer.connect():
        logger.error("[FATAL] Не удалось подключиться к базе данных")
        sys.exit(1)
    
    try:
        # Проверяем наличие таблицы small_bodies
        with importer.conn.cursor() as cur:
            cur.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = 'small_bodies'
                );
            """)
            table_exists = cur.fetchone()[0]
            
            if not table_exists:
                logger.error("[FATAL] Таблица 'small_bodies' не найдена в базе данных!")
                logger.info("Выполните SQL-скрипт для создания таблицы перед запуском импорта")
                sys.exit(1)
        
        # Запускаем импорт
        importer.import_objects(targets, delay=1.5)
        
    except KeyboardInterrupt:
        logger.info("\nИмпорт прерван пользователем")
    except Exception as e:
        logger.error(f"[FATAL] Критическая ошибка: {e}")
        import traceback
        traceback.print_exc()
    finally:
        importer.disconnect()

if __name__ == "__main__":
    main()