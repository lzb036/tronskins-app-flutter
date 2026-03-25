const String steamSessionInjectionScript = r"""
(function() {
  if (window.__tronSteamRefreshTokenInjected) {
    return;
  }
  window.__tronSteamRefreshTokenInjected = true;

  let lastReportedRefreshToken = '';

  const readText = (value) => String(value == null ? '' : value).trim();
  const escapeRegExp = (value) =>
    String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

  const decodeRequestField = (value) => {
    const text = readText(value);
    if (!text) {
      return '';
    }
    try {
      return decodeURIComponent(text.replace(/\+/g, '%20'));
    } catch (error) {
      return text;
    }
  };

  const setRefreshTokenTitle = (refreshToken, steamId) => {
    document.title =
      readText(refreshToken) +
      (steamId ? '&steamId=' + readText(steamId) : '');
  };

  const postRefreshTokenToApp = (refreshToken, steamId) => {
    const payload = JSON.stringify({
      refreshToken: readText(refreshToken),
      steamId: readText(steamId),
    });

    try {
      if (
        window.TronSteamSession &&
        typeof window.TronSteamSession.postMessage === 'function'
      ) {
        window.TronSteamSession.postMessage(payload);
      }
    } catch (error) {}
  };

  const reportRefreshToken = (refreshToken, steamId) => {
    const normalizedRefreshToken = readText(refreshToken);
    if (!normalizedRefreshToken) {
      return;
    }
    if (lastReportedRefreshToken === normalizedRefreshToken) {
      return;
    }

    lastReportedRefreshToken = normalizedRefreshToken;
    setRefreshTokenTitle(normalizedRefreshToken, steamId);
    postRefreshTokenToApp(normalizedRefreshToken, steamId);
  };

  const extractRequestField = (body, key) => {
    if (!body) {
      return '';
    }

    if (typeof FormData !== 'undefined' && body instanceof FormData) {
      return readText(body.get(key));
    }

    if (
      typeof URLSearchParams !== 'undefined' &&
      body instanceof URLSearchParams
    ) {
      return readText(body.get(key));
    }

    if (typeof body === 'string') {
      const multipartMatch = body.match(
        new RegExp(
          'name="' + escapeRegExp(key) + '"\\r?\\n\\r?\\n([^\\r\\n]+)'
        )
      );
      if (multipartMatch && multipartMatch[1]) {
        return decodeRequestField(multipartMatch[1]);
      }

      const formMatch = body.match(
        new RegExp('(?:^|&)' + escapeRegExp(key) + '=([^&]*)')
      );
      if (formMatch && formMatch[1]) {
        return decodeRequestField(formMatch[1]);
      }
    }

    return '';
  };

  const captureFinalLoginToken = (url, body) => {
    const requestUrl = readText(url).toLowerCase();
    if (
      !requestUrl ||
      requestUrl.indexOf('login.steampowered.com/jwt/finalizelogin') === -1
    ) {
      return;
    }

    const refreshToken = extractRequestField(body, 'nonce');
    if (!refreshToken) {
      return;
    }

    const steamId = extractRequestField(body, 'steamID');
    reportRefreshToken(refreshToken, steamId);
  };

  const hookFinalLoginTransport = () => {
    if (window.__tronSteamRefreshTransportHooked) {
      return;
    }
    window.__tronSteamRefreshTransportHooked = true;

    if (typeof window.fetch === 'function') {
      const originalFetch = window.fetch;
      window.fetch = function(input, init) {
        try {
          const requestUrl =
            typeof input === 'string'
              ? input
              : input && input.url
                ? input.url
                : '';
          const requestBody =
            init && Object.prototype.hasOwnProperty.call(init, 'body')
              ? init.body
              : null;
          captureFinalLoginToken(requestUrl, requestBody);
        } catch (error) {}
        return originalFetch.apply(this, arguments);
      };
    }

    if (typeof window.XMLHttpRequest !== 'undefined') {
      const originalOpen = window.XMLHttpRequest.prototype.open;
      const originalSend = window.XMLHttpRequest.prototype.send;

      window.XMLHttpRequest.prototype.open = function(method, url) {
        this.__tronSteamRefreshRequestUrl = url;
        return originalOpen.apply(this, arguments);
      };

      window.XMLHttpRequest.prototype.send = function(body) {
        try {
          captureFinalLoginToken(this.__tronSteamRefreshRequestUrl, body);
        } catch (error) {}
        return originalSend.apply(this, arguments);
      };
    }
  };

  hookFinalLoginTransport();
})();
""";
