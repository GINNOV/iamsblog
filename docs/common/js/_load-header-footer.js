document.addEventListener('DOMContentLoaded', function() {
    const headerPlaceholder = document.getElementById('header-placeholder');
    const footerPlaceholder = document.getElementById('footer-placeholder');

    /**
     * Determines the correct base path for the GitHub Pages project.
     * It specifically looks for your repository name in the URL.
     * Returns '/littlethings/' when on GitHub Pages, and '/' for local development.
     */
    const getBasePath = () => {
        const path = window.location.pathname;
        if (path.includes('/littlethings/')) {
            return '/littlethings/';
        }
        return '/';
    };

    const basePath = getBasePath();

    // Paths to common resources are now built dynamically and absolutely
    const headerPath = `${basePath}common/_header.html`;
    const footerPath = `${basePath}common/_footer.html`;

    // --- Load Header ---
    if (headerPlaceholder) {
        fetch(headerPath)
            .then(response => {
                if (!response.ok) throw new Error(`Failed to load header from: ${headerPath}`);
                return response.text();
            })
            .then(data => {
                headerPlaceholder.innerHTML = data;

                // --- After loading header, fix paths of assets inside the header ---
                const headerLogo = headerPlaceholder.querySelector('.header-logo');
                if (headerLogo && headerLogo.getAttribute('src').startsWith('./')) {
                    const originalSrc = headerLogo.getAttribute('src').replace('./', '');
                    headerLogo.src = `${basePath}${originalSrc}`;
                }

                // Fix navigation link paths to be absolute
                headerPlaceholder.querySelectorAll('nav a').forEach(link => {
                    const originalHref = link.getAttribute('href');
                    if (originalHref && !originalHref.startsWith('http') && !originalHref.startsWith('#')) {
                        link.href = `${basePath}${originalHref}`;
                    }
                });
                
                // Set the 'active' class on the current page's navigation link
                const currentPath = window.location.pathname;
                headerPlaceholder.querySelectorAll('nav a').forEach(link => {
                    const linkPath = new URL(link.href).pathname;
                    if (currentPath === linkPath || (currentPath.endsWith('/') && linkPath.endsWith('/index.html'))) {
                        link.classList.add('active');
                    }
                });

                // Activate mobile menu toggle logic
                const menuToggle = headerPlaceholder.querySelector('.menu-toggle');
                const sidebar = headerPlaceholder.querySelector('.sidebar ul');
                if (menuToggle && sidebar) {
                    if (window.innerWidth < 768) sidebar.classList.add('hidden');
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
                if (!response.ok) throw new Error(`Failed to load footer from: ${footerPath}`);
                return response.text();
            })
            .then(data => {
                footerPlaceholder.innerHTML = data;

                // Activate theme toggle logic
                const themeToggle = footerPlaceholder.querySelector('#theme-toggle');
                if (themeToggle) {
                    const applyTheme = (theme) => {
                        document.body.classList.toggle('dark-theme', theme === 'dark');
                        themeToggle.textContent = theme === 'dark' ? 'Light Mode' : 'Dark Mode';
                    };
                    const savedTheme = localStorage.getItem('theme') || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
                    applyTheme(savedTheme);
                    themeToggle.addEventListener('click', () => {
                        const newTheme = document.body.classList.contains('dark-theme') ? 'light' : 'dark';
                        localStorage.setItem('theme', newTheme);
                        applyTheme(newTheme);
                    });
                }
            })
            .catch(error => console.error('Error fetching footer:', error));
    }
});
