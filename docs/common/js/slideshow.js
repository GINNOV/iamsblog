document.addEventListener('DOMContentLoaded', () => {
  // --- Slideshow Data ---
  // To add more images, just add a new object to this array.
  // The script will loop through them automatically.
  // IMPORTANT: The paths must be absolute from the site root.
  const slides = [
    {
      image: '/littlethings/images/slideshow/1_kickstart.png',
      description: "The iconic Kickstart 1.3 boot screen. A sight that welcomed millions of Amiga users.",
    },
    {
      image: '/littlethings/images/slideshow/2_deluxe_paint.png',
      description: "Deluxe Paint was the Amiga's killer app for artists, defining a generation of pixel art.",
    },
    {
      image: '/littlethings/images/slideshow/3_shadow_of_the_beast.png',
      description: "The parallax scrolling and stunning visuals of Shadow of the Beast showcased the Amiga's power.",
    },
    {
      image: '/littlethings/images/slideshow/4_workbench.png',
      description: 'The Amiga Workbench, a pioneering graphical user interface with multi-tasking capabilities.',
    },
    // Add more slides here, e.g.:
    // {
    //   image: '/littlethings/images/slideshow/5_another_image.png',
    //   description: 'Description for the fifth image.',
    // },
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
