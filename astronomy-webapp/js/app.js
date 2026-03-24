// Основной файл приложения
class AstronomyApp {
    constructor() {
        this.init();
    }
    
    async init() {
        console.log('Инициализация приложения...');
        
        // Загрузка статистики
        await this.loadStatistics();
        
        // Загрузка данных в таблицы
        await this.loadAllTables();
        
        // Настройка обработчиков событий
        this.setupEventHandlers();
        
        console.log('Приложение готово!');
    }
    
    async loadStatistics() {
        try {
            const stats = await api.getStatistics();
            
            // Обновляем статистику на странице
            document.getElementById('total-galaxies').textContent = stats.total.total_galaxies || 0;
            document.getElementById('total-stars').textContent = stats.total.total_stars || 0;
            document.getElementById('total-planets').textContent = stats.total.total_planets || 0;
            document.getElementById('total-satellites').textContent = stats.total.total_satellites || 0;
            
            // Можно добавить дополнительные графики статистики
            console.log('Статистика загружена:', stats);
        } catch (error) {
            console.error('Ошибка загрузки статистики:', error);
        }
    }
    
    async loadAllTables() {
        // Показываем загрузку
        this.showLoading();
        
        try {
            // Загружаем данные для всех таблиц параллельно
            await Promise.all([
                astronomyTables.loadGalaxies(),
                astronomyTables.loadStars(),
                astronomyTables.loadPlanets(),
                astronomyTables.loadSatellites()
            ]);
            
            console.log('Все данные загружены');
        } catch (error) {
            console.error('Ошибка загрузки данных:', error);
            this.showError('Не удалось загрузить данные. Проверьте подключение к серверу.');
        } finally {
            this.hideLoading();
        }
    }
    
