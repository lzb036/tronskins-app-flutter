const String steamSessionInjectionScript = r"""
(function() {
  if (window.__tronSteamRefreshTokenInjected) {
    return;
  }
  window.__tronSteamRefreshTokenInjected = true;

  const state = {
    isProcessing: false,
    isPolling: false,
    pollingTimer: null,
    sessionStartTime: 0,
    sessionTimeout: 120000,
    maxPollAttempts: 60,
    pollAttempts: 0,
    interactionDetectedTime: 0,
    maxInteractionWaitTime: 45000,
    hasReceivedRefreshToken: false,
    hasEnteredCode: false,
    codeUiReady: false
  };

  let formAccount = '';
  let formPassword = '';
  let beginAuthRes = {};
  let lastReportedRefreshToken = '';

  const qs = (selector) => document.querySelector(selector);
  const qsa = (selector) => Array.from(document.querySelectorAll(selector));
  const readText = (value) => String(value == null ? '' : value).trim();
  const now = () => Date.now();
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

  const getLocalizedText = (key) => {
    const pageLang = document.documentElement.lang || '';
    const isChinese = pageLang.toLowerCase().indexOf('zh') !== -1;
    const dict = isChinese ? {
      signIn: '登录',
      account: '账户',
      authenticator: '此账户受到手机验证器保护。',
      enterCode: '输入您 Steam 手机应用上的代码',
      backupCode: '使用备用码',
      help: '请求帮助，我已无法访问我的 Steam 手机应用',
      waitingForApprove: '请在 Steam 移动应用中确认登录...',
      invalidCredential: '请核对您的密码和账户名称并重试。',
      invalidCode: '代码错误，请重试',
      networkError: '请求失败，请稍后重试'
    } : {
      signIn: 'Sign in',
      account: 'Account',
      authenticator: 'You have a mobile authenticator protecting this account.',
      enterCode: 'Enter the code from your Steam Mobile App',
      backupCode: 'Use backup code',
      help: 'Help, I no longer have access to my Steam Mobile App',
      waitingForApprove: 'Waiting for approval in Steam Mobile App...',
      invalidCredential: 'Please check your password and account name and try again.',
      invalidCode: 'Code error, please try again.',
      networkError: 'Request failed, please try again.'
    };
    return dict[key] || key;
  };

  const ensureRuntimeReady = () => {
    return !!(window.$J && window.RSA && typeof window.$J.ajax === 'function');
  };

  const clearLoginError = () => {
    qsa('._2GBWeup5cttgbTw8FM3tfx').forEach((input) => {
      input.style.border = '';
      input.style.borderColor = '';
      input.style.borderRadius = '';
    });
    const existingError = qs('.login-error-message');
    if (existingError) {
      existingError.remove();
    }
  };

  const showLoginError = (message) => {
    const formInputs = qsa('._2GBWeup5cttgbTw8FM3tfx');
    formInputs.forEach((input) => {
      input.style.border = '1px solid';
      input.style.borderColor = '#c05654';
      input.style.borderRadius = '3px';
      input.removeEventListener('input', clearLoginError);
      input.addEventListener('input', clearLoginError);
    });

    const existingError = qs('.login-error-message');
    if (existingError) {
      existingError.remove();
    }

    const errorMsg = document.createElement('div');
    errorMsg.className = 'login-error-message';
    errorMsg.style.cssText =
      'text-align:center;color:#c05654;font-size:14px;margin-top:12px;max-width:320px;margin-left:auto;margin-right:auto;';
    errorMsg.textContent = message;

    const loginButton = qs('.DjSvCZoKKfoNSmarsEcTS');
    if (loginButton && loginButton.parentNode) {
      loginButton.parentNode.insertBefore(errorMsg, loginButton.nextSibling);
    }
  };

  const isSessionExpired = () => {
    if (!state.sessionStartTime) {
      return true;
    }
    return now() - state.sessionStartTime > state.sessionTimeout;
  };

  const isInteractionWaitTooLong = () => {
    if (!state.interactionDetectedTime) {
      return false;
    }
    return now() - state.interactionDetectedTime > state.maxInteractionWaitTime;
  };

  const cleanupPolling = () => {
    if (state.pollingTimer) {
      clearInterval(state.pollingTimer);
      state.pollingTimer = null;
    }
    state.isPolling = false;
    state.pollAttempts = 0;
    state.interactionDetectedTime = 0;
  };

  const restartAuthFlow = () => {
    cleanupPolling();
    state.isProcessing = false;
    state.hasReceivedRefreshToken = false;
    state.hasEnteredCode = false;
    state.codeUiReady = false;
    setTimeout(() => {
      window.location.reload();
    }, 600);
  };

  const setRefreshTokenTitle = (refreshToken, steamIdOverride) => {
    const steamId = readText(steamIdOverride) || readText(beginAuthRes.steamid);
    document.title = readText(refreshToken) +
      (steamId ? '&steamId=' + steamId : '');
  };

  const postRefreshTokenToApp = (refreshToken, steamId) => {
    const payload = JSON.stringify({
      refreshToken: readText(refreshToken),
      steamId: readText(steamId)
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

  const reportRefreshToken = (refreshToken, steamIdOverride) => {
    const normalizedRefreshToken = readText(refreshToken);
    if (!normalizedRefreshToken) {
      return;
    }
    if (lastReportedRefreshToken === normalizedRefreshToken) {
      return;
    }

    const steamId = readText(steamIdOverride) || readText(beginAuthRes.steamid);
    lastReportedRefreshToken = normalizedRefreshToken;
    state.hasReceivedRefreshToken = true;
    cleanupPolling();
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
        new RegExp('name="' + escapeRegExp(key) + '"\\r?\\n\\r?\\n([^\\r\\n]+)')
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
    const requestUrl = readText(url);
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

    const steamId =
      extractRequestField(body, 'steamID') || readText(beginAuthRes.steamid);
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
              : input && input.body
                ? input.body
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

  const validateCredentials = async (account, password) => {
    return new Promise((resolve) => {
      try {
        window.$J.ajax({
          type: 'GET',
          url:
            'https://api.steampowered.com/IAuthenticationService/GetPasswordRSAPublicKey/v1/?account_name=' +
            encodeURIComponent(account)
        }).done(function(response) {
          const rsaData = response && response.response ? response.response : {};
          if (!rsaData.publickey_mod || !rsaData.publickey_exp || !rsaData.timestamp) {
            resolve(false);
            return;
          }

          let encryptedPassword = '';
          try {
            const pubKey = window.RSA.getPublicKey(
              rsaData.publickey_mod,
              rsaData.publickey_exp
            );
            encryptedPassword = window.RSA.encrypt(password, pubKey);
          } catch (error) {
            resolve(false);
            return;
          }

          window.$J.ajax({
            type: 'POST',
            url: 'https://api.steampowered.com/IAuthenticationService/BeginAuthSessionViaCredentials/v1/',
            data: {
              persistence: 1,
              encrypted_password: encryptedPassword,
              account_name: account,
              encryption_timestamp: rsaData.timestamp
            }
          }).done(function(beginAuth) {
            const beginAuthData = beginAuth && beginAuth.response ? beginAuth.response : {};
            if (beginAuthData && beginAuthData.client_id && beginAuthData.request_id) {
              beginAuthRes = beginAuthData;
              state.sessionStartTime = now();
              state.interactionDetectedTime = 0;
              state.hasReceivedRefreshToken = false;
              state.hasEnteredCode = false;
              state.pollAttempts = 0;
              resolve(true);
              return;
            }
            resolve(false);
          }).fail(function() {
            resolve(false);
          });
        }).fail(function() {
          resolve(false);
        });
      } catch (error) {
        resolve(false);
      }
    });
  };

  const startPollingAuthStatus = () => {
    if (state.isPolling || !beginAuthRes.client_id || !beginAuthRes.request_id) {
      return;
    }

    state.isPolling = true;
    state.pollAttempts = 0;

    state.pollingTimer = setInterval(() => {
      state.pollAttempts += 1;

      if (isSessionExpired() || state.pollAttempts > state.maxPollAttempts) {
        restartAuthFlow();
        return;
      }

      if (state.interactionDetectedTime && isInteractionWaitTooLong()) {
        restartAuthFlow();
        return;
      }

      window.$J.ajax({
        type: 'POST',
        url: 'https://api.steampowered.com/IAuthenticationService/PollAuthSessionStatus/v1/',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          Referer: 'https://steamcommunity.com'
        },
        data: {
          client_id: beginAuthRes.client_id,
          request_id: beginAuthRes.request_id
        },
        timeout: 10000
      }).done(function(pollAuth) {
        const pollAuthData = pollAuth && pollAuth.response ? pollAuth.response : {};

        if (pollAuthData.had_remote_interaction && !state.interactionDetectedTime) {
          state.interactionDetectedTime = now();
        }

        if (pollAuthData.refresh_token) {
          reportRefreshToken(
            pollAuthData.refresh_token,
            pollAuthData.steamid || beginAuthRes.steamid
          );
        }
      }).fail(function(xhr) {
        if (xhr && (xhr.status === 401 || xhr.status === 403)) {
          restartAuthFlow();
        }
      });
    }, 2000);
  };

  const ensureCodeStyle = () => {
    if (qs('#tron-steam-code-style')) {
      return;
    }
    const style = document.createElement('style');
    style.id = 'tron-steam-code-style';
    style.textContent = [
      '@keyframes tronSpin {',
      '  0% { transform: rotate(0deg); }',
      '  100% { transform: rotate(360deg); }',
      '}',
      '.tron-steam-code-loading { display:none; text-align:center; color:#007aff; font-size:14px; margin-top:8px; }',
      '.tron-steam-code-error { color:#c05654; text-align:center; font-size:14px; margin-top:8px; }'
    ].join('\n');
    document.head.appendChild(style);
  };

  const enterCodeLogin = async () => {
    if (state.codeUiReady) {
      startPollingAuthStatus();
      return;
    }

    const nodeDom = qs('._3XCnc4SuTz8V8-jXVwkt_s');
    if (!nodeDom) {
      state.isProcessing = false;
      return;
    }

    ensureCodeStyle();
    state.codeUiReady = true;
    state.isProcessing = true;

    nodeDom.innerHTML = '';

    const formElement = document.createElement('form');
    const container = document.createElement('div');
    container.className = '_1NOsG2PAO2rRBb8glCFM_6 _2QHQ1DkwVuPafY7Yr1Df6w';
    container.style.gap = '14px';

    const accountElement = document.createElement('div');
    accountElement.className = '_3JBYGcszFcaSNXHHSR3kCV';

    const accountText = document.createElement('div');
    accountText.className = '_1hKgiFuFaVR_Sq1Gj_gCnd';
    accountText.appendChild(document.createTextNode(getLocalizedText('account') + ': '));
    const accountSpan = document.createElement('span');
    accountSpan.className = '_31Vq4lzNWs4WikXVr9J4hz';
    accountSpan.textContent = formAccount;
    accountText.appendChild(accountSpan);

    const authText = document.createElement('div');
    authText.className = '_2o5mE8JpPFOyJ0HwX_y0y7';
    authText.textContent = getLocalizedText('authenticator');

    accountElement.appendChild(accountText);
    accountElement.appendChild(authText);

    const codeElement = document.createElement('div');
    codeElement.className = '_3huyZ7Eoy2bX4PbCnH3p5w';

    const inputContainer = document.createElement('div');
    inputContainer.className = '_1NOsG2PAO2rRBb8glCFM_6 _2QHQ1DkwVuPafY7Yr1Df6w';
    inputContainer.style.gap = '2px';

    const inputErrorWrapper = document.createElement('div');
    const inputWrapper = document.createElement('div');
    inputWrapper.className = '_1gzkmmy_XA39rp9MtxJfZJ Panel Focusable';

    const loadingElement = document.createElement('div');
    loadingElement.className = 'tron-steam-code-loading';

    const steamCodes = ['', '', '', '', ''];
    const inputs = [];

    const clearCodeError = () => {
      inputErrorWrapper.innerHTML = '';
    };

    const showCodeError = (message) => {
      inputErrorWrapper.innerHTML =
        '<div class="tron-steam-code-error">' + message + '</div>';
      inputs.forEach((input) => {
        input.style.borderColor = '#c05654';
      });
      loadingElement.style.display = 'none';
      inputs.forEach((input) => {
        input.disabled = false;
      });
    };

    const showCodeLoading = () => {
      loadingElement.style.display = 'block';
      loadingElement.innerHTML =
        '<div style="display:flex;align-items:center;justify-content:center;gap:8px;">' +
        '<div style="width:16px;height:16px;border:2px solid #007aff;border-top:2px solid transparent;border-radius:50%;animation:tronSpin 1s linear infinite;"></div>' +
        '<span>' + getLocalizedText('waitingForApprove') + '</span>' +
        '</div>';
      inputs.forEach((input) => {
        input.disabled = true;
      });
    };

    const hideCodeLoading = () => {
      loadingElement.style.display = 'none';
      inputs.forEach((input) => {
        input.disabled = false;
        input.style.backgroundColor = '';
      });
    };

    const markCodeSuccess = () => {
      hideCodeLoading();
      inputs.forEach((input) => {
        input.style.borderColor = '#52c41a';
        input.style.backgroundColor = '#f6ffed';
      });
    };

    const submitCode = () => {
      const code = steamCodes.join('');
      if (code.length !== 5) {
        return;
      }
      if (!beginAuthRes.client_id || !beginAuthRes.request_id) {
        showCodeError(getLocalizedText('invalidCode'));
        return;
      }
      if (isSessionExpired()) {
        restartAuthFlow();
        return;
      }

      state.hasEnteredCode = true;
      clearCodeError();
      showCodeLoading();

      window.$J.ajax({
        type: 'POST',
        url: 'https://api.steampowered.com/IAuthenticationService/UpdateAuthSessionWithSteamGuardCode/v1',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          Referer: 'https://steamcommunity.com'
        },
        data: {
          client_id: beginAuthRes.client_id,
          steamid: beginAuthRes.steamid,
          code_type: '3',
          code: code
        },
        timeout: 10000
      }).done(function(updateAuth) {
        const codeRes = updateAuth && updateAuth.response ? updateAuth.response : {};
        if (readText(codeRes.agreement_session_url) === '') {
          markCodeSuccess();
          return;
        }
        showCodeError(getLocalizedText('invalidCode'));
      }).fail(function() {
        showCodeError(getLocalizedText('invalidCode'));
        setTimeout(restartAuthFlow, 3000);
      });
    };

    for (let i = 0; i < 5; i += 1) {
      const input = document.createElement('input');
      input.type = 'text';
      input.maxLength = 1;
      input.autocomplete = 'none';
      input.className = '_3xcXqLVteTNHmk-gh9W65d Focusable';
      input.setAttribute('role', 'button');

      input.addEventListener('input', function(e) {
        clearCodeError();
        e.target.value = e.target.value.replace(/[^a-zA-Z0-9]/g, '').toUpperCase();
        steamCodes[i] = e.target.value;

        if (e.target.value.length === 1 && i < 4) {
          inputs[i + 1].focus();
        }

        if (steamCodes.every((item) => item && item.length === 1)) {
          submitCode();
        }
      });

      input.addEventListener('keydown', function(e) {
        if (e.key === 'Backspace' && e.target.value.length === 0 && i > 0) {
          inputs[i - 1].focus();
        }
        if (e.key === 'ArrowLeft' && i > 0) {
          inputs[i - 1].focus();
          e.preventDefault();
        }
        if (e.key === 'ArrowRight' && i < 4) {
          inputs[i + 1].focus();
          e.preventDefault();
        }
      });

      inputs.push(input);
      inputWrapper.appendChild(input);
    }

    inputContainer.appendChild(inputErrorWrapper);
    inputContainer.appendChild(inputWrapper);
    codeElement.appendChild(inputContainer);
    codeElement.appendChild(loadingElement);

    const hintElement = document.createElement('div');
    hintElement.className = '_2Io_Jc8M4cRHn9cU4vHcqW';
    hintElement.style.display = 'flex';
    hintElement.style.flexDirection = 'row';
    hintElement.style.justifyContent = 'space-evenly';
    hintElement.style.alignItems = 'center';

    const hintText = document.createElement('div');
    hintText.className = '_1rEWOv1g1uTXNhoWiJLQZs';
    hintText.textContent = getLocalizedText('enterCode');
    hintElement.appendChild(hintText);
    codeElement.appendChild(hintElement);

    const backupLink = document.createElement('div');
    backupLink.className = '_1K431RbY14lkaFW6-XgSsC _2FyQDUS2uHbW1fzoFK2jLx';
    backupLink.textContent = getLocalizedText('backupCode');

    const helpLink = document.createElement('a');
    helpLink.className = '_1K431RbY14lkaFW6-XgSsC _2FyQDUS2uHbW1fzoFK2jLx';
    helpLink.href =
      'https://help.steampowered.com/wizard/HelpWithLoginInfo?lost=8&issueid=402';
    helpLink.textContent = getLocalizedText('help');

    container.appendChild(accountElement);
    container.appendChild(codeElement);
    container.appendChild(backupLink);
    container.appendChild(helpLink);
    formElement.appendChild(container);
    nodeDom.appendChild(formElement);

    startPollingAuthStatus();
    if (inputs[0]) {
      inputs[0].focus();
    }
  };

  const handleLoginAttempt = async (event) => {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
      if (typeof event.stopImmediatePropagation === 'function') {
        event.stopImmediatePropagation();
      }
    }

    if (state.isProcessing || !ensureRuntimeReady()) {
      return false;
    }

    const formInputs = qsa('._2GBWeup5cttgbTw8FM3tfx');
    formAccount = formInputs[0] ? readText(formInputs[0].value) : '';
    formPassword = formInputs[1] ? readText(formInputs[1].value) : '';

    if (!formAccount || !formPassword) {
      showLoginError(getLocalizedText('invalidCredential'));
      return false;
    }

    clearLoginError();
    state.isProcessing = true;
    state.codeUiReady = false;

    const isValid = await validateCredentials(formAccount, formPassword);
    if (!isValid) {
      state.isProcessing = false;
      showLoginError(getLocalizedText('invalidCredential'));
      return false;
    }

    await enterCodeLogin();
    return false;
  };

  const bindLoginInterceptors = () => {
    const loginButton = qs('.DjSvCZoKKfoNSmarsEcTS');
    const form = loginButton ? loginButton.closest('form') : null;

    if (loginButton && !loginButton.__tronSteamRefreshBound) {
      loginButton.__tronSteamRefreshBound = true;
      loginButton.addEventListener('click', handleLoginAttempt, true);
    }

    if (form && !form.__tronSteamRefreshBound) {
      form.__tronSteamRefreshBound = true;
      form.addEventListener('submit', handleLoginAttempt, true);
    }
  };

  const analyzePageState = () => {
    return {
      isLoginPage:
        !!qs('._2GBWeup5cttgbTw8FM3tfx') ||
        !!qs('.DjSvCZoKKfoNSmarsEcTS'),
      isCodeInputPage: !!qs('input[type="text"][maxlength="1"]'),
      isLoggedIn:
        !!qs('[data-steamid]') ||
        !!qs('.persona') ||
        window.location.href.indexOf('/profiles/') !== -1 ||
        window.location.href.indexOf('/id/') !== -1
    };
  };

  const initLoginFlow = () => {
    if (!ensureRuntimeReady()) {
      return;
    }

    const pageState = analyzePageState();
    if (pageState.isLoginPage && !pageState.isCodeInputPage) {
      bindLoginInterceptors();
      return;
    }

    if (pageState.isCodeInputPage) {
      startPollingAuthStatus();
    }
  };

  hookFinalLoginTransport();
  setTimeout(initLoginFlow, 500);
  window.__tronSteamRefreshWatchTimer = setInterval(initLoginFlow, 1000);
})();
""";
