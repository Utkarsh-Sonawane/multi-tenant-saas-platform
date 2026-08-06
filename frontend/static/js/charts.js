/**
 * charts.js — Dynamic Chart.js loader for multi-tenant SaaS dashboard.
 *
 * Fetches tenant chart data from /api/charts and renders:
 *  - Doughnut chart (distribution by category/status)
 *  - Bar chart (module record overview)
 */

'use strict';

const Charts = (() => {
  let doughnutInstance = null;
  let barInstance      = null;

  // Colour palette that blends with the tenant theme
  function getColors(count, alpha = 1) {
    const base = getComputedStyle(document.documentElement)
      .getPropertyValue('--tenant-primary').trim() || '#6366f1';

    const palette = [
      base,
      '#8b5cf6', '#06b6d4', '#f59e0b',
      '#10b981', '#ef4444', '#ec4899',
      '#f97316', '#14b8a6', '#a855f7',
    ];
    return palette.slice(0, count).map(c => {
      // Inject alpha for backgrounds
      if (alpha < 1) return c + Math.round(alpha * 255).toString(16).padStart(2, '0');
      return c;
    });
  }

  function isDark() {
    return document.documentElement.getAttribute('data-bs-theme') === 'dark';
  }

  function chartDefaults() {
    return {
      plugins: {
        legend: {
          labels: {
            color: isDark() ? '#cbd5e1' : '#374151',
            font: { family: 'Inter', size: 12 },
            padding: 16,
            boxWidth: 12, boxHeight: 12, borderRadius: 6,
          },
        },
        tooltip: {
          backgroundColor: isDark() ? '#1e293b' : '#fff',
          titleColor:      isDark() ? '#f1f5f9' : '#0f172a',
          bodyColor:       isDark() ? '#94a3b8' : '#374151',
          borderColor:     isDark() ? '#334155' : '#e2e8f0',
          borderWidth: 1,
          cornerRadius: 10,
          padding: 12,
          titleFont: { weight: '700', family: 'Inter', size: 13 },
          bodyFont:  { family: 'Inter', size: 12 },
        },
      },
      animation: { duration: 600, easing: 'easeInOutQuart' },
    };
  }

  function renderDoughnut(labels, data) {
    const canvas = document.getElementById('doughnut-chart');
    if (!canvas) return;
    if (doughnutInstance) { doughnutInstance.destroy(); doughnutInstance = null; }

    const colors = getColors(labels.length);
    doughnutInstance = new Chart(canvas, {
      type: 'doughnut',
      data: {
        labels,
        datasets: [{
          data,
          backgroundColor: getColors(labels.length, 0.85),
          borderColor:     getColors(labels.length),
          borderWidth: 2,
          hoverOffset: 10,
        }],
      },
      options: {
        ...chartDefaults(),
        cutout: '72%',
        plugins: {
          ...chartDefaults().plugins,
          legend: {
            ...chartDefaults().plugins.legend,
            position: 'bottom',
          },
        },
        responsive: true,
        maintainAspectRatio: true,
      },
    });
  }

  function renderBar(labels, datasets) {
    const canvas = document.getElementById('bar-chart');
    if (!canvas) return;
    if (barInstance) { barInstance.destroy(); barInstance = null; }

    const tenantColor = getComputedStyle(document.documentElement)
      .getPropertyValue('--tenant-primary').trim() || '#6366f1';

    barInstance = new Chart(canvas, {
      type: 'bar',
      data: {
        labels,
        datasets: datasets.map((ds, i) => ({
          label:           ds.label,
          data:            ds.data,
          backgroundColor: getColors(labels.length, 0.7),
          borderColor:     getColors(labels.length),
          borderWidth: 2,
          borderRadius: 6,
          borderSkipped: false,
        })),
      },
      options: {
        ...chartDefaults(),
        responsive: true,
        maintainAspectRatio: true,
        scales: {
          x: {
            grid: { color: isDark() ? 'rgba(255,255,255,.05)' : 'rgba(0,0,0,.04)' },
            ticks: { color: isDark() ? '#64748b' : '#94a3b8', font: { family: 'Inter', size: 11 } },
          },
          y: {
            beginAtZero: true,
            grid: { color: isDark() ? 'rgba(255,255,255,.05)' : 'rgba(0,0,0,.04)' },
            ticks: { color: isDark() ? '#64748b' : '#94a3b8', font: { family: 'Inter', size: 11 }, precision: 0 },
          },
        },
      },
    });
  }

  // Fallback: render module counts as a bar chart when API returns no data
  async function renderCountsFallback() {
    if (!window.TENANT) return;
    try {
      const resp   = await fetch(`/${window.TENANT.id}/api/counts`);
      const counts = await resp.json();
      const labels = Object.keys(counts);
      const data   = Object.values(counts);
      if (labels.length) {
        renderDoughnut(labels, data);
        renderBar(labels, [{ label: 'Records', data }]);
      }
    } catch (e) {
      console.warn('[Charts] Fallback load failed:', e);
    }
  }

  async function loadCharts() {
    if (!window.TENANT) return;
    try {
      const resp = await fetch(`/${window.TENANT.id}/api/charts`);
      const data = await resp.json();

      if (data.labels && data.labels.length > 0 && data.datasets && data.datasets.length > 0) {
        const values = data.datasets[0].data;
        renderDoughnut(data.labels, values);
        renderBar(data.labels, data.datasets);
      } else {
        await renderCountsFallback();
      }
    } catch (e) {
      console.warn('[Charts] Primary load failed, trying fallback:', e);
      await renderCountsFallback();
    }
  }

  // Re-render on dark mode toggle
  const observer = new MutationObserver(() => loadCharts());
  observer.observe(document.documentElement, { attributes: true, attributeFilter: ['data-bs-theme'] });

  // Auto-load on page ready
  document.addEventListener('DOMContentLoaded', () => {
    if (document.getElementById('doughnut-chart') || document.getElementById('bar-chart')) {
      loadCharts();
    }
  });

  return { loadCharts };
})();
