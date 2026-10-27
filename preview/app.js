// Initialize Lucide SVG Icons
document.addEventListener("DOMContentLoaded", () => {
  if (window.lucide) {
    window.lucide.createIcons();
  }
  updateClock();
  setInterval(updateClock, 1000);
});

// Update iOS Status Bar Clock
function updateClock() {
  const now = new Date();
  const hours = String(now.getHours()).padStart(2, "0");
  const minutes = String(now.getMinutes()).padStart(2, "0");
  const display = document.getElementById("currentTimeDisplay");
  if (display) display.textContent = `${hours}:${minutes}`;
}

// ==========================================================================
// Web Audio Synthesized Haptic Click Feedback
// ==========================================================================
class HapticAudio {
  constructor() {
    this.ctx = null;
  }
  
  init() {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (AudioCtx) this.ctx = new AudioCtx();
    }
  }

  playTap(freq = 240, duration = 0.035) {
    this.init();
    if (!this.ctx) return;
    try {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = "sine";
      osc.frequency.setValueAtTime(freq, this.ctx.currentTime);
      gain.gain.setValueAtTime(0.15, this.ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + duration);
      osc.connect(gain);
      gain.connect(this.ctx.destination);
      osc.start();
      osc.stop(this.ctx.currentTime + duration);
    } catch (e) {}
  }
}

const haptic = new HapticAudio();

// ==========================================================================
// Command Logger (Replicating WebSocket ms.remote.control Payload Stream)
// ==========================================================================
const commandLog = document.getElementById("commandLog");
const clearLogBtn = document.getElementById("clearLogBtn");

function logCommand(keyName, keyCode, type = "key") {
  if (!commandLog) return;
  
  const entry = document.createElement("div");
  entry.className = `log-entry ${type}`;
  
  const timestamp = new Date().toLocaleTimeString("vi-VN", { hour12: false });
  
  if (type === "key") {
    entry.innerHTML = `<strong>[${timestamp}] Key:</strong> ${keyName}<br><code>{"method":"ms.remote.control","params":{"Cmd":"Click","DataOfCode":"${keyCode}"}}</code>`;
  } else if (type === "app") {
    entry.innerHTML = `<strong>[${timestamp}] Launch App:</strong> ${keyName}<br><code>{"event":"ed.apps.launch","appId":"${keyCode}"}</code>`;
  } else {
    entry.textContent = `[${timestamp}] ${keyName}`;
  }
  
  commandLog.appendChild(entry);
  commandLog.scrollTop = commandLog.scrollHeight;
}

if (clearLogBtn) {
  clearLogBtn.addEventListener("click", () => {
    commandLog.innerHTML = `<div class="log-entry system">[System] Đã xóa lịch sử lệnh. Sẵn sàng...</div>`;
  });
}

// ==========================================================================
// Remote Button Actions Binding
// ==========================================================================

function bindButton(id, keyName, keyCode) {
  const btn = document.getElementById(id);
  if (!btn) return;
  btn.addEventListener("click", () => {
    haptic.playTap(320);
    logCommand(keyName, keyCode, "key");
  });
}

// Top Bar & Controls
bindButton("btnSource", "Source / Input", "KEY_SOURCE");
bindButton("btnHome", "Home (Smart Hub)", "KEY_HOME");
bindButton("btnBack", "Back / Return", "KEY_RETURN");
bindButton("btnExit", "Exit / Close", "KEY_EXIT");

// Google Assistant / Voice Search
const btnAssistantTrigger = document.getElementById("btnAssistantTrigger");
if (btnAssistantTrigger) {
  btnAssistantTrigger.addEventListener("click", () => {
    haptic.playTap(480, 0.08);
    logCommand("Voice Search / Assistant", "KEY_VOICE", "key");
  });
}

