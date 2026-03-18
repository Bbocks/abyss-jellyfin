const nav = document.getElementById('nav');
window.addEventListener('scroll', () => {
  nav.classList.toggle('scrolled', window.scrollY > 20);
}, { passive: true });

//Scroll reveal
const revealEls = document.querySelectorAll('.reveal');
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.12 });
revealEls.forEach(el => observer.observe(el));

//Copy buttons
document.querySelectorAll('.copy-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const targetId = btn.getAttribute('data-target');
    const pre = document.getElementById(targetId);
    if (!pre) return;
    const text = pre.innerText || pre.textContent;
    navigator.clipboard.writeText(text.trim()).then(() => {
      btn.textContent = 'Copied!';
      btn.classList.add('copied');
      setTimeout(() => {
        btn.textContent = 'Copy';
        btn.classList.remove('copied');
      }, 2000);
    });
  });
});

//Accent swatch - update code block on click
const swatches     = document.querySelectorAll('.swatch');
const accentValEl  = document.querySelector('.accent-val');

swatches.forEach(swatch => {
  swatch.addEventListener('click', () => {
    swatches.forEach(s => {
      s.classList.remove('active');
      s.setAttribute('aria-pressed', 'false');
    });
    swatch.classList.add('active');
    swatch.setAttribute('aria-pressed', 'true');

    if (accentValEl) {
      const val = swatch.getAttribute('data-val');
      const rgb = swatch.style.getPropertyValue('--c');
      accentValEl.textContent = val;
      // flash the updated value in the swatch colour briefly
      accentValEl.style.color = `rgb(${rgb})`;
      setTimeout(() => { accentValEl.style.color = ''; }, 600);
    }
  });
});

//Radius slider
const SNAP_STOPS   = [0, 4, 8, 12, 16, 18, 20, 24];
const SNAP_RADIUS  = 1.5; // px - snap zone around each stop

const slider        = document.getElementById('radius-slider');
const radiusValEl   = document.querySelector('.radius-val');
const radiusDisplay = document.querySelector('.radius-display');
const previewCard   = document.getElementById('radius-preview-card');
const stopLabels    = document.querySelectorAll('.radius-stops span');

function updateRadiusUI(val) {
  const px = `${val}px`;

  // Update code block value
  if (radiusValEl)   radiusValEl.textContent   = px;
  // Update label in sidebar header
  if (radiusDisplay) radiusDisplay.textContent  = px;
  // Update the preview card's border-radius live
  if (previewCard)   previewCard.style.borderRadius = px;
  // Update slider aria
  if (slider) slider.setAttribute('aria-valuenow', val);

  // Highlight the nearest stop label
  stopLabels.forEach(label => {
    label.classList.toggle('active', parseInt(label.dataset.val) === val);
  });

  // Update the filled track colour via a CSS custom property
  if (slider) {
    const pct = (val / 24) * 100;
    slider.style.background = `linear-gradient(to right,
      rgba(245,245,247,0.7) 0%,
      rgba(245,245,247,0.7) ${pct}%,
      rgba(255,255,255,0.08) ${pct}%,
      rgba(255,255,255,0.08) 100%)`;
  }
}

function snapValue(raw) {
  for (const stop of SNAP_STOPS) {
    if (Math.abs(raw - stop) <= SNAP_RADIUS) return stop;
  }
  return raw;
}

if (slider) {
  slider.addEventListener('input', () => {
    const snapped = snapValue(parseInt(slider.value));
    slider.value = snapped;
    updateRadiusUI(snapped);
  });

  // Clicking a stop label jumps directly to that value
  stopLabels.forEach(label => {
    label.addEventListener('click', () => {
      const val = parseInt(label.dataset.val);
      slider.value = val;
      updateRadiusUI(val);
    });
  });

  // Initialise on load
  updateRadiusUI(parseInt(slider.value));
}

//Smooth anchor scroll with fixed nav offset
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
  anchor.addEventListener('click', (e) => {
    const href = anchor.getAttribute('href');
    if (href === '#') return;
    const target = document.querySelector(href);
    if (!target) return;
    e.preventDefault();
    const top = target.getBoundingClientRect().top + window.scrollY - 72;
    window.scrollTo({ top, behavior: 'smooth' });
  });
});