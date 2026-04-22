class AstronomyAlgorithms {
    constructor() {
        this.comparisons = 0;
        this.swaps = 0;
    }

    quickSort(arr, field, ascending = true) {
        if (!arr || arr.length <= 1) return arr;
        
        const arrayCopy = [...arr];
        this.comparisons = 0;
        this.swaps = 0;
        
        this._quickSortRecursive(arrayCopy, 0, arrayCopy.length - 1, field, ascending);
        
        console.log(`QuickSort по полю "${field}": сравнений=${this.comparisons}, перестановок=${this.swaps}`);
        return arrayCopy;
    }
    
    _quickSortRecursive(arr, left, right, field, ascending) {
        if (left >= right) return;
        
        const pivotIndex = this._partition(arr, left, right, field, ascending);
        this._quickSortRecursive(arr, left, pivotIndex - 1, field, ascending);
        this._quickSortRecursive(arr, pivotIndex + 1, right, field, ascending);
    }
    
    _partition(arr, left, right, field, ascending) {
        const pivot = arr[right];
        let i = left - 1;
        
        for (let j = left; j < right; j++) {
            this.comparisons++;
            
            let compareResult;
            if (typeof arr[j][field] === 'number' && typeof pivot[field] === 'number') {
                compareResult = arr[j][field] - pivot[field];
            } else {
                compareResult = String(arr[j][field]).localeCompare(String(pivot[field]));
            }
            
            if (ascending ? compareResult <= 0 : compareResult >= 0) {
                i++;
                this._swap(arr, i, j);
            }
        }
        
        this._swap(arr, i + 1, right);
        return i + 1;
    }
    
    _swap(arr, i, j) {
        if (i !== j) {
            [arr[i], arr[j]] = [arr[j], arr[i]];
            this.swaps++;
        }
    }
    
    rabinKarpMatch(text, pattern) {
        const textLength = text.length;
        const patternLength = pattern.length;
        
        if (patternLength === 0) return true;
        if (patternLength > textLength) return false;
        
        const q = 1000000007;
        const d = 256;
        
        let patternHash = 0;
        let textHash = 0;
        let h = 1;
        
        for (let i = 0; i < patternLength - 1; i++) {
            h = (h * d) % q;
        }
        
        for (let i = 0; i < patternLength; i++) {
            patternHash = (d * patternHash + pattern.charCodeAt(i)) % q;
            textHash = (d * textHash + text.charCodeAt(i)) % q;
        }
        
        for (let i = 0; i <= textLength - patternLength; i++) {
            if (patternHash === textHash) {
                let match = true;
                for (let j = 0; j < patternLength; j++) {
                    if (text[i + j] !== pattern[j]) {
                        match = false;
                        break;
                    }
                }
                if (match) return true;
            }
            
            if (i < textLength - patternLength) {
                textHash = (d * (textHash - text.charCodeAt(i) * h) + text.charCodeAt(i + patternLength)) % q;
                if (textHash < 0) textHash += q;
            }
        }
        
        return false;
    }
    
    filterDataWithRabinKarp(data, filters) {
        if (!data || data.length === 0) return [];
        if (!filters || Object.keys(filters).length === 0) return data;
        
        const results = [];
        let totalComparisons = 0;
        
        for (const item of data) {
            let allMatched = true;
            
            for (const [field, pattern] of Object.entries(filters)) {
                const value = item[field];
                if (value === undefined || value === null) {
                    allMatched = false;
                    break;
                }
                
                const text = String(value).toLowerCase();
                const patternLower = pattern.toLowerCase();
                totalComparisons++;
                
                if (!this.rabinKarpMatch(text, patternLower)) {
                    allMatched = false;
                    break;
                }
            }
            
            if (allMatched) results.push(item);
        }
        
        console.log(`🔍 Фильтрация Рабина-Карпа: ${data.length} → ${results.length} записей, сравнений: ${totalComparisons}`);
        return results;
    }
    
    buildOptimalSearchTree(data, keyField, weightField = null) {
        if (!data || data.length === 0) return null;
        
        const sortedData = [...data];
        this.quickSort(sortedData, keyField, true);
        
        const weights = weightField 
            ? sortedData.map(item => {
                const weight = item[weightField];
                if (typeof weight === 'string') {
                    const num = parseFloat(weight);
                    return isNaN(num) ? 1 : num;
                }
                return weight || 1;
              })
            : sortedData.map(() => 1);
        
        const keys = sortedData.map(item => item[keyField]);
        
        return this._buildA2TreeRecursive(keys, sortedData, weights, 0, keys.length - 1);
    }
    
    _buildA2TreeRecursive(keys, data, weights, left, right) {
        if (left > right) return null;
        
        let totalWeight = 0;
        for (let i = left; i <= right; i++) totalWeight += weights[i];
        
        let halfWeight = totalWeight / 2;
        let currentWeight = 0;
        let medianIndex = left;
        
        for (let i = left; i <= right; i++) {
            currentWeight += weights[i];
            if (currentWeight >= halfWeight) {
                medianIndex = i;
                break;
            }
        }
        
        const node = {
            key: keys[medianIndex],
            data: data[medianIndex],
            weight: weights[medianIndex],
            left: this._buildA2TreeRecursive(keys, data, weights, left, medianIndex - 1),
            right: this._buildA2TreeRecursive(keys, data, weights, medianIndex + 1, right),
            height: 0
        };
        
        node.height = 1 + Math.max(
            node.left ? node.left.height : 0,
            node.right ? node.right.height : 0
        );
        
        return node;
    }
    
    calculateTreeStatistics(tree) {
        if (!tree) return null;
        
        const stats = {
            totalNodes: 0,
            height: tree.height,
            totalWeight: 0,
            weightedPathSum: 0,
            avgWeightedHeight: 0,
            leaves: 0,
            internalNodes: 0,
            maxWeight: 0,
            minWeight: Infinity,
            keysAtLevels: {}
        };
        
        this._traverseAndCalculate(tree, 1, stats);
        
        if (stats.totalWeight > 0) {
            stats.avgWeightedHeight = stats.weightedPathSum / stats.totalWeight;
        }
        
        return stats;
    }
    
    _traverseAndCalculate(node, level, stats) {
        if (!node) return;
        
        stats.totalNodes++;
        stats.totalWeight += node.weight;
        stats.weightedPathSum += node.weight * level;
        
        if (node.weight > stats.maxWeight) stats.maxWeight = node.weight;
        if (node.weight < stats.minWeight) stats.minWeight = node.weight;
        
        if (!stats.keysAtLevels[level]) stats.keysAtLevels[level] = [];
        stats.keysAtLevels[level].push(node.key);
        
        if (!node.left && !node.right) {
            stats.leaves++;
        } else {
            stats.internalNodes++;
        }
        
        this._traverseAndCalculate(node.left, level + 1, stats);
        this._traverseAndCalculate(node.right, level + 1, stats);
    }
}

