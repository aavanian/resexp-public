/**
 * Simple client-side search implementation
 * No external dependencies - works entirely offline
 */

// Search index - will be populated from docs
let searchIndex = [];

/**
 * Initialize search index from documents
 */
function initializeSearchIndex() {
    // This will be populated with content from all documentation files
    // Format: { title, content, url, excerpt }
    searchIndex = [
        {
            title: "Welcome",
            url: "docs/welcome.html",
            content: "welcome documentation getting started introduction overview",
            excerpt: "Welcome to the documentation. Get started with our comprehensive guides."
        },
        {
            title: "Installation",
            url: "docs/installation.html",
            content: "installation setup install configure requirements dependencies",
            excerpt: "Learn how to install and set up the system on your machine."
        },
        {
            title: "Quick Start",
            url: "docs/quick-start.html",
            content: "quick start tutorial guide first steps hello world",
            excerpt: "Get up and running quickly with this step-by-step tutorial."
        },
        {
            title: "User Guide",
            url: "docs/user-guide.html",
            content: "user guide manual documentation how to usage instructions",
            excerpt: "Comprehensive guide covering all features and functionality."
        },
        {
            title: "API Reference",
            url: "docs/api-reference.html",
            content: "api reference methods functions classes interfaces types",
            excerpt: "Complete API documentation with all available methods and types."
        },
        {
            title: "Code Examples",
            url: "docs/examples.html",
            content: "examples code samples snippets demonstrations tutorials",
            excerpt: "Practical code examples showing common use cases and patterns."
        }
    ];
}

/**
 * Perform search across all indexed documents
 * @param {string} query - Search query
 * @returns {Array} - Array of matching results
 */
function performSearch(query) {
    if (!query || query.length < 2) {
        return [];
    }

    const normalizedQuery = query.toLowerCase().trim();
    const queryWords = normalizedQuery.split(/\s+/);

    // Score each document
    const results = searchIndex.map(doc => {
        let score = 0;
        const titleLower = doc.title.toLowerCase();
        const contentLower = doc.content.toLowerCase();

        // Check each query word
        queryWords.forEach(word => {
            // Title matches are worth more
            if (titleLower.includes(word)) {
                score += 10;
            }

            // Content matches
            if (contentLower.includes(word)) {
                score += 5;
            }

            // Exact phrase match bonus
            if (contentLower.includes(normalizedQuery)) {
                score += 15;
            }
        });

        return {
            ...doc,
            score: score
        };
    });

    // Filter and sort by score
    return results
        .filter(result => result.score > 0)
        .sort((a, b) => b.score - a.score)
        .slice(0, 10); // Limit to top 10 results
}

/**
 * Highlight search terms in text
 * @param {string} text - Text to highlight
 * @param {string} query - Search query
 * @returns {string} - HTML with highlighted terms
 */
function highlightSearchTerms(text, query) {
    if (!query) return text;

    const queryWords = query.toLowerCase().trim().split(/\s+/);
    let result = text;

    queryWords.forEach(word => {
        if (word.length < 2) return;
        const regex = new RegExp(`(${escapeRegex(word)})`, 'gi');
        result = result.replace(regex, '<span class="search-highlight">$1</span>');
    });

    return result;
}

/**
 * Escape special regex characters
 * @param {string} str - String to escape
 * @returns {string} - Escaped string
 */
function escapeRegex(str) {
    return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * Display search results
 * @param {Array} results - Search results to display
 * @param {string} query - Original search query
 */
function displaySearchResults(results, query) {
    const searchResults = document.getElementById('searchResults');

    if (results.length === 0) {
        searchResults.innerHTML = '<div class="search-result-item">No results found</div>';
        searchResults.classList.add('active');
        return;
    }

    const html = results.map(result => `
        <div class="search-result-item" onclick="loadPage('${result.url}')">
            <div class="search-result-title">${highlightSearchTerms(result.title, query)}</div>
            <div class="search-result-excerpt">${highlightSearchTerms(result.excerpt, query)}</div>
        </div>
    `).join('');

    searchResults.innerHTML = html;
    searchResults.classList.add('active');
}

/**
 * Hide search results
 */
function hideSearchResults() {
    const searchResults = document.getElementById('searchResults');
    setTimeout(() => {
        searchResults.classList.remove('active');
    }, 200);
}

/**
 * Load a page (referenced by search results)
 * @param {string} url - URL of page to load
 */
function loadPage(url) {
    // Extract page identifier from URL
    const pageId = url.replace('docs/', '').replace('.html', '');
    const navLink = document.querySelector(`[data-page="${pageId}"]`);
    if (navLink) {
        navLink.click();
    }
}

// Initialize search when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    initializeSearchIndex();

    const searchInput = document.getElementById('searchInput');

    // Perform search on input
    searchInput.addEventListener('input', function(e) {
        const query = e.target.value;

        if (query.length < 2) {
            hideSearchResults();
            return;
        }

        const results = performSearch(query);
        displaySearchResults(results, query);
    });

    // Hide results when clicking outside
    searchInput.addEventListener('blur', hideSearchResults);

    // Keep results visible when clicking on them
    document.getElementById('searchResults').addEventListener('mousedown', function(e) {
        e.preventDefault();
    });
});
