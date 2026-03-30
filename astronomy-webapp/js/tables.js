// Класс для управления таблицами Tabulator
class AstronomyTables {
    constructor() {
        this.tables = {};
        this.initTables();
    }
    
    initTables() {
        if (typeof Tabulator === 'undefined') {
            console.error('Tabulator не загружен!');
            return;
        }
        
        // Таблица галактик
        this.tables.galaxies = new Tabulator("#galaxies-table", {
            height: "500px",
            layout: "fitColumns",
            responsiveLayout: "collapse",
            placeholder: "Нет данных для отображения",
            columns: [
                { title: "ID", field: "id", width: 70, headerFilter: "input", headerFilterPlaceholder: "Поиск по ID..." },
                { title: "Название галактики", field: "galaxy_name", width: 200, headerFilter: "input", headerFilterPlaceholder: "Поиск по названию..." },
                { title: "Тип", field: "galaxy_type", width: 180, headerFilter: "input", headerFilterPlaceholder: "Поиск по типу..." },
                { title: "Диаметр (св. лет)", field: "diameter_ly", width: 150, formatter: "number", formatterParams: { thousands: " " }, headerFilter: "input" },
                { title: "Количество звезд", field: "star_count", width: 150, headerFilter: "input" },
                { title: "Масса (M☉)", field: "mass_solar_masses", width: 150, headerFilter: "input" },
                { title: "Расстояние (св. лет)", field: "distance_from_earth_ly", width: 150, formatter: "number", formatterParams: { thousands: " " }, headerFilter: "input" },
                { title: "Возраст (млрд лет)", field: "age_billion_years", width: 130, formatter: "number", formatterParams: { decimals: 1 }, headerFilter: "input" },
                { title: "Металличность", field: "metallicity", width: 120, headerFilter: "input" },
                { title: "Скорость вращения (км/с)", field: "rotation_speed_kms", width: 160, formatter: "number", headerFilter: "input" },
                { title: "Год открытия", field: "discovery_year", width: 120, formatter: "number", headerFilter: "input", headerFilterPlaceholder: "Поиск по году..." }
            ],
            rowFormatter: (row) => {
                const data = row.getData();
                if ($) $(row.getElement()).attr('data-id', data.id);
            }
        });
        
        // Таблица звезд
        this.tables.stars = new Tabulator("#stars-table", {
            height: "500px",
            layout: "fitColumns",
            responsiveLayout: "collapse",
            placeholder: "Нет данных для отображения",
            columns: [
                { title: "ID", field: "id", width: 70, headerFilter: "input", headerFilterPlaceholder: "Поиск..." },
                { title: "Название звезды", field: "star_name", width: 200, headerFilter: "input", headerFilterPlaceholder: "Поиск по названию..." },
                { title: "Галактика", field: "galaxy_name", width: 180, headerFilter: "input" },
                { title: "Состав", field: "composition", width: 200, headerFilter: "input" },
                { title: "Масса (M☉)", field: "mass_sun", width: 120, formatter: "number", formatterParams: { decimals: 2 }, headerFilter: "input" },
                { title: "Спектральный класс", field: "spectral_class", width: 130, headerFilter: "input" },
                { title: "Температура (K)", field: "temperature_k", width: 130, formatter: "number", formatterParams: { thousands: " " }, headerFilter: "input" },
                { title: "Год открытия", field: "discovery_year", width: 120, headerFilter: "input", headerFilterPlaceholder: "Поиск по году..." }
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
                { title: "Название планеты", field: "planet_name", width: 180, headerFilter: "input", headerFilterPlaceholder: "Поиск по названию..." },
                { title: "Звезда", field: "star_name", width: 180, headerFilter: "input" },
                { title: "Тип планеты", field: "planet_type", width: 130, headerFilter: "input" },
                { title: "Масса (M⊕)", field: "mass_earth", width: 120, formatter: "number", formatterParams: { decimals: 2 }, headerFilter: "input" },
                { title: "Период обращения (дней)", field: "orbital_period_days", width: 150, formatter: "number", formatterParams: { decimals: 2 }, headerFilter: "input" },
                { title: "Год открытия", field: "discovery_year", width: 120, headerFilter: "input" }
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
                { title: "Название спутника", field: "satellite_name", width: 180, headerFilter: "input", headerFilterPlaceholder: "Поиск по названию..." },
                { title: "Планета", field: "planet_name", width: 180, headerFilter: "input" },
                { title: "Тип", field: "satellite_type", width: 120, headerFilter: "input" },
                { title: "Диаметр (км)", field: "diameter_km", width: 120, formatter: "number", formatterParams: { decimals: 2 }, headerFilter: "input" },
                { title: "Период обращения (дней)", field: "orbital_period_days", width: 150, formatter: "number", formatterParams: { decimals: 2 }, headerFilter: "input" },
                { title: "Год открытия", field: "discovery_year", width: 120, headerFilter: "input" }
            ]
        });
        
        console.log('Таблицы инициализированы');
    }
    
    async loadGalaxies() {
        try {
            const data = await api.getGalaxies();
            console.log('Загружено галактик:', data.length);
            this.tables.galaxies.setData(data);
            if (window.tableAlgorithms) window.tableAlgorithms.setData('galaxies', data);
            return data;
        } catch (error) {
            console.error('Ошибка загрузки галактик:', error);
            return [];
        }
    }
    
    async loadStars() {
        try {
            const data = await api.getStars();
            console.log('Загружено звезд:', data.length);
            this.tables.stars.setData(data);
            if (window.tableAlgorithms) window.tableAlgorithms.setData('stars', data);
            return data;
        } catch (error) {
            console.error('Ошибка загрузки звезд:', error);
            return [];
        }
    }
    
    async loadPlanets() {
        try {
            const data = await api.getPlanets();
            console.log('Загружено планет:', data.length);
            this.tables.planets.setData(data);
            if (window.tableAlgorithms) window.tableAlgorithms.setData('planets', data);
            return data;
        } catch (error) {
            console.error('Ошибка загрузки планет:', error);
            return [];
        }
    }
    
    async loadSatellites() {
        try {
            const data = await api.getSatellites();
            console.log('Загружено спутников:', data.length);
            this.tables.satellites.setData(data);
            if (window.tableAlgorithms) window.tableAlgorithms.setData('satellites', data);
            return data;
        } catch (error) {
            console.error('Ошибка загрузки спутников:', error);
            return [];
        }
    }
    
    updateData(type, data) {
        if (this.tables[type]) this.tables[type].setData(data);
        if (window.tableAlgorithms) window.tableAlgorithms.setData(type, data);
    }
}

// Создаем глобальный экземпляр
let astronomyTables;

document.addEventListener('DOMContentLoaded', () => {
    console.log('DOM загружен, инициализация таблиц...');
    astronomyTables = new AstronomyTables();
    if (typeof AstronomyTableAlgorithms !== 'undefined') {
        window.tableAlgorithms = new AstronomyTableAlgorithms(astronomyTables);
    }
});