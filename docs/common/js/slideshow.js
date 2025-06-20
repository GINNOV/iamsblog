document.addEventListener('DOMContentLoaded', () => {
  // --- Slideshow Data ---
  // To add more images, just add a new object to this array.
  // The script will loop through them automatically.
  // IMPORTANT: The paths must be absolute from the site root.
  const slides = [
    {
      image: './images/slideshow/1_adfinder.png',
      description: "It looks like the Apple Finder with one magic touch, it works on Amiga Disk. Custom images aren't supported yet.",
    },
    {
      image: './images/slideshow/2_adfinder.png',
      description: "Create a new image using one of the two file systems supported.",
    },
    {
      image: './images/slideshow/3_adfinder.png',
      description: "Sort like a real Amiga champ.",
    },
    {
      image: './images/slideshow/4_adfinder.png',
      description: 'Delete files and folder by either honoring the original settings or using God powers.',
    },
    {
      image: './images/slideshow/5_adfinder.png',
      description: 'An Hex/Ascii viewer that allows you to export the dump of a file.',
    },
    {
      image: './images/slideshow/6_adfinder.png',
      description: 'A small but effective text editor to make startup sequene tweaks or just write a note.',
    },
    {
      image: './images/slideshow/7_adfinder.png',
      description: 'Inspect the disk blocks like a real Amiga surgeon',
    },
    {
      image: './images/slideshow/8_adfinder.png',
      description: 'Set permissions and attributes on files.',
    },
    {
      image: './images/slideshow/9_adfinder.png',
      description: 'Inspet sectors like an Amiga proctologist. Useful to compare two disks.',
    },
    {
      image: './images/slideshow/10_adfinder.png',
      description: 'Retrieve current permissions in the same fashion you do on Finder and with the same shortcuts!',
    },  
  ];

  let currentSlideIndex = 0;
  let slideInterval;

  const slideImage = document.getElementById('slideImage');
  const slideDescription = document.getElementById('slideDescription');
  const prevButton = document.getElementById('prevBtn');
  const nextButton = document.getElementById('nextBtn');
  const playPauseBtn = document.getElementById('playPauseBtn');

  function showSlide(index) {
    if (!slides || slides.length === 0 || !slideImage) {
      if(slideDescription) slideDescription.textContent = 'No images have been configured for the slideshow.';
      return;
    }
    
    // Handle index wrapping
    if (index >= slides.length) {
      currentSlideIndex = 0;
    } else if (index < 0) {
      currentSlideIndex = slides.length - 1;
    } else {
      currentSlideIndex = index;
    }

    const slide = slides[currentSlideIndex];
    slideImage.src = slide.image;
    slideImage.alt = slide.description; // Set alt text for accessibility
    slideImage.onerror = function() {
        // Handle image loading errors, e.g., show a placeholder
        this.src = 'https://placehold.co/800x450/0F172A/FF8800?text=Image+Not+Found';
        if(slideDescription) slideDescription.textContent = `Error: Could not load image at path: ${slide.image}`;
    };
    if(slideDescription) slideDescription.textContent = slide.description;
  }

  function nextSlide() {
    showSlide(currentSlideIndex + 1);
  }

  function prevSlide() {
    showSlide(currentSlideIndex - 1);
  }

  function playSlideshow() {
    clearInterval(slideInterval); // Clear any existing interval
    slideInterval = setInterval(nextSlide, 5000); // Change slide every 5 seconds
    if(playPauseBtn) {
        playPauseBtn.innerHTML = '<i class="fas fa-pause"></i><span>Pause</span>';
    }
  }

  function pauseSlideshow() {
    clearInterval(slideInterval);
    slideInterval = null;
    if(playPauseBtn) {
        playPauseBtn.innerHTML = '<i class="fas fa-play"></i><span>Play</span>';
    }
  }

  // --- Initialize Slideshow ---
  if(slideImage && prevButton && nextButton && playPauseBtn) {
      showSlide(currentSlideIndex);
      playSlideshow(); // Start automatically

      // Event Listeners
      nextButton.addEventListener('click', () => {
        nextSlide();
        // Reset the timer when manually changing slides
        if (slideInterval) {
          playSlideshow();
        }
      });

      prevButton.addEventListener('click', () => {
        prevSlide();
        // Reset the timer
        if (slideInterval) {
          playSlideshow();
        }
      });

      playPauseBtn.addEventListener('click', () => {
        if (slideInterval) {
          pauseSlideshow();
        } else {
          playSlideshow();
        }
      });
  }
});