// Power Button
const btnPower = document.getElementById("btnPower");
let isPowerOn = true;
if (btnPower) {
  btnPower.addEventListener("click", () => {
    haptic.playTap(180, 0.08);
    isPowerOn = !isPowerOn;
    logCommand("Power Toggle", "KEY_POWER", "key");
    if (!isPowerOn) {
      logCommand("Gửi gói tin Wake-on-LAN (UDP Port 9 Magic Packet) khi bật lại", "", "system");
    }
  });
}

// D-Pad
bindButton("btnDpadUp", "D-Pad Up", "KEY_UP");
bindButton("btnDpadDown", "D-Pad Down", "KEY_DOWN");
bindButton("btnDpadLeft", "D-Pad Left", "KEY_LEFT");
bindButton("btnDpadRight", "D-Pad Right", "KEY_RIGHT");
bindButton("btnDpadOk", "OK / Enter", "KEY_ENTER");

// Volume & Channel Rockers
bindButton("btnVolUp", "Volume Up", "KEY_VOLUP");
bindButton("btnVolDown", "Volume Down", "KEY_VOLDOWN");
bindButton("btnChUp", "Channel Up", "KEY_CHUP");
bindButton("btnChDown", "Channel Down", "KEY_CHDOWN");

// Center 2x2 Grid (Mute, Settings, List, Guide)
bindButton("btnMute", "Mute Sound", "KEY_MUTE");
bindButton("btnSettings", "Settings / Tools", "KEY_TOOLS");
bindButton("btnList", "Channel List", "KEY_CH_LIST");
bindButton("btnGuide", "TV Guide", "KEY_GUIDE");

// Playback Controls Row (<<, >, ||, >>)
bindButton("btnRewind", "Rewind (<<)", "KEY_REWIND");
bindButton("btnPlay", "Play (>)", "KEY_PLAY");
bindButton("btnPause", "Pause (||)", "KEY_PAUSE");
bindButton("btnFastForward", "Fast Forward (>>)", "KEY_FF");

// Quick App Dock
document.querySelectorAll(".quick-app-pill").forEach(pill => {
  pill.addEventListener("click", () => {
    haptic.playTap(440);
    const appName = pill.getAttribute("data-app");
    const appId = pill.getAttribute("data-id");
    logCommand(appName, appId, "app");
  });
});

// App Drawer Cards
document.querySelectorAll(".app-card").forEach(card => {
  card.addEventListener("click", () => {
    haptic.playTap(440);
    const appName = card.getAttribute("data-app");
    const appId = card.getAttribute("data-id");
    logCommand(appName, appId, "app");
    closeAllSheets();
  });
});

// Numeric Keypad Keys
document.querySelectorAll(".num-key").forEach(key => {
  key.addEventListener("click", () => {
    haptic.playTap(380);
    const code = key.getAttribute("data-key");
    const label = key.textContent.trim();
    logCommand(`Number ${label}`, code, "key");
  });
});

document.querySelectorAll(".color-key").forEach(key => {
  key.addEventListener("click", () => {
    haptic.playTap(350);
    const code = key.getAttribute("data-key");
    const title = key.getAttribute("title");
    logCommand(`Color ${title}`, code, "key");
  });
});

// ==========================================================================
// Modal Sheets System (Keypad, Apps Drawer, Discovery)
// ==========================================================================

const sheetBackdrop = document.getElementById("sheetBackdrop");
const keypadSheet = document.getElementById("keypadSheet");
const appsSheet = document.getElementById("appsSheet");
const discoverySheet = document.getElementById("discoverySheet");
const keyboardSheet = document.getElementById("keyboardSheet");

function openSheet(sheet) {
  closeAllSheets();
  if (sheet) {
    sheet.classList.add("active");
    if (sheetBackdrop) sheetBackdrop.classList.add("active");
    // Auto focus text input when keyboard sheet opens
    if (sheet === keyboardSheet) {
      setTimeout(() => {
        const input = document.getElementById("tvTextInput");
        if (input) input.focus();
      }, 250);
    }
  }
}

