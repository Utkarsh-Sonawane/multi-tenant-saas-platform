/**
 * main.js — Multi-Tenant SaaS Platform
 *
 * Handles: dark mode, sidebar toggle, toast notifications,
 *          debounced search, badge loading, dashboard refresh,
 *          and loading overlay.
 */

'use strict';

/* ================================================================
   1. DARK MODE
================================================================ */
(function initDarkMode() {
  const stored = localStorage.getItem('saas-dark-mode');
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  if (stored === 'true' || (stored === null && prefersDark)) {
    document.documentElement.setAttribute('data-bs-theme', 'dark');
  }
  updateDarkIcon();
})();

function toggleDarkMode() {
  const html = document.documentElement;
  const isDark = html.getAttribute('data-bs-theme') === 'dark';
  html.setAttribute('data-bs-theme', isDark ? 'light' : 'dark');
  localStorage.setItem('saas-dark-mode', String(!isDark));
  updateDarkIcon();
  showToast(isDark ? '☀️ Light mode activated' : '🌙 Dark mode activated', 'info', 2000);
}

function updateDarkIcon() {
  const icon = document.getElementById('dark-icon');
  if (!icon) return;
  const isDark = document.documentElement.getAttribute('data-bs-theme') === 'dark';
  icon.className = isDark ? 'bi bi-sun-fill' : 'bi bi-moon-stars-fill';
}

/* ================================================================
   2. SIDEBAR TOGGLE
================================================================ */
function toggleSidebar() {
  const sidebar = document.getElementById('sidebar');
  if (!sidebar) return;
  const isMobile = window.innerWidth <= 992;
  if (isMobile) {
    sidebar.classList.toggle('mobile-open');
  } else {
    sidebar.classList.toggle('collapsed');
    localStorage.setItem('sidebar-collapsed', sidebar.classList.contains('collapsed'));
  }
}

// Restore sidebar state on load
(function restoreSidebar() {
  if (window.innerWidth > 992) {
    const collapsed = localStorage.getItem('sidebar-collapsed') === 'true';
    const sidebar   = document.getElementById('sidebar');
    if (sidebar && collapsed) sidebar.classList.add('collapsed');
  }
})();

// Close mobile sidebar on outside click
document.addEventListener('click', (e) => {
  const sidebar = document.getElementById('sidebar');
  if (!sidebar) return;
  if (window.innerWidth <= 992 &&
      sidebar.classList.contains('mobile-open') &&
      !sidebar.contains(e.target) &&
      !e.target.closest('#sidebar-toggle')) {
    sidebar.classList.remove('mobile-open');
  }
});

/* ================================================================
   3. TOAST NOTIFICATIONS
================================================================ */
const TOAST_ICONS = {
  success: 'bi-check-circle-fill text-success',
  danger:  'bi-x-circle-fill text-danger',
  warning: 'bi-exclamation-triangle-fill text-warning',
  info:    'bi-info-circle-fill text-info',
};

function showToast(message, type = 'info', duration = 4000) {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const id   = 'toast-' + Date.now();
  const icon = TOAST_ICONS[type] || TOAST_ICONS.info;
  const label = type.charAt(0).toUpperCase() + type.slice(1);

  container.insertAdjacentHTML('beforeend', `
    <div id="${id}" class="toast align-items-center" role="alert" aria-live="assertive" aria-atomic="true">
      <div class="d-flex">
        <div class="toast-body d-flex align-items-center gap-2">
          <i class="bi ${icon}"></i>
          <span>${message}</span>
        </div>
        <button type="button" class="btn-close me-2 m-auto" data-bs-dismiss="toast"></button>
      </div>
    </div>
  `);

  const el    = document.getElementById(id);
  const toast = new bootstrap.Toast(el, { delay: duration, autohide: true });
  toast.show();
  el.addEventListener('hidden.bs.toast', () => el.remove());
}

/* ================================================================
   4. LOADING OVERLAY
================================================================ */
function showLoading() {
  const ov = document.getElementById('loading-overlay');
  if (ov) ov.classList.remove('d-none');
}
function hideLoading() {
  const ov = document.getElementById('loading-overlay');
  if (ov) ov.classList.add('d-none');
}

/* ================================================================
   5. DEBOUNCED SEARCH (dashboard global search)
================================================================ */
let _globalSearchTimer = null;

function debounceSearch(value) {
  clearTimeout(_globalSearchTimer);
  _globalSearchTimer = setTimeout(() => {
    if (window.TENANT && window.TENANT.id) {
      const module = (window.TENANT.modules || [])[0];
      if (module) {
        window.location.href =
          `/${window.TENANT.id}/module/${module}?search=${encodeURIComponent(value)}`;
      }
    }
  }, 500);
}

function debounceTableSearch(value) {
  clearTimeout(_globalSearchTimer);
  _globalSearchTimer = setTimeout(() => {
    if (window.MODULE) {
      window.location.href =
        `?limit=${window.PAGE_LIMIT || 10}&offset=0&search=${encodeURIComponent(value)}`;
    }
  }, 400);
}

/* ================================================================
   6. DASHBOARD REFRESH
================================================================ */
function refreshDashboard() {
  showLoading();
  setTimeout(() => {
    window.location.reload();
  }, 300);
}

/* ================================================================
   7. BADGE LOADING (sidebar module record counts)
================================================================ */
async function loadSidebarBadges() {
  if (!window.TENANT) return;
  try {
    const resp   = await fetch(`/${window.TENANT.id}/api/counts`);
    const counts = await resp.json();
    for (const [module, count] of Object.entries(counts)) {
      const badge = document.getElementById(`badge-${module.toLowerCase()}`);
      if (badge) badge.textContent = count > 999 ? '999+' : String(count);
    }
  } catch (e) {
    // Silently ignore — badges stay at —
  }
}

/* ================================================================
   8. PAGE INIT
================================================================ */
document.addEventListener('DOMContentLoaded', () => {
  loadSidebarBadges();

  // Auto-dismiss flash alerts after 5 seconds
  document.querySelectorAll('.alert.alert-dismissible').forEach(alert => {
    setTimeout(() => {
      const bsAlert = bootstrap.Alert.getOrCreateInstance(alert);
      if (bsAlert) bsAlert.close();
    }, 5000);
  });

  // Show welcome toast on dashboard
  if (window.TENANT && window.location.pathname.includes('/dashboard')) {
    setTimeout(() => {
      showToast(`Welcome to ${window.TENANT.id.replace('-', ' ').toUpperCase()} Dashboard`, 'success', 3000);
    }, 800);
  }
});
