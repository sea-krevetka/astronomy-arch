// Класс для управления таблицами Tabulator
class AstronomyTables {
    constructor() {
        this.tables = {};
        this.initTables();
    }
    
    initTables() {
        // Таблица галактик
        this.tables.galaxies = new Tabulator("#galaxies-table", {
            height: "500px",
            layout: "fitColumns",
            responsiveLayout: "collapse",
            placeholder: "Нет данных для отображения",
            columns: [
                { title: "ID", field: "id", width: 70, headerFilter: "input" },
                { title: "Название галактики", field: "galaxy_name", width: 200, headerFilter: "input" },
                { title: "Тип", field: "galaxy_type", width: 180, headerFilter: "input" },
                { title: "Диаметр (св. лет)", field: "diameter_ly", width: 150, formatter: "number", formatterParams: { thousands: " " } },
                { title: "Количество звезд", field: "star_count", width: 150 },
                { title: "Масса", field: "mass_solar_masses", width: 150 },
                { title: "Расстояние (св. лет)", field: "distance_from_earth_ly", width: 150, formatter: "number", formatterParams: { thousands: " " } },
                { title: "Возраст (млрд лет)", field: "age_billion_years", width: 130, formatter: "number", formatterParams: { decimals: 1 } },
                { title: "Металличность", field: "metallicity", width: 120 },
                { title: "Скорость вращения (км/с)", field: "rotation_speed_kms", width: 160, formatter: "number" },
                { title: "Год открытия", field: "discovery_year", width: 120, formatter: "number" }
            ],
            rowFormatter: (row) => {
                const data = row.getData();
                $(row.getElement()).attr('data-id', data.id);
            }
        });
        
        // Таблица звезд
        this.tables.stars = new Tabulator("#stars-table", {
            height: "500px",
            layout: "fitColumns",
            responsiveLayout: "collapse",
            placeholder: "Нет данных для отображения",
            columns: [
                { title: "ID", field: "id", width: 70, headerFilter: "input" },
                { title: "Название звезды", field: "star_name", width: 200, headerFilter: "input" },
                { title: "Галактика", field: "galaxy_name", width: 180, headerFilter: "input" },
                { title: "Масса (M☉)", field: "mass_solar", width: 120, formatter: "number", formatterParams: { decimals: 2 } },
                { title: "Температура (K)", field: "temperature_k", width: 130, formatter: "number", formatterParams: { thousands: " " } },
                { title: "Светимость (L☉)", field: "luminosity_solar", width: 130, formatter: "number", formatterParams: { decimals: 0 } },
                { title: "Радиус (R☉)", field: "radius_solar", width: 120, formatter: "number", formatterParams: { decimals: 2 } },
                { title: "Спектральный класс", field: "spectral_class", width: 130, headerFilter: "input" },
                { title: "Расстояние (св. лет)", field: "distance_from_sun_ly", width: 150, formatter: "number", formatterParams: { decimals: 2 } },
                { title: "Возраст (млрд лет)", field: "age_billion_years", width: 130, formatter: "number", formatterParams: { decimals: 2 } },
                { title: "Видимая величина", field: "apparent_magnitude", width: 130, formatter: "number", formatterParams: { decimals: 2 } },
                { title: "Планет", field: "planets_count", width: 80, formatter: "number" }
            ]
        });
        
        // Таблица планет
        this.tables.planets = new Tabulator("#planets-table", {
            height: "500px",
            layout: "fitColumns",
            responsiveLayout: "collapse",
            placeholder: "Нет данных для отображения",
            columns: [
                { title: "ID", field: "id", width: 70, headerFilter: "input" },
                { title: "Название планеты", field: "planet_name", width: 180, headerFilter: "input" },
                { title: "Звезда", field: "star_name", width: 180, headerFilter: "input" },
                { title: "Спектральный класс звезды", field: "star_spectral_class", width: 150 },
                { title: "Тип планеты", field: "planet_type", width: 130, headerFilter: "input" },
                { title: "Масса (M⊕)", field: "mass_earth", width: 120, formatter: "number", formatterParams: { decimals: 2 } },
                { title: "Диаметр (км)", field: "diameter_km", width: 120, formatter: "number", formatterParams: { thousands: " " } },
                { title: "Период обращения (дней)", field: "orbital_period_days", width: 150, formatter: "number", formatterParams: { decimals: 2 } },
                { title: "Расстояние от звезды (а.е.)", field: "distance_from_star_au", width: 170, formatter: "number", formatterParams: { decimals: 2 } },
                { title: "Температура (°C)", field: "surface_temperature_c", width: 140 },
                { title: "Спутников", field: "satellites_count", width: 100, formatter: "number" },
                { title: "Атмосфера", field: "atmosphere_composition", width: 200 }
            ]
        });
        
        // Таблица спутников
        this.tables.satellites = new Tabulator("#satellites-table", {
            height: "500px",
            layout: "fitColumns",
            responsiveLayout: "collapse",
            placeholder: "Нет данных для отображения",
            columns: [
                { title: "ID", field: "id", width: 70, headerFilter: "input" },
                { title: "Название спутника", field: "satellite_name", width: 180, headerFilter: "input" },
                { title: "Планета", field: "planet_name", width: 180, headerFilter: "input" },
                { title: "Тип", field: "satellite_type", width: 120, headerFilter: "input" },
                { title: "Диаметр (км)", field: "diameter_km", width: 120, formatter: "number", formatterParams: { decimals: 2 } },
                { title: "Масса (кг)", field: "mass_kg", width: 150 },
                { title: "Период обращения (дней)", field: "orbital_period_days", width: 150, formatter: "number", formatterParams: { decimals: 2 } },
                { title: "Расстояние от планеты (км)", field: "distance_from_planet_km", width: 170, formatter: "number", formatterParams: { thousands: " " } },
                { title: "Температура (°C)", field: "temperature_c", width: 130 },
                { title: "Год открытия", field: "discovery_year", width: 120 },
                { title: "Первооткрыватель", field: "discoverer", width: 180 }
            ]
        });
    }
    
    async loadGalaxies() {
        try {
            const data = await api.getGalaxies();
            this.tables.galaxies.setData(data);
            return data;
        } catch (error) {
            console.error('Ошибка загрузки галактик:', error);
            return [];
        }
    }
    
    async loadStars() {
        try {
            const data = await api.getStars();
            this.tables.stars.setData(data);
            return data;
        } catch (error) {
            console.error('Ошибка загрузки звезд:', error);
            return [];
        }
    }
    
    async loadPlanets() {
        try {
            const data = await api.getPlanets();
            this.tables.planets.setData(data);
            return data;
        } catch (error) {
            console.error('Ошибка загрузки планет:', error);
            return [];
        }
    }
    
    async loadSatellites() {
        try {
            const data = await api.getSatellites();
            this.tables.satellites.setData(data);
            return data;
        } catch (error) {
            console.error('Ошибка загрузки спутников:', error);
            return [];
        }
    }
    
    updateData(type, data) {
        if (this.tables[type]) {
            this.tables[type].setData(data);
        }
    }
}

// Создаем глобальный экземпляр
const astronomyTables = new AstronomyTables();