function closeAllSheets() {
  document.querySelectorAll(".ios-modal-sheet").forEach(s => s.classList.remove("active"));
  if (sheetBackdrop) sheetBackdrop.classList.remove("active");
}

if (sheetBackdrop) {
  sheetBackdrop.addEventListener("click", closeAllSheets);
}

// Sheet triggers
const btnKeypadTrigger = document.getElementById("btnKeypadTrigger");
if (btnKeypadTrigger) {
  btnKeypadTrigger.addEventListener("click", () => {
    haptic.playTap(300);
    openSheet(keypadSheet);
  });
}

const btnKeyboardTrigger = document.getElementById("btnKeyboardTrigger");
if (btnKeyboardTrigger) {
  btnKeyboardTrigger.addEventListener("click", () => {
    haptic.playTap(300);
    openSheet(keyboardSheet);
  });
}

const btnAppsTrigger = document.getElementById("btnAppsTrigger");
if (btnAppsTrigger) {
  btnAppsTrigger.addEventListener("click", () => {
    haptic.playTap(300);
    openSheet(appsSheet);
  });
}

const btnConnectionBadge = document.getElementById("btnConnectionBadge");
if (btnConnectionBadge) {
  btnConnectionBadge.addEventListener("click", () => {
    haptic.playTap(300);
    openSheet(discoverySheet);
  });
}

// Close buttons
const closeKeypadBtn = document.getElementById("closeKeypadBtn");
if (closeKeypadBtn) closeKeypadBtn.addEventListener("click", closeAllSheets);

const closeKeyboardBtn = document.getElementById("closeKeyboardBtn");
if (closeKeyboardBtn) closeKeyboardBtn.addEventListener("click", closeAllSheets);

const closeAppsBtn = document.getElementById("closeAppsBtn");
if (closeAppsBtn) closeAppsBtn.addEventListener("click", closeAllSheets);

const closeDiscoveryBtn = document.getElementById("closeDiscoveryBtn");
if (closeDiscoveryBtn) closeDiscoveryBtn.addEventListener("click", closeAllSheets);

// Device Selection in Discovery Modal
document.querySelectorAll(".device-card").forEach(card => {
  card.addEventListener("click", () => {
    haptic.playTap(320);
    document.querySelectorAll(".device-card").forEach(c => c.classList.remove("active"));
    card.classList.add("active");
    
    const tvName = card.getAttribute("data-name") || "Samsung Smart TV";
    const tvIp = card.getAttribute("data-ip") || "192.168.1.150";
    
    const badgeName = document.getElementById("badgeDeviceName");
    if (badgeName) badgeName.textContent = tvName;
    
    logCommand(`Đã chuyển sang TV: ${tvName} (${tvIp})`, "", "system");
    closeAllSheets();
  });
});

// Manual IP Connect
const manualConnectBtn = document.getElementById("manualConnectBtn");
const manualIpInput = document.getElementById("manualIpInput");
if (manualConnectBtn && manualIpInput) {
  manualConnectBtn.addEventListener("click", () => {
    const ip = manualIpInput.value.trim();
    if (ip) {
      haptic.playTap(320);
      const badgeName = document.getElementById("badgeDeviceName");
      if (badgeName) badgeName.textContent = `Samsung TV (${ip})`;
      logCommand(`Kết nối thủ công tới IP: ${ip} qua wss://${ip}:8002`, "", "system");
      closeAllSheets();
    }
  });
}

// Rescan Button
const rescanBtn = document.getElementById("rescanBtn");
if (rescanBtn) {
  rescanBtn.addEventListener("click", () => {
    haptic.playTap(300);
    const label = document.getElementById("scanStatusLabel");
    if (label) label.textContent = "Đang quét broadcast SSDP (239.255.255.250)...";
    setTimeout(() => {
      if (label) label.textContent = "Tìm thấy 2 Samsung Smart TV trong mạng Wi-Fi";
    }, 1200);
  });
}

