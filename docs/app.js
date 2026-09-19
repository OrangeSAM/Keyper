/**
 * Keyper Web Audio Engine & Interactive Simulator
 * 1:1 acoustic logic matching native macOS Keyper app
 */

class KeyperWebAudioEngine {
  constructor() {
    this.ctx = null;
    this.schemes = [];
    this.currentScheme = null;
    this.audioBuffers = new Map(); // key: "scheme/filename" -> AudioBuffer
    this.volume = 0.7;
    this.pitch = 1.0;
    this.lastTimeMs = 0;
    this.lastKeycode = -1;
    this.isLoading = false;
  }

  initContext() {
    if (!this.ctx) {
      const AudioContext = window.AudioContext || window.webkitAudioContext;
      this.ctx = new AudioContext();
    }
    if (this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  async loadSchemes() {
    try {
      const res = await fetch('./data/schemes.json');
      this.schemes = await res.json();
      // Default to user's favorite: Cherry_G80_3000
      const defaultScheme = this.schemes.find(s => s.name === 'Cherry_G80_3000') || this.schemes[0];
      await this.setScheme(defaultScheme.name);
    } catch (err) {
      console.error('Failed to load schemes.json:', err);
    }
  }

  async setScheme(schemeName) {
    const scheme = this.schemes.find(s => s.name === schemeName);
    if (!scheme) return;
    this.currentScheme = scheme;
    this.isLoading = true;

    // Preload audio files for this scheme
    const promises = scheme.files.map(async (file) => {
      const cacheKey = `${scheme.name}/${file}`;
      if (this.audioBuffers.has(cacheKey)) return;

      try {
        const response = await fetch(`./data/${scheme.name}/${file}`);
        const arrayBuffer = await response.arrayBuffer();
        this.initContext();
        const audioBuffer = await this.ctx.decodeAudioData(arrayBuffer);
        this.audioBuffers.set(cacheKey, audioBuffer);
      } catch (e) {
        console.warn(`Failed to decode audio: ${cacheKey}`, e);
      }
    });

    await Promise.all(promises);
    this.isLoading = false;
  }

  isTooFrequent(keyCode) {
    const now = performance.now();
    const delta = now - this.lastTimeMs;
    if (delta < 120 && this.lastKeycode === keyCode) {
      this.lastTimeMs = now;
      return true;
    }
    this.lastKeycode = keyCode;
    this.lastTimeMs = now;
    return false;
  }

  playKey(macKeyCode) {
    this.initContext();
    if (!this.currentScheme || this.isLoading) return;

    // Debounce check matching original Tickeys
    if (this.isTooFrequent(macKeyCode)) return;

    // Get buffer index matching original Tickeys deterministic algorithm
    let audioIndex = 0;
    const strKey = String(macKeyCode);
    if (this.currentScheme.key_audio_map && this.currentScheme.key_audio_map[strKey] !== undefined) {
      audioIndex = this.currentScheme.key_audio_map[strKey];
    } else if (this.currentScheme.non_unique_count > 0) {
      audioIndex = Math.abs(macKeyCode) % this.currentScheme.non_unique_count;
    }

    const fileName = this.currentScheme.files[audioIndex];
    if (!fileName) return;

    const cacheKey = `${this.currentScheme.name}/${fileName}`;
    const buffer = this.audioBuffers.get(cacheKey);
    if (!buffer) return;

    // Create source node & gain node
    const source = this.ctx.createBufferSource();
    source.buffer = buffer;
    // Pure Varispeed playbackRate (matching native AVAudioUnitVarispeed)
    source.playbackRate.value = this.pitch;

    const gainNode = this.ctx.createGain();
    gainNode.gain.value = this.volume;

    source.connect(gainNode);
    gainNode.connect(this.ctx.destination);
    source.start(0);
  }
}

// Standard macOS KeyCode mapping from Web KeyboardEvent.code
const WEB_CODE_TO_MAC_KEYCODE = {
  KeyA: 0, KeyS: 1, KeyD: 2, KeyF: 3, KeyH: 4, KeyG: 5, KeyZ: 6, KeyX: 7,
  KeyC: 8, KeyV: 9, KeyB: 11, KeyQ: 12, KeyW: 13, KeyE: 14, KeyR: 15,
  KeyY: 16, KeyT: 17, Digit1: 18, Digit2: 19, Digit3: 20, Digit4: 21,
  Digit6: 22, Digit5: 23, Equal: 24, Digit9: 25, Digit7: 26, Minus: 27,
  Digit8: 28, Digit0: 29, BracketRight: 30, KeyO: 31, KeyU: 32,
  BracketLeft: 33, KeyI: 34, KeyP: 35, Enter: 36, KeyL: 37, KeyJ: 38,
  Quote: 39, KeyK: 40, Semicolon: 41, Backslash: 42, Comma: 43,
  Slash: 44, KeyN: 45, KeyM: 46, Period: 47, Tab: 48, Space: 49,
  Backquote: 50, Backspace: 51, Escape: 53, CapsLock: 57,
  ShiftLeft: 56, ShiftRight: 60, ControlLeft: 59, AltLeft: 58, MetaLeft: 55,
  ArrowLeft: 123, ArrowRight: 124, ArrowDown: 125, ArrowUp: 126
};

// Secret sequence: Q (12), A (0), Z (6), 1 (18), 2 (19), 3 (20)
const SECRET_SEQUENCE = [12, 0, 6, 18, 19, 20];

document.addEventListener('DOMContentLoaded', async () => {
  const engine = new KeyperWebAudioEngine();
  await engine.loadSchemes();

  const sandboxInput = document.getElementById('sandboxInput');
  const schemePills = document.querySelectorAll('.scheme-btn');
  const secretKeycaps = document.querySelectorAll('.secret-keycap');
  const secretStatus = document.getElementById('secretStatus');
  const modalOverlay = document.getElementById('settingsModal');
  const modalCloseBtn = document.getElementById('modalCloseBtn');
  const openModalBtn = document.getElementById('openModalBtn');

  // Scheme Switcher
  schemePills.forEach((pill) => {
    pill.addEventListener('click', async () => {
      schemePills.forEach(p => p.classList.remove('active'));
      pill.classList.add('active');
      const schemeName = pill.getAttribute('data-scheme');
      await engine.setScheme(schemeName);
      // Play instant preview click
      engine.playKey(36); // Enter key
    });
  });

  // Recent keys for QAZ123 detection
  const recentKeys = [];

  function checkSecretSequence(macCode) {
    recentKeys.push(macCode);
    if (recentKeys.length > 6) recentKeys.shift();

    if (recentKeys.length === 6 && recentKeys.every((v, i) => v === SECRET_SEQUENCE[i])) {
      // Trigger Easter Egg!
      triggerEasterEgg();
    }
  }

  function triggerEasterEgg() {
    secretKeycaps.forEach(k => k.classList.add('unlocked'));
    if (secretStatus) secretStatus.textContent = '🎉 暗号正确！已唤出设置面板！';
    
    // Play cheerful multi-tone preview
    setTimeout(() => engine.playKey(18), 0);
    setTimeout(() => engine.playKey(19), 80);
    setTimeout(() => engine.playKey(20), 160);
    setTimeout(() => engine.playKey(36), 260);

    setTimeout(() => {
      if (modalOverlay) modalOverlay.classList.add('open');
    }, 300);
  }

  // Keyboard Event Handling
  window.addEventListener('keydown', (e) => {
    engine.initContext();
    const macCode = WEB_CODE_TO_MAC_KEYCODE[e.code] !== undefined 
      ? WEB_CODE_TO_MAC_KEYCODE[e.code] 
      : 0;

    // Highlight on-screen virtual keyboard keycap
    const keycap = document.querySelector(`.keycap[data-code="${e.code}"]`);
    if (keycap) keycap.classList.add('active');

    // Play sound!
    engine.playKey(macCode);

    // Check secret code
    checkSecretSequence(macCode);
  });

  window.addEventListener('keyup', (e) => {
    const keycap = document.querySelector(`.keycap[data-code="${e.code}"]`);
    if (keycap) keycap.classList.remove('active');
  });

  // On-screen Virtual Keycaps Click / Touch
  document.querySelectorAll('.keycap').forEach((keycap) => {
    const code = keycap.getAttribute('data-code');
    const macCode = WEB_CODE_TO_MAC_KEYCODE[code] !== undefined ? WEB_CODE_TO_MAC_KEYCODE[code] : 49;

    const pressKey = () => {
      engine.initContext();
      keycap.classList.add('active');
      engine.playKey(macCode);
      checkSecretSequence(macCode);
      setTimeout(() => keycap.classList.remove('active'), 120);

      // Append character to sandbox input if not backspace/enter
      if (sandboxInput) {
        if (code === 'Backspace') {
          sandboxInput.value = sandboxInput.value.slice(0, -1);
        } else if (code === 'Space') {
          sandboxInput.value += ' ';
        } else if (code === 'Enter') {
          sandboxInput.value += '\n';
        } else {
          const char = keycap.textContent.trim();
          if (char.length === 1) sandboxInput.value += char.toLowerCase();
        }
      }
    };

    keycap.addEventListener('mousedown', pressKey);
  });

  // Interactive Secret Keys Click
  secretKeycaps.forEach((cap) => {
    cap.addEventListener('click', () => {
      const code = cap.getAttribute('data-code');
      const macCode = WEB_CODE_TO_MAC_KEYCODE[code];
      if (macCode !== undefined) {
        engine.playKey(macCode);
        checkSecretSequence(macCode);
      }
    });
  });

  // Modal controls
  if (modalCloseBtn) {
    modalCloseBtn.addEventListener('click', () => {
      modalOverlay.classList.remove('open');
      secretKeycaps.forEach(k => k.classList.remove('unlocked'));
      if (secretStatus) secretStatus.textContent = '敲击键盘测试暗号 Q A Z 1 2 3';
    });
  }

  if (modalOverlay) {
    modalOverlay.addEventListener('click', (e) => {
      if (e.target === modalOverlay) {
        modalOverlay.classList.remove('open');
        secretKeycaps.forEach(k => k.classList.remove('unlocked'));
        if (secretStatus) secretStatus.textContent = '敲击键盘测试暗号 Q A Z 1 2 3';
      }
    });
  }

  if (openModalBtn) {
    openModalBtn.addEventListener('click', () => {
      triggerEasterEgg();
    });
  }
});
