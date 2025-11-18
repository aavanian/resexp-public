/**
 * Documentation Search using Lunr.js
 *
 * Requires:
 * - lunr.min.js (local file)
 * - search-index.js (auto-generated from HTML files)
 *
 * To regenerate index: python3 build-search-index.py
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
        console.error('Lunr.js not loaded! Ensure lunr.min.js is available.');
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

// Perform search using lunr
function performSearch(query) {
    if (!query || query.length < 2) {
        return [];
    }

    if (!searchIndex) {
        console.error('Search index not initialized');
        return [];
    }

    try {
        // Add trailing wildcard to each term for progressive search
        const wildcardQuery = query.trim().split(/\s+/).map(term => term + '*').join(' ');
        const results = searchIndex.search(wildcardQuery);
        return results.map(result => {
            const doc = searchDocuments.find(d => d.id === result.ref);
            return {
                ...doc,
                score: result.score
            };
        });
    } catch (e) {
        console.error('Lunr search failed:', e);
        return [];
    }
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