const algorithms = new AstronomyAlgorithms();

class AstronomyTableAlgorithms {
    constructor(tableManager) {
        this.tableManager = tableManager;
        this.algorithms = algorithms;
        this.currentSortField = null;
        this.currentSortAscending = true;
        this.optimalTree = null;
        this.currentTreeType = null;
        this.currentData = {
            galaxies: [],
            stars: [],
            planets: [],
            satellites: []
        };
    }
    
    setData(type, data) {
        this.currentData[type] = [...data];
        console.log(`Данные для ${type} загружены: ${data.length} записей`);
    }
    
    sortTable(type, field, ascending = true) {
        const data = this.currentData[type];
        if (!data || data.length === 0) return;
        
        const sortedData = this.algorithms.quickSort(data, field, ascending);
        this.currentData[type] = sortedData;
        this.currentSortField = field;
        this.currentSortAscending = ascending;
        
        if (this.tableManager && this.tableManager.tables[type]) {
            this.tableManager.tables[type].setData(sortedData);
        }
        
        console.log(`Таблица ${type} отсортирована по полю ${field}`);
    }
    
    buildOptimalTree(type, keyField, weightField = null) {
        const data = this.currentData[type];
        if (!data || data.length === 0) return null;
        
        console.log(`Построение дерева оптимального поиска для ${type} по полю "${keyField}"...`);
        
        this.optimalTree = this.algorithms.buildOptimalSearchTree(data, keyField, weightField);
        this.currentTreeType = type;
        
        if (this.optimalTree) {
            const stats = this.algorithms.calculateTreeStatistics(this.optimalTree);
            return { tree: this.optimalTree, stats };
        }
        
        return null;
    }
    
    getTreeStatistics() {
        if (!this.optimalTree) return null;
        return this.algorithms.calculateTreeStatistics(this.optimalTree);
    }
    
    resetTree() {
        this.optimalTree = null;
        this.currentTreeType = null;
        console.log('Дерево сброшено');
    }
    
    filterWithRabinKarp(type, filters) {
        const data = this.currentData[type];
        if (!data || data.length === 0) return [];
        return this.algorithms.filterDataWithRabinKarp(data, filters);
    }
}

window.AstronomyAlgorithms = AstronomyAlgorithms;
window.AstronomyTableAlgorithms = AstronomyTableAlgorithms;
window.algorithms = algorithms;