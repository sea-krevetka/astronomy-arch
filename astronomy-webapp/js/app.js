// Основной файл приложения
class AstronomyApp {
    constructor() {
        this.init();
    }
    
    async init() {
        console.log('Инициализация приложения...');
        await this.loadStatistics();
        await this.loadAllTables();
        this.setupEventHandlers();
        console.log('Приложение готово!');
    }
    
    async loadStatistics() {
        try {
            const stats = await api.getStatistics();
            document.getElementById('total-galaxies').textContent = stats.total?.total_galaxies || 0;
            document.getElementById('total-stars').textContent = stats.total?.total_stars || 0;
            document.getElementById('total-planets').textContent = stats.total?.total_planets || 0;
            document.getElementById('total-satellites').textContent = stats.total?.total_satellites || 0;
            console.log('Статистика загружена:', stats);
        } catch (error) {
            console.error('Ошибка загрузки статистики:', error);
        }
    }
    
    async loadAllTables() {
        this.showLoading();
        try {
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
        const searchBtn = document.getElementById('search-btn');
        const searchInput = document.getElementById('search-input');
        
        if (searchBtn) {
            searchBtn.addEventListener('click', () => this.performSearch(searchInput.value));
        }
        if (searchInput) {
            searchInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') this.performSearch(searchInput.value);
            });
        }
        
        const tabs = document.querySelectorAll('[data-bs-toggle="tab"]');
        tabs.forEach(tab => {
            tab.addEventListener('shown.bs.tab', (e) => {
                this.onTabChange(e.target.getAttribute('data-bs-target'));
            });
        });
        
        this.setupRowClickHandlers();
        
        window.sortCurrentTable = () => this.sortCurrentTable();
        window.showTreeStats = () => this.showTreeStats();
        
