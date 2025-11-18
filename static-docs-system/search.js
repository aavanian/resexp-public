/**
 * Documentation Search using Lunr.js
 *
 * Search index loaded from search-index.js (auto-generated)
 * To regenerate index: python3 build-search-index.py
 *
 * To use this, download lunr.js:
 * wget https://unpkg.com/lunr@2.3.9/lunr.min.js
 *
 * Or from CDN (requires internet):
 * <script src="https://unpkg.com/lunr@2.3.9/lunr.min.js"></script>
 */

// Search index will be loaded from search-index.js
// If that file doesn't exist, you'll need to run: python3 build-search-index.py
// The searchDocuments array is defined in search-index.js

let searchIndex = null;

// Initialize search index
function initializeSearch() {
    // Check if search documents are loaded
    if (typeof searchDocuments === 'undefined') {
        console.error('Search index not loaded! Run: python3 build-search-index.py');
        return null;
    }

    // Check if lunr is available
    if (typeof lunr === 'undefined') {
        console.warn('Lunr.js not loaded. Using simple search fallback.');
        return null;
    }

    // Build lunr index
    searchIndex = lunr(function() {
        this.ref('id');
        this.field('title', { boost: 10 });
        this.field('body');

        searchDocuments.forEach(doc => {
            this.add(doc);
        });
    });

    return searchIndex;
}

// Perform search using lunr or fallback
function performSearch(query) {
    if (!query || query.length < 2) {
        return [];
    }

    // Try lunr search first
    if (searchIndex) {
        try {
            const results = searchIndex.search(query);
            return results.map(result => {
                const doc = searchDocuments.find(d => d.id === result.ref);
                return {
                    ...doc,
                    score: result.score
                };
            });
        } catch (e) {
            console.warn('Lunr search failed, using fallback:', e);
        }
    }

    // Fallback to simple search
    return simpleSearch(query);
}

// Simple search fallback (if lunr not available)
function simpleSearch(query) {
    if (typeof searchDocuments === 'undefined') {
        return [];
    }

    const lowerQuery = query.toLowerCase();
    const words = lowerQuery.split(/\s+/);

    return searchDocuments
        .map(doc => {
            let score = 0;
            const titleLower = doc.title.toLowerCase();
            const bodyLower = doc.body.toLowerCase();

            words.forEach(word => {
                if (titleLower.includes(word)) score += 10;
                if (bodyLower.includes(word)) score += 5;
            });

            return { ...doc, score };
        })
        .filter(doc => doc.score > 0)
        .sort((a, b) => b.score - a.score);
}

// Highlight matching terms
function highlightText(text, query) {
    const words = query.toLowerCase().split(/\s+/);
    let result = text;

    words.forEach(word => {
        if (word.length < 2) return;
        const regex = new RegExp(`(${escapeRegex(word)})`, 'gi');
        result = result.replace(regex, '<span class="highlight">$1</span>');
    });

    return result;
}

function escapeRegex(str) {
    return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// Display search results
function displayResults(results, query, containerId) {
    const container = document.getElementById(containerId);

    if (!results || results.length === 0) {
        container.innerHTML = '<div class="search-result-item">No results found</div>';
        container.classList.add('show');
        return;
    }

    const html = results.map(doc => `
        <div class="search-result-item">
            <a href="${doc.url}">${highlightText(doc.title, query)}</a>
            <div class="search-result-excerpt">${highlightText(doc.body.substring(0, 100), query)}...</div>
        </div>
    `).join('');

    container.innerHTML = html;
    container.classList.add('show');
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
    // Initialize search index
    initializeSearch();

    // Set up search input
    const searchInput = document.getElementById('searchInput');
    const searchResults = document.getElementById('searchResults');

    if (!searchInput || !searchResults) {
        console.warn('Search elements not found');
        return;
    }

    // Search as user types
    searchInput.addEventListener('input', function(e) {
        const query = e.target.value;

        if (query.length < 2) {
            searchResults.classList.remove('show');
            return;
        }

        const results = performSearch(query);
        displayResults(results, query, 'searchResults');
    });

    // Hide results when clicking outside
    searchInput.addEventListener('blur', function() {
        setTimeout(() => {
            searchResults.classList.remove('show');
        }, 200);
    });

    // Show results again on focus if there's a query
    searchInput.addEventListener('focus', function() {
        if (this.value.length >= 2) {
            const results = performSearch(this.value);
            displayResults(results, this.value, 'searchResults');
        }
    });

    // Prevent results from closing when clicking on them
    searchResults.addEventListener('mousedown', function(e) {
        e.preventDefault();
    });
});
