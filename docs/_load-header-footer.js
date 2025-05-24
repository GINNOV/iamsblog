document.addEventListener('DOMContentLoaded', function() {
    const headerPlaceholder = document.getElementById('header-placeholder');
    const footerPlaceholder = document.getElementById('footer-placeholder');
    const currentPage = window.location.pathname.split('/').pop() || 'index.html'; // Get current page filename

    if (headerPlaceholder) {
        fetch('_header.html')
            .then(response => {
                if (!response.ok) {
                    throw new Error('Network response was not ok for _header.html');
                }
                return response.text();
            })
            .then(data => {
                headerPlaceholder.innerHTML = data;
                // Script for menu toggle - originally in script.js, now needs to run after header is loaded
                const menuToggle = headerPlaceholder.querySelector('.menu-toggle');
                const sidebar = headerPlaceholder.querySelector('.sidebar ul'); // Target ul within sidebar
                if (menuToggle && sidebar) {
                    // Ensure sidebar is initially hidden on mobile
                    if (window.innerWidth < 768) { // Tailwind 'md' breakpoint
                        sidebar.classList.add('hidden');
                    } else {
                        sidebar.classList.remove('hidden');
                    }

                    menuToggle.addEventListener('click', () => {
                        sidebar.classList.toggle('hidden');
                        // sidebar.classList.toggle('flex'); // Ensure display:flex is managed if needed by CSS
                    });

                    // Adjust sidebar visibility on resize
                     window.addEventListener('resize', () => {
                        if (window.innerWidth < 768) {
                            if (!sidebar.classList.contains('hidden')) {
                                // If menu was open and resized to mobile, keep it open or decide behavior
                                // For now, let's ensure it's not flex if hidden
                            }
                        } else {
                            sidebar.classList.remove('hidden'); // Always show on desktop
                           // sidebar.classList.add('flex');
                        }
                    });
                }

                // Set active navigation link
                let navId = '';
                if (currentPage === 'index.html' || currentPage === '') {
                    navId = 'nav-projects';
                } else if (currentPage === 'tutorials.html') {
                    navId = 'nav-tutorials';
                } else if (currentPage === 'resources.html') {
                    navId = 'nav-resources';
                } else if (currentPage === 'about.html') {
                    navId = 'nav-about';
                }
                if (navId) {
                    const activeLink = headerPlaceholder.querySelector('#' + navId);
                    if (activeLink) {
                        activeLink.classList.add('active');
                    }
                }
            })
            .catch(error => {
                console.error('Error fetching header:', error);
                headerPlaceholder.innerHTML = '<p>Error loading header. Please check console.</p>';
            });
    }

    if (footerPlaceholder) {
        fetch('_footer.html')
            .then(response => {
                if (!response.ok) {
                    throw new Error('Network response was not ok for _footer.html');
                }
                return response.text();
            })
            .then(data => {
                footerPlaceholder.innerHTML = data;
                // Theme toggle logic - originally in script.js, now needs to run after footer is loaded
                const themeToggle = footerPlaceholder.querySelector('#theme-toggle');
                if (themeToggle) {
                    // Set initial theme based on localStorage or system preference
                    if (localStorage.getItem('theme') === 'dark' || (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
                        document.body.classList.add('dark-theme');
                        themeToggle.textContent = 'Light Mode';
                    } else {
                        document.body.classList.remove('dark-theme');
                        themeToggle.textContent = 'Dark Mode';
                    }

                    themeToggle.addEventListener('click', () => {
                        document.body.classList.toggle('dark-theme');
                        const isDarkMode = document.body.classList.contains('dark-theme');
                        localStorage.setItem('theme', isDarkMode ? 'dark' : 'light');
                        themeToggle.textContent = isDarkMode ? 'Light Mode' : 'Dark Mode';
                    });
                }
            })
            .catch(error => {
                console.error('Error fetching footer:', error);
                footerPlaceholder.innerHTML = '<p>Error loading footer. Please check console.</p>';
            });
    }
});