// ==========================================================================
// Simulator Sidebar Controls
// ==========================================================================

// Device Model Selector (Dynamic Island vs Notch)
const deviceButtons = document.querySelectorAll("#deviceSelector .segment-btn");
const sensorCutout = document.getElementById("sensorCutout");

deviceButtons.forEach(btn => {
  btn.addEventListener("click", () => {
    deviceButtons.forEach(b => b.classList.remove("active"));
    btn.classList.add("active");
    
    const mode = btn.getAttribute("data-device");
    if (sensorCutout) {
      if (mode === "notch") {
        sensorCutout.className = "top-sensor-cutout notch";
      } else {
        sensorCutout.className = "top-sensor-cutout dynamic-island";
      }
    }
  });
});

// TV Status Switcher Simulator
const statusButtons = document.querySelectorAll(".status-btn");
const badgeStatusText = document.getElementById("badgeStatusText");
const pulseRing = document.querySelector(".pulse-ring");
const pulseDot = document.querySelector(".pulse-dot");

statusButtons.forEach(btn => {
  btn.addEventListener("click", () => {
    statusButtons.forEach(b => b.classList.remove("active"));
    btn.classList.add("active");
    
    const state = btn.getAttribute("data-state");
    updateConnectionUI(state);
  });
});

function updateConnectionUI(state) {
  if (!badgeStatusText || !pulseDot) return;
  
  if (state === "connected") {
    badgeStatusText.textContent = "Connected";
    badgeStatusText.style.color = "var(--color-green)";
    pulseDot.style.background = "var(--color-green)";
    pulseDot.style.boxShadow = "0 0 6px var(--color-green)";
    if (pulseRing) pulseRing.style.display = "block";
    logCommand("Trạng thái: Đã kết nối WebSocket (port 8002 WSS)", "", "system");
  } else if (state === "connecting") {
    badgeStatusText.textContent = "Connecting...";
    badgeStatusText.style.color = "var(--color-orange)";
    pulseDot.style.background = "var(--color-orange)";
    pulseDot.style.boxShadow = "0 0 6px var(--color-orange)";
    if (pulseRing) pulseRing.style.display = "none";
    logCommand("Trạng thái: Đang kết nối tới TV...", "", "system");
  } else if (state === "pairing") {
    badgeStatusText.textContent = "Allow on TV";
    badgeStatusText.style.color = "var(--color-yellow)";
    pulseDot.style.background = "var(--color-yellow)";
    pulseDot.style.boxShadow = "0 0 6px var(--color-yellow)";
    if (pulseRing) pulseRing.style.display = "none";
    logCommand("Trạng thái: Đang chờ bấm 'Cho phép' trên màn hình TV", "", "system");
  } else {
    badgeStatusText.textContent = "Disconnected";
    badgeStatusText.style.color = "#888";
    pulseDot.style.background = "#666";
    pulseDot.style.boxShadow = "none";
    if (pulseRing) pulseRing.style.display = "none";
    logCommand("Trạng thái: Ngắt kết nối TV", "", "system");
  }
}

// ==========================================================================
// Smart Keyboard & Text Input (YouTube & Search)
// ==========================================================================
const tvTextInput = document.getElementById("tvTextInput");
const clearTvTextInput = document.getElementById("clearTvTextInput");
const sendTvTextBtn = document.getElementById("sendTvTextBtn");
const kbBackspaceBtn = document.getElementById("kbBackspaceBtn");
const kbSpaceBtn = document.getElementById("kbSpaceBtn");
const kbEnterBtn = document.getElementById("kbEnterBtn");

// Helper to encode UTF-8 string to Base64 in Browser
function utf8ToBase64(str) {
  return window.btoa(unescape(encodeURIComponent(str)));
}

