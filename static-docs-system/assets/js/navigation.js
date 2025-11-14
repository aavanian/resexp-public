/**
 * Navigation and page loading functionality
 * Handles loading HTML content into the main content area
 */

// Content cache to avoid re-loading
const contentCache = {};

/**
 * Load content for a specific page
 * @param {string} page - Page identifier
 */
function loadContent(page) {
    const contentFrame = document.getElementById('contentFrame');
    const url = `docs/${page}.html`;

    // Check cache first
    if (contentCache[page]) {
        contentFrame.innerHTML = contentCache[page];
        scrollToTop();
        return;
    }

    // Show loading state
    contentFrame.innerHTML = '<div class="loading">Loading content...</div>';

    // Load content via fetch
    fetch(url)
        .then(response => {
            if (!response.ok) {
                throw new Error(`Failed to load ${url}`);
            }
            return response.text();
        })
        .then(html => {
            // Cache the content
            contentCache[page] = html;
            contentFrame.innerHTML = html;
            scrollToTop();
        })
        .catch(error => {
            console.error('Error loading content:', error);
            contentFrame.innerHTML = `
                <div style="padding: 20px;">
                    <h2>Error Loading Content</h2>
                    <p>Could not load the page: <code>${page}</code></p>
                    <p>Make sure the file <code>${url}</code> exists.</p>
                </div>
            `;
        });
}

/**
 * Scroll main content to top
 */
function scrollToTop() {
    const mainContent = document.querySelector('.main-content');
    if (mainContent) {
        mainContent.scrollTop = 0;
    }
    window.scrollTo(0, 0);
}

/**
 * Update active navigation link
 * @param {HTMLElement} activeLink - The link element to mark as active
 */
function updateActiveNav(activeLink) {
    // Remove active class from all links
    document.querySelectorAll('.nav-menu a').forEach(link => {
        link.classList.remove('active');
    });

    // Add active class to clicked link
    if (activeLink) {
        activeLink.classList.add('active');
    }
}

/**
 * Handle navigation click
 * @param {Event} e - Click event
 */
function handleNavClick(e) {
    e.preventDefault();

    const link = e.target.closest('a');
    if (!link) return;

    const page = link.getAttribute('data-page');
    if (!page) return;

    // Update URL hash without scrolling
    history.pushState({ page }, '', `#${page}`);

    // Load content and update nav
    loadContent(page);
    updateActiveNav(link);
}

/**
 * Load page from URL hash
 */
function loadFromHash() {
    const hash = window.location.hash.slice(1); // Remove #
    const page = hash || 'welcome'; // Default to welcome

    const navLink = document.querySelector(`[data-page="${page}"]`);
    if (navLink) {
        loadContent(page);
        updateActiveNav(navLink);
    } else {
        // If page not found in nav, try to load it anyway
        loadContent(page);
    }
}

// Initialize navigation when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Set up navigation menu click handlers
    const navMenu = document.getElementById('navMenu');
    navMenu.addEventListener('click', handleNavClick);

    // Load initial page from hash or default
    loadFromHash();

    // Handle browser back/forward buttons
    window.addEventListener('popstate', function(e) {
        if (e.state && e.state.page) {
            const navLink = document.querySelector(`[data-page="${e.state.page}"]`);
            loadContent(e.state.page);
            updateActiveNav(navLink);
        }
    });
});
