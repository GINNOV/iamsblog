document.addEventListener('DOMContentLoaded', function() {
    const headerPlaceholder = document.getElementById('header-placeholder');
    const footerPlaceholder = document.getElementById('footer-placeholder');

    // Determine the base path to get from the current HTML page to the root directory.
    // This allows the script to work from any subdirectory level.
    const pathSegments = window.location.pathname.split('/').filter(segment => segment);
    // Remove the filename if it's there
    if (pathSegments.length > 0 && pathSegments[pathSegments.length - 1].includes('.html')) {
        pathSegments.pop();
    }
    const depth = pathSegments.length;
    const basePath = '../'.repeat(depth) || './';

    // --- Define paths to common resources relative to the site root ---
    const headerPath = `${basePath}common/_header.html`;
    const footerPath = `${basePath}common/_footer.html`;

    // --- Load Header ---
    if (headerPlaceholder) {
        fetch(headerPath)
            .then(response => {
                if (!response.ok) throw new Error(`Network response was not ok for ${headerPath}`);
                return response.text();
            })
            .then(data => {
                headerPlaceholder.innerHTML = data;
                
                // Now that the header is loaded, find the nav links within it and fix their paths
                const navLinks = headerPlaceholder.querySelectorAll('nav a');
                navLinks.forEach(link => {
                    const originalHref = link.getAttribute('href');
                    if (originalHref && !originalHref.startsWith('http') && !originalHref.startsWith('#')) {
                        link.setAttribute('href', `${basePath}${originalHref}`);
                    }
                });

                // Set the active class on the correct navigation link
                const currentPage = window.location.pathname.split('/').pop() || 'index.html';
                headerPlaceholder.querySelector(`nav a[href$="${currentPage}"]`)?.classList.add('active');
                if (currentPage === 'index.html' || currentPage === '') {
                     headerPlaceholder.querySelector(`nav a[href$="index.html"]`)?.classList.add('active');
                }
                
                // Activate mobile menu toggle logic
                const menuToggle = headerPlaceholder.querySelector('.menu-toggle');
                const sidebar = headerPlaceholder.querySelector('.sidebar ul');
                if (menuToggle && sidebar) {
                    if (window.innerWidth < 768) sidebar.classList.add('hidden');
                    else sidebar.classList.remove('hidden');

                    menuToggle.addEventListener('click', () => sidebar.classList.toggle('hidden'));
                    window.addEventListener('resize', () => {
                        if (window.innerWidth >= 768) sidebar.classList.remove('hidden');
                    });
                }
            })
            .catch(error => console.error('Error fetching header:', error));
    }

    // --- Load Footer ---
    if (footerPlaceholder) {
        fetch(footerPath)
            .then(response => {
                if (!response.ok) throw new Error(`Network response was not ok for ${footerPath}`);
                return response.text();
            })
            .then(data => {
                footerPlaceholder.innerHTML = data;

                // Activate theme toggle logic
                const themeToggle = footerPlaceholder.querySelector('#theme-toggle');
                if (themeToggle) {
                    const applyTheme = (theme) => {
                        if (theme === 'dark') {
                            document.body.classList.add('dark-theme');
                            themeToggle.textContent = 'Light Mode';
                        } else {
                            document.body.classList.remove('dark-theme');
                            themeToggle.textContent = 'Dark Mode';
                        }
                    };

                    const savedTheme = localStorage.getItem('theme');
                    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
                    
                    applyTheme(savedTheme || (prefersDark ? 'dark' : 'light'));

                    themeToggle.addEventListener('click', () => {
                        const isDarkMode = !document.body.classList.contains('dark-theme');
                        const newTheme = isDarkMode ? 'dark' : 'light';
                        localStorage.setItem('theme', newTheme);
                        applyTheme(newTheme);
                    });
                }
            })
            .catch(error => console.error('Error fetching footer:', error));
    }
});
