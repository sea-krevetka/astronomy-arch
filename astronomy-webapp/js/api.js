// API класс для работы с бэкендом
class AstronomyAPI {
    constructor(baseURL = 'http://localhost:3000/api') {
        this.baseURL = baseURL;
    }
    
    async request(endpoint, options = {}) {
        try {
            const response = await fetch(`${this.baseURL}${endpoint}`, {
                ...options,
                headers: {
                    'Content-Type': 'application/json',
                    ...options.headers
                }
            });
            
            if (!response.ok) {
                const error = await response.json();
                throw new Error(error.error || 'Ошибка запроса');
            }
            
            return await response.json();
        } catch (error) {
            console.error(`API Error (${endpoint}):`, error);
            throw error;
        }
    }
    
    // Галактики
    async getGalaxies() {
        return this.request('/galaxies');
    }
    
    async getGalaxyById(id) {
        return this.request(`/galaxies/${id}`);
    }
    
    // Звезды
    async getStars() {
        return this.request('/stars');
    }
    
    async getStarsByGalaxy(galaxyId) {
        return this.request(`/stars/galaxy/${galaxyId}`);
    }
    
    // Планеты
    async getPlanets() {
        return this.request('/planets');
    }
    
    async getPlanetsByStar(starId) {
        return this.request(`/planets/star/${starId}`);
    }
    
    // Спутники
    async getSatellites() {
        return this.request('/satellites');
    }
    
    async getSatellitesByPlanet(planetId) {
        return this.request(`/satellites/planet/${planetId}`);
    }
    
    // Типы галактик
    async getGalaxyTypes() {
        return this.request('/galaxy-types');
    }
    
    // Статистика
    async getStatistics() {
        return this.request('/statistics');
    }
    
    // Поиск
    async search(query, type = null) {
        const params = new URLSearchParams({ q: query });
        if (type) params.append('type', type);
        return this.request(`/search?${params.toString()}`);
    }
}

// Создаем глобальный экземпляр API
const api = new AstronomyAPI();