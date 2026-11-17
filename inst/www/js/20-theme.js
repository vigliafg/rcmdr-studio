    function rcmdrThemeClasses(theme) {
      if (theme === 'system') {
        var prefersDark = window.matchMedia &&
          window.matchMedia('(prefers-color-scheme: dark)').matches;
        theme = prefersDark ? 'dark' : 'light';
      }
      if (theme === 'dark-dim') return ['rcmdr-dark', 'rcmdr-dark-dim'];
      if (theme === 'dark-graphite') return ['rcmdr-dark', 'rcmdr-dark-graphite'];
      if (theme === 'dark') return ['rcmdr-dark'];
      if (theme === 'contrast') return ['rcmdr-contrast'];
      if (theme === 'light-warm') return ['rcmdr-light-warm'];
      if (theme === 'light-cool') return ['rcmdr-light-cool'];
      return ['rcmdr-light'];
    }
    var rcmdrThemeChoice = 'system';
    function rcmdrApplyTheme(theme) {
      var body = document.body;
      if (!body) return;
      if (typeof theme !== 'string' || !theme) theme = 'system';
      rcmdrThemeChoice = theme;
      body.classList.remove('rcmdr-dark', 'rcmdr-dark-dim',
        'rcmdr-dark-graphite', 'rcmdr-light', 'rcmdr-light-warm',
        'rcmdr-light-cool', 'rcmdr-contrast');
      rcmdrThemeClasses(theme).forEach(function(name) {
        body.classList.add(name);
      });
      body.setAttribute('data-rcmdr-theme', theme);
      try { window.localStorage.setItem('rcmdr-theme', theme); } catch (e) {}
    }
    function rcmdrApplyDensity(density) {
      var body = document.body;
      if (!body) return;
      var comfortable = density === 'comfortable';
      body.classList.toggle('rcmdr-density-comfortable', comfortable);
      body.classList.toggle('rcmdr-density-compact', !comfortable);
      body.setAttribute('data-rcmdr-density',
                        comfortable ? 'comfortable' : 'compact');
      try {
        window.localStorage.setItem('rcmdr-density',
                                    comfortable ? 'comfortable' : 'compact');
      } catch (e) {}
    }
    Shiny.addCustomMessageHandler('rcmdr-theme', function(payload) {
      // A plain string is the old theme-only message; objects carry both.
      var theme = payload;
      var density = null;
      if (payload && typeof payload === 'object') {
        theme = payload.theme;
        density = payload.density;
      }
      rcmdrApplyTheme(theme);
      if (density) rcmdrApplyDensity(density);
    });
    (function() {
      function applyStoredTheme() {
        var stored = 'system';
        try { stored = window.localStorage.getItem('rcmdr-theme') || 'system'; }
        catch (e) { stored = 'system'; }
        rcmdrApplyTheme(stored);
        var density = 'compact';
        try {
          density = window.localStorage.getItem('rcmdr-density') || 'compact';
        } catch (e) { density = 'compact'; }
        rcmdrApplyDensity(density);
      }
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', applyStoredTheme);
      } else {
        applyStoredTheme();
      }
      if (window.matchMedia) {
        var media = window.matchMedia('(prefers-color-scheme: dark)');
        var onSystemTheme = function() {
          if (rcmdrThemeChoice === 'system') rcmdrApplyTheme('system');
        };
        if (media.addEventListener) media.addEventListener('change', onSystemTheme);
        else if (media.addListener) media.addListener(onSystemTheme);
      }
    })();