        console.log('Обработчики событий настроены');
    }
    
    getCurrentTableType() {
        const activeTab = document.querySelector('.tab-pane.active');
        if (activeTab && activeTab.id === 'galaxies') return 'galaxies';
        if (activeTab && activeTab.id === 'stars') return 'stars';
        if (activeTab && activeTab.id === 'planets') return 'planets';
        if (activeTab && activeTab.id === 'satellites') return 'satellites';
        return 'galaxies';
    }
    
    sortCurrentTable() {
        const type = this.getCurrentTableType();
        const fieldSelect = document.getElementById('sort-field');
        if (!fieldSelect) return;
        
        const field = fieldSelect.value;
        if (window.tableAlgorithms) {
            window.tableAlgorithms.sortTable(type, field, true);
            this.showMessage(`Таблица отсортирована по полю ${field} (QuickSort)`, 'success');
        } else {
            this.showMessage('Алгоритмы не загружены', 'warning');
        }
    }
    
    showTreeStats() {
        const type = this.getCurrentTableType();
        let keyField = 'galaxy_name';
        if (type === 'stars') keyField = 'star_name';
        if (type === 'planets') keyField = 'planet_name';
        if (type === 'satellites') keyField = 'satellite_name';
        
        if (!window.tableAlgorithms) {
            this.showMessage('⚠️ Алгоритмы не загружены', 'warning');
            return;
        }
        
        const currentTree = window.tableAlgorithms.optimalTree;
        const currentTreeType = window.tableAlgorithms.currentTreeType;
        
        if (currentTree && currentTreeType === type) {
            const stats = window.tableAlgorithms.getTreeStatistics();
            if (stats) this.displayTreeStatistics(stats, type, keyField);
        } else {
            this.showLoading();
            try {
                const result = window.tableAlgorithms.buildOptimalTree(type, keyField);
                if (result && result.stats) {
                    window.tableAlgorithms.currentTreeType = type;
                    this.displayTreeStatistics(result.stats, type, keyField);
                    this.showMessage(`✅ Дерево построено для таблицы "${type}"`, 'success');
                } else {
                    this.showMessage(`⚠️ Не удалось построить дерево для "${type}"`, 'warning');
                }
            } catch (error) {
                console.error('Ошибка:', error);
                this.showMessage('❌ Ошибка при построении дерева', 'danger');
            } finally {
                this.hideLoading();
            }
        }
    }
    
    displayTreeStatistics(stats, type, keyField) {
        let message = `📊 СТАТИСТИКА ДЕРЕВА ОПТИМАЛЬНОГО ПОИСКА (А2)\n`;
        message += `━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`;
        message += `📁 Тип данных: ${type}\n`;
        message += `🔑 Ключевое поле: ${keyField}\n`;
        message += `━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`;
        message += `📊 Количество узлов: ${stats.totalNodes}\n`;
        message += `🌳 Высота дерева: ${stats.height}\n`;
        message += `🍃 Листьев: ${stats.leaves}\n`;
        message += `🌿 Внутренних узлов: ${stats.internalNodes}\n`;
        message += `⚖️ Общий вес: ${stats.totalWeight}\n`;
        message += `📈 Средневзвешенная высота: ${stats.avgWeightedHeight.toFixed(4)}\n`;
        message += `━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`;
        
        if (stats.keysAtLevels && Object.keys(stats.keysAtLevels).length > 0) {
            message += `\n📐 РАСПРЕДЕЛЕНИЕ ПО УРОВНЯМ:\n`;
            const levels = Object.keys(stats.keysAtLevels).sort((a, b) => Number(a) - Number(b));
            levels.forEach(level => {
                const count = stats.keysAtLevels[level].length;
                const percent = ((count / stats.totalNodes) * 100).toFixed(1);
                message += `  Уровень ${level.padStart(2)}: ${count.toString().padStart(3)} узлов (${percent}%)\n`;
            });
        }
        
        alert(message);
    }
    
    onTabChange(target) {
        console.log('Переключено на вкладку:', target);
        if (window.tableAlgorithms && window.tableAlgorithms.currentTreeType !== this.getCurrentTableType()) {
            window.tableAlgorithms.currentTreeType = null;
        }
    }
    
    setupRowClickHandlers() {
        const types = ['galaxies', 'stars', 'planets', 'satellites'];
        types.forEach(type => {
            if (astronomyTables.tables[type]) {
                astronomyTables.tables[type].on('rowClick', (e, row) => {
                    const data = row.getData();
                    this.showObjectDetails(type, data);
                });
            }
        });
    }
    
    showObjectDetails(type, data) {
        if (type === 'galaxies') {
            alert(`Галактика: ${data.galaxy_name}\nТип: ${data.galaxy_type}\nДиаметр: ${data.diameter_ly} св. лет\nВозраст: ${data.age_billion_years} млрд лет`);
        } else if (type === 'stars') {
            alert(`Звезда: ${data.star_name}\nГалактика: ${data.galaxy_name}\nМасса: ${data.mass_sun} M☉\nСпектральный класс: ${data.spectral_class}`);
        } else if (type === 'planets') {
            alert(`Планета: ${data.planet_name}\nЗвезда: ${data.star_name}\nТип: ${data.planet_type}\nМасса: ${data.mass_earth} M⊕`);
        } else if (type === 'satellites') {
            alert(`Спутник: ${data.satellite_name}\nПланета: ${data.planet_name}\nДиаметр: ${data.diameter_km} км`);
        }
    }
    
    async performSearch(query) {
        if (!query || query.trim() === '') {
            const resultsDiv = document.getElementById('search-results');
            if (resultsDiv) resultsDiv.style.display = 'none';
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
        if (!resultsDiv) return;
        
        if (results.length === 0) {
            resultsDiv.innerHTML = '<div class="search-result-item text-muted">Ничего не найдено</div>';
            resultsDiv.style.display = 'block';
            return;
        }
        
        let html = '';
        results.forEach(result => {
            let icon = '';
            if (result.type === 'galaxy') icon = '<i class="fas fa-galaxy text-primary"></i>';
            else if (result.type === 'star') icon = '<i class="fas fa-sun text-warning"></i>';
            else if (result.type === 'planet') icon = '<i class="fas fa-globe text-success"></i>';
            else icon = '<i class="fas fa-moon text-secondary"></i>';
            
            html += `<div class="search-result-item" data-id="${result.id}" data-type="${result.type}">
                        ${icon} <strong>${result.name}</strong>
                        <span class="text-muted ms-2">${result.type}</span>
                    </div>`;
        });
        
        resultsDiv.innerHTML = html;
        resultsDiv.style.display = 'block';
        
        document.querySelectorAll('.search-result-item').forEach(item => {
            item.addEventListener('click', () => {
                const id = item.dataset.id;
                const type = item.dataset.type;
                this.navigateToObject(type, id);
                resultsDiv.style.display = 'none';
                const searchInput = document.getElementById('search-input');
                if (searchInput) searchInput.value = '';
            });
        });
        
        setTimeout(() => {
            document.addEventListener('click', (e) => {
                if (!resultsDiv.contains(e.target) && e.target !== document.getElementById('search-input')) {
                    resultsDiv.style.display = 'none';
                }
            });
        }, 100);
    }
    
    navigateToObject(type, id) {
        const tabMap = { galaxy: 'galaxies-tab', star: 'stars-tab', planet: 'planets-tab', satellite: 'satellites-tab' };
        const tabId = tabMap[type];
        if (tabId) {
            const tab = document.getElementById(tabId);
            if (tab) new bootstrap.Tab(tab).show();
            setTimeout(() => {
                const table = astronomyTables.tables[type + 's'];
                if (table) {
                    const row = table.getRows().find(r => r.getData().id == id);
                    if (row) { row.scrollTo(); row.select(); }
                }
            }, 300);
        }
    }
    
    showLoading() {
        const loader = document.createElement('div');
        loader.id = 'global-loader';
        loader.innerHTML = '<i class="fas fa-spinner fa-spin"></i><p>Загрузка...</p>';
        loader.style.cssText = 'position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);background:rgba(0,0,0,0.8);color:white;padding:20px;border-radius:10px;z-index:9999';
        document.body.appendChild(loader);
    }
    
    hideLoading() {
        const loader = document.getElementById('global-loader');
        if (loader) loader.remove();
    }
    
    showError(message) {
        const errorDiv = document.createElement('div');
        errorDiv.className = 'alert alert-danger alert-dismissible fade show';
        errorDiv.innerHTML = `${message}<button type="button" class="btn-close" data-bs-dismiss="alert"></button>`;
        const container = document.querySelector('.container-fluid');
        if (container) container.insertAdjacentElement('afterbegin', errorDiv);
        setTimeout(() => errorDiv.remove(), 5000);
    }
    
    showMessage(message, type) {
        const msgDiv = document.createElement('div');
        msgDiv.className = `alert alert-${type === 'success' ? 'success' : type === 'warning' ? 'warning' : 'info'} alert-dismissible fade show`;
        msgDiv.style.whiteSpace = 'pre-line';
        msgDiv.innerHTML = `${message.replace(/\n/g, '<br>')}<button type="button" class="btn-close" data-bs-dismiss="alert"></button>`;
        const container = document.querySelector('.container-fluid');
        if (container) container.insertAdjacentElement('afterbegin', msgDiv);
        setTimeout(() => msgDiv.remove(), 5000);
    }
}

document.addEventListener('DOMContentLoaded', () => {
    new AstronomyApp();
});