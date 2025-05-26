document.addEventListener('DOMContentLoaded', function() {
    const headerPlaceholder = document.getElementById('header-placeholder');
    const footerPlaceholder = document.getElementById('footer-placeholder');
    // Assuming HTML pages are in root, and common files are in 'common/' relative to root.
    const basePath = 'common/'; 
    const currentPage = window.location.pathname.split('/').pop() || 'index.html';

    if (headerPlaceholder) {
        // Fetch from the 'common' folder, relative to the HTML page in the root
        fetch(basePath + '_header.html') 
            .then(response => {
                if (!response.ok) {
                    throw new Error('Network response was not ok for _header.html');
                }
                return response.text();
            })
            .then(data => {
                headerPlaceholder.innerHTML = data;
                const menuToggle = headerPlaceholder.querySelector('.menu-toggle');
                const sidebar = headerPlaceholder.querySelector('.sidebar ul'); 
                if (menuToggle && sidebar) {
                    if (window.innerWidth < 768) { 
                        sidebar.classList.add('hidden');
                    } else {
                        sidebar.classList.remove('hidden');
                    }
                    menuToggle.addEventListener('click', () => {
                        sidebar.classList.toggle('hidden');
                    });
                     window.addEventListener('resize', () => {
                        if (window.innerWidth < 768) {
                            // On mobile, if menu is not hidden (i.e., was open), keep it as is or hide.
                            // Current logic: if it's not hidden and we resize to mobile, it stays as is.
                            // To always hide on resize to mobile:
                            // if (!sidebar.classList.contains('hidden')) { sidebar.classList.add('hidden'); }
                        } else {
                            sidebar.classList.remove('hidden'); 
                        }
                    });
                }

                let navId = '';
                if (currentPage === 'index.html' || currentPage === '') {
                    navId = 'nav-projects';
                } else if (currentPage === 'walkthroughs.html') {
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
        // Fetch from the 'common' folder, relative to the HTML page in the root
        fetch(basePath + '_footer.html')
            .then(response => {
                if (!response.ok) {
                    throw new Error('Network response was not ok for _footer.html');
                }
                return response.text();
            })
            .then(data => {
                footerPlaceholder.innerHTML = data;
                const themeToggle = footerPlaceholder.querySelector('#theme-toggle');
                if (themeToggle) {
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