function sendTvText(text) {
  const trimmed = text.trim();
  if (!trimmed) return;
  haptic.playTap(350, 0.05);

  const base64Str = utf8ToBase64(trimmed);
  const timestamp = new Date().toLocaleTimeString("vi-VN", { hour12: false });
  
  // Log the exact Samsung Tizen ms.remote.control SendInputString JSON payload
  if (commandLog) {
    const entry = document.createElement("div");
    entry.className = "log-entry key";
    entry.innerHTML = `<strong>[${timestamp}] Gửi chữ (SendText):</strong> "${trimmed}"<br><code>{"method":"ms.remote.control","params":{"Cmd":"SendInputString","DataOfCode":"${base64Str}","TypeOfRemote":"SendRemoteKey"}}</code>`;
    commandLog.appendChild(entry);
    commandLog.scrollTop = commandLog.scrollHeight;
  }

  // Followed automatically by KEY_ENTER after 300ms to trigger the search on TV
  setTimeout(() => {
    logCommand("Enter / Tìm kiếm", "KEY_ENTER", "key");
  }, 300);

  if (tvTextInput) tvTextInput.value = "";
  if (clearTvTextInput) clearTvTextInput.style.display = "none";
  closeAllSheets();
}

if (tvTextInput) {
  tvTextInput.addEventListener("input", (e) => {
    if (clearTvTextInput) {
      clearTvTextInput.style.display = e.target.value.length > 0 ? "flex" : "none";
    }
  });

  tvTextInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      e.preventDefault();
      sendTvText(tvTextInput.value);
    }
  });
}

if (clearTvTextInput) {
  clearTvTextInput.addEventListener("click", () => {
    if (tvTextInput) {
      tvTextInput.value = "";
      tvTextInput.focus();
    }
    clearTvTextInput.style.display = "none";
  });
}

if (sendTvTextBtn) {
  sendTvTextBtn.addEventListener("click", () => {
    if (tvTextInput) {
      sendTvText(tvTextInput.value);
    }
  });
}

// Quick Suggestion Chips
document.querySelectorAll(".chip-btn").forEach(chip => {
  chip.addEventListener("click", () => {
    const text = chip.getAttribute("data-text");
    if (text) {
      sendTvText(text);
    }
  });
});

// Helper action buttons
if (kbBackspaceBtn) {
  kbBackspaceBtn.addEventListener("click", () => {
    haptic.playTap(260);
    if (tvTextInput && tvTextInput.value.length > 0) {
      tvTextInput.value = tvTextInput.value.slice(0, -1);
      if (clearTvTextInput) {
        clearTvTextInput.style.display = tvTextInput.value.length > 0 ? "flex" : "none";
      }
    }
    logCommand("Xóa (Backspace)", "KEY_BACK", "key");
  });
}

if (kbSpaceBtn) {
  kbSpaceBtn.addEventListener("click", () => {
    haptic.playTap(260);
    if (tvTextInput) {
      tvTextInput.value += " ";
      if (clearTvTextInput) clearTvTextInput.style.display = "flex";
    }
    const base64Space = utf8ToBase64(" ");
    if (commandLog) {
      const timestamp = new Date().toLocaleTimeString("vi-VN", { hour12: false });
      const entry = document.createElement("div");
      entry.className = "log-entry key";
      entry.innerHTML = `<strong>[${timestamp}] Phím Space:</strong> " "<br><code>{"method":"ms.remote.control","params":{"Cmd":"SendInputString","DataOfCode":"${base64Space}","TypeOfRemote":"SendRemoteKey"}}</code>`;
      commandLog.appendChild(entry);
      commandLog.scrollTop = commandLog.scrollHeight;
    }
  });
}

if (kbEnterBtn) {
  kbEnterBtn.addEventListener("click", () => {
    haptic.playTap(320);
    logCommand("Tìm (Enter)", "KEY_ENTER", "key");
    closeAllSheets();
  });
}