    setupEventHandlers() {
        // Поиск
        const searchBtn = document.getElementById('search-btn');
        const searchInput = document.getElementById('search-input');
        
        searchBtn.addEventListener('click', () => {
            this.performSearch(searchInput.value);
        });
        
        searchInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.performSearch(searchInput.value);
            }
        });
        
        // Обработка смены вкладок
        const tabs = document.querySelectorAll('[data-bs-toggle="tab"]');
        tabs.forEach(tab => {
            tab.addEventListener('shown.bs.tab', (e) => {
                const target = e.target.getAttribute('data-bs-target');
                this.onTabChange(target);
            });
        });
        
        // Добавляем обработчики для кликов по строкам таблиц
        this.setupRowClickHandlers();
    }
    
    setupRowClickHandlers() {
        // Клик по строке галактики
        astronomyTables.tables.galaxies.on('rowClick', (e, row) => {
            const data = row.getData();
            this.showGalaxyDetails(data);
        });
        
        // Клик по строке звезды
        astronomyTables.tables.stars.on('rowClick', (e, row) => {
            const data = row.getData();
            this.showStarDetails(data);
        });
        
        // Клик по строке планеты
        astronomyTables.tables.planets.on('rowClick', (e, row) => {
            const data = row.getData();
            this.showPlanetDetails(data);
        });
        
        // Клик по строке спутника
        astronomyTables.tables.satellites.on('rowClick', (e, row) => {
            const data = row.getData();
            this.showSatelliteDetails(data);
        });
    }
    
    async performSearch(query) {
        if (!query || query.trim() === '') {
            document.getElementById('search-results').style.display = 'none';
            return;
        }
        
        try {
            const results = await api.search(query);
            this.displaySearchResults(results);
        } catch (error) {
            console.error('Ошибка поиска:', error);
        }
    }
    
    displaySearchResults(results) {
        const resultsDiv = document.getElementById('search-results');
        
        if (results.length === 0) {
            resultsDiv.innerHTML = '<div class="search-result-item text-muted">Ничего не найдено</div>';
            resultsDiv.style.display = 'block';
            return;
        }
        
        let html = '';
        results.forEach(result => {
            let icon = '';
            switch(result.type) {
                case 'galaxy':
                    icon = '<i class="fas fa-galaxy text-primary"></i>';
                    break;
                case 'star':
                    icon = '<i class="fas fa-sun text-warning"></i>';
                    break;
                case 'planet':
                    icon = '<i class="fas fa-globe text-success"></i>';
                    break;
                default:
                    icon = '<i class="fas fa-moon text-secondary"></i>';
            }
            
            html += `
                <div class="search-result-item" data-id="${result.id}" data-type="${result.type}">
                    ${icon} <strong>${result.name}</strong>
                    <span class="text-muted ms-2">${result.type}</span>
                    <small class="text-muted ms-2">${result.info || ''}</small>
                </div>
            `;
        });
        
        resultsDiv.innerHTML = html;
        resultsDiv.style.display = 'block';
        
        // Добавляем обработчики кликов на результаты поиска
        document.querySelectorAll('.search-result-item').forEach(item => {
            item.addEventListener('click', () => {
                const id = item.dataset.id;
                const type = item.dataset.type;
                this.navigateToObject(type, id);
                resultsDiv.style.display = 'none';
                document.getElementById('search-input').value = '';
            });
        });
        
        // Скрываем результаты при клике вне
        setTimeout(() => {
            document.addEventListener('click', (e) => {
                if (!resultsDiv.contains(e.target) && e.target !== document.getElementById('search-input')) {
                    resultsDiv.style.display = 'none';
                }
            });
        }, 100);
    }
    
    navigateToObject(type, id) {
        // Переключение на соответствующую вкладку и выделение строки
        const tabMap = {
            galaxy: 'galaxies-tab',
            star: 'stars-tab',
            planet: 'planets-tab',
            satellite: 'satellites-tab'
        };
        
        const tabId = tabMap[type];
        if (tabId) {
            const tab = document.getElementById(tabId);
            const bsTab = new bootstrap.Tab(tab);
            bsTab.show();
            
            // Прокручиваем к нужной строке
            setTimeout(() => {
                const table = astronomyTables.tables[type + 's'];
                if (table) {
                    const row = table.getRows().find(r => r.getData().id == id);
                    if (row) {
                        row.scrollTo();
                        row.select();
                    }
                }
            }, 300);
        }
    }
    
    showGalaxyDetails(galaxy) {
        const modalHtml = `
            <div class="modal fade" id="galaxyModal" tabindex="-1">
                <div class="modal-dialog modal-lg">
                    <div class="modal-content">
                        <div class="modal-header bg-primary text-white">
                            <h5 class="modal-title">
                                <i class="fas fa-galaxy"></i> ${galaxy.galaxy_name}
                            </h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <div class="modal-body">
                            <div class="row">
                                <div class="col-md-6">
                                    <h6>Основные характеристики</h6>
                                    <table class="table table-sm">
                                        <tr><td><strong>Тип:</strong></td><td>${galaxy.galaxy_type}</td></tr>
                                        <tr><td><strong>Диаметр:</strong></td><td>${galaxy.diameter_ly.toLocaleString()} св. лет</td></tr>
                                        <tr><td><strong>Количество звезд:</strong></td><td>${galaxy.star_count}</td></tr>
                                        <tr><td><strong>Масса:</strong></td><td>${galaxy.mass_solar_masses} M☉</td></tr>
                                        <tr><td><strong>Расстояние от Земли:</strong></td><td>${galaxy.distance_from_earth_ly.toLocaleString()} св. лет</td></tr>
                                    </table>
                                </div>
                                <div class="col-md-6">
                                    <h6>Дополнительная информация</h6>
                                    <table class="table table-sm">
                                        <tr><td><strong>Возраст:</strong></td><td>${galaxy.age_billion_years} млрд лет</td></tr>
                                        <tr><td><strong>Металличность:</strong></td><td>${galaxy.metallicity}</td></tr>
                                        <tr><td><strong>Скорость вращения:</strong></td><td>${galaxy.rotation_speed_kms} км/с</td></tr>
                                        <tr><td><strong>Год открытия:</strong></td><td>${galaxy.discovery_year}</td></tr>
                                    </table>
                                </div>
                            </div>
                            <hr>
                            <h6>Описание типа галактики</h6>
                            <p>${galaxy.type_description || 'Нет описания'}</p>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        // Удаляем старый модал, если есть
        const oldModal = document.getElementById('galaxyModal');
        if (oldModal) oldModal.remove();
        
        document.body.insertAdjacentHTML('beforeend', modalHtml);
        const modal = new bootstrap.Modal(document.getElementById('galaxyModal'));
        modal.show();
        
        // Удаляем модал после закрытия
        document.getElementById('galaxyModal').addEventListener('hidden.bs.modal', function() {
            this.remove();
        });
    }
    
    showStarDetails(star) {
        alert(`Звезда: ${star.star_name}\nСпектральный класс: ${star.spectral_class}\nМасса: ${star.mass_solar} M☉\nТемпература: ${star.temperature_k} K`);
    }
    
    showPlanetDetails(planet) {
        alert(`Планета: ${planet.planet_name}\nТип: ${planet.planet_type}\nМасса: ${planet.mass_earth} M⊕\nПериод обращения: ${planet.orbital_period_days} дней`);
    }
    
    showSatelliteDetails(satellite) {
        alert(`Спутник: ${satellite.satellite_name}\nПланета: ${satellite.planet_name}\nДиаметр: ${satellite.diameter_km} км`);
    }
    
    onTabChange(target) {
        console.log('Переключено на вкладку:', target);
        // Здесь можно добавить логику для lazy loading данных
    }
    
    showLoading() {
        // Добавляем индикатор загрузки
        const loader = document.createElement('div');
        loader.id = 'global-loader';
        loader.className = 'loading-spinner';
        loader.innerHTML = '<i class="fas fa-spinner fa-spin"></i><p>Загрузка данных...</p>';
        loader.style.cssText = `
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(0,0,0,0.8);
            color: white;
            padding: 20px;
            border-radius: 10px;
            z-index: 9999;
        `;
        document.body.appendChild(loader);
    }
    
    hideLoading() {
        const loader = document.getElementById('global-loader');
        if (loader) loader.remove();
    }
    
    showError(message) {
        const errorDiv = document.createElement('div');
        errorDiv.className = 'alert alert-danger alert-dismissible fade show';
        errorDiv.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;
        document.querySelector('.container-fluid').insertAdjacentElement('afterbegin', errorDiv);
        
        setTimeout(() => {
            errorDiv.remove();
        }, 5000);
    }
}

// Запуск приложения после загрузки страницы
document.addEventListener('DOMContentLoaded', () => {
    new AstronomyApp();
});