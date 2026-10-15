/**
 * High-Visibility Cursor and Click Ripple Overlay for Playwright Screencasts
 * Injected into the browser page via page.add_init_script() or page.evaluate().
 * Persists across DOM updates and full-page navigations.
 */
(() => {
  if (window.__vbCursorInjected) return;
  window.__vbCursorInjected = true;

  const initCursor = () => {
    // Avoid duplicate DOM elements if re-run
    if (document.getElementById('vb-ai-cursor')) return;

    const style = document.createElement('style');
    style.id = 'vb-cursor-styles';
    style.innerHTML = `
      #vb-ai-cursor {
        position: fixed;
        top: 0; left: 0;
        width: 28px; height: 28px;
        pointer-events: none;
        z-index: 2147483647;
        transform: translate(-4px, -4px);
        transition: top 0.04s linear, left 0.04s linear;
        filter: drop-shadow(0 3px 6px rgba(0,0,0,0.45));
      }
      .vb-click-ring {
        position: fixed;
        pointer-events: none;
        z-index: 2147483646;
        border: 3px solid #E65100;
        background: rgba(255, 152, 0, 0.25);
        border-radius: 50%;
        width: 16px; height: 16px;
        transform: translate(-50%, -50%) scale(0.5);
        animation: vb-ripple-anim 0.55s cubic-bezier(0.16, 1, 0.3, 1) forwards;
      }
      @keyframes vb-ripple-anim {
        0% { transform: translate(-50%, -50%) scale(0.4); opacity: 1; }
        70% { opacity: 0.85; }
        100% { transform: translate(-50%, -50%) scale(4.2); opacity: 0; }
      }
      .vb-element-pulse {
        outline: 3px solid #FF9800 !important;
        box-shadow: 0 0 12px rgba(255, 152, 0, 0.6) !important;
        transition: outline 0.3s ease, box-shadow 0.3s ease !important;
      }
    `;
    document.head.appendChild(style);

    const cursor = document.createElement('div');
    cursor.id = 'vb-ai-cursor';
    cursor.innerHTML = `<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M5.5 3.21V20.8C5.5 21.45 6.27 21.79 6.75 21.35L11.44 17.02H18.5C19.16 17.02 19.5 16.22 19.04 15.75L6.54 2.75C6.09 2.28 5.5 2.6 5.5 3.21Z" fill="#FFFFFF" stroke="#111111" stroke-width="2"/>
    </svg>`;
    document.body.appendChild(cursor);

    window.addEventListener('mousemove', (e) => {
      cursor.style.left = e.clientX + 'px';
      cursor.style.top = e.clientY + 'px';
    }, true);

    window.addEventListener('mousedown', (e) => {
      const ring = document.createElement('div');
      ring.className = 'vb-click-ring';
      ring.style.left = e.clientX + 'px';
      ring.style.top = e.clientY + 'px';
      document.body.appendChild(ring);
      setTimeout(() => ring.remove(), 600);

      // Element highlight pulse
      const target = document.elementFromPoint(e.clientX, e.clientY);
      if (target && (target.tagName === 'BUTTON' || target.tagName === 'A' || target.tagName === 'INPUT' || target.closest('button, a, input, select, [role="button"]'))) {
        const interactive = target.closest('button, a, input, select, [role="button"]') || target;
        interactive.classList.add('vb-element-pulse');
        setTimeout(() => interactive.classList.remove('vb-element-pulse'), 350);
      }
    }, true);
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initCursor);
  } else {
    initCursor();
  }
})();
