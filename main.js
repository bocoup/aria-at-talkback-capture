const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const path = require('path');
const { spawn } = require('child_process');
const os = require('os');

let mainWindow;
let captureProcess = null;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    },
    icon: path.join(__dirname, 'assets', 'icon.png'),
    title: 'ARIA-AT TalkBack Capture'
  });

  mainWindow.loadFile('index.html');

  if (process.argv.includes('--dev')) {
    mainWindow.webContents.openDevTools();
  }
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});

// Get platform-specific script directory
function getScriptDir() {
  const platform = os.platform();
  if (platform === 'win32') return 'win';
  if (platform === 'darwin') return 'macos';
  return 'linux';
}

// Get script extension
function getScriptExt() {
  return os.platform() === 'win32' ? '.ps1' : '.sh';
}

// Execute script with real-time output
function executeScript(scriptName, args = [], onData, onError, onClose) {
  const scriptDir = getScriptDir();
  const scriptExt = getScriptExt();
  const scriptPath = path.join(__dirname, scriptDir, scriptName + scriptExt);
  
  let command, commandArgs;
  
  if (os.platform() === 'win32') {
    command = 'powershell.exe';
    commandArgs = ['-ExecutionPolicy', 'Bypass', '-File', scriptPath, ...args];
  } else {
    command = 'bash';
    commandArgs = [scriptPath, ...args];
  }

  const process = spawn(command, commandArgs, {
    cwd: path.join(__dirname, scriptDir)
  });

  process.stdout.on('data', (data) => {
    onData(data.toString());
  });

  process.stderr.on('data', (data) => {
    onError(data.toString());
  });

  process.on('close', (code) => {
    onClose(code);
  });

  return process;
}

// IPC handlers
ipcMain.handle('enable-talkback', async () => {
  return new Promise((resolve, reject) => {
    let output = '';
    let error = '';

    const process = executeScript(
      'enableTalkback',
      [],
      (data) => { output += data; },
      (data) => { error += data; },
      (code) => {
        if (code === 0) {
          resolve({ success: true, output });
        } else {
          reject({ success: false, error, output });
        }
      }
    );
  });
});

ipcMain.handle('disable-talkback', async () => {
  return new Promise((resolve, reject) => {
    let output = '';
    let error = '';

    const process = executeScript(
      'disableTalkback',
      [],
      (data) => { output += data; },
      (data) => { error += data; },
      (code) => {
        if (code === 0) {
          resolve({ success: true, output });
        } else {
          reject({ success: false, error, output });
        }
      }
    );
  });
});

ipcMain.handle('open-webpage', async (event, url) => {
  return new Promise((resolve, reject) => {
    let output = '';
    let error = '';

    const process = executeScript(
      'openWebPage',
      [url],
      (data) => { output += data; },
      (data) => { error += data; },
      (code) => {
        if (code === 0) {
          resolve({ success: true, output });
        } else {
          reject({ success: false, error, output });
        }
      }
    );
  });
});

ipcMain.handle('start-capture', async () => {
  return new Promise((resolve, reject) => {
    if (captureProcess) {
      reject({ success: false, error: 'Capture already running' });
      return;
    }

    let output = '';
    let error = '';

    captureProcess = executeScript(
      'captureUtterances',
      [],
      (data) => { 
        output += data;
        mainWindow.webContents.send('capture-data', data);
      },
      (data) => { 
        error += data;
        mainWindow.webContents.send('capture-error', data);
      },
      (code) => {
        captureProcess = null;
        mainWindow.webContents.send('capture-finished', { code, output, error });
        if (code === 0) {
          resolve({ success: true, output });
        } else {
          reject({ success: false, error, output });
        }
      }
    );

    resolve({ success: true, message: 'Capture started' });
  });
});

ipcMain.handle('stop-capture', async () => {
  if (captureProcess) {
    captureProcess.kill('SIGINT');
    captureProcess = null;
    return { success: true, message: 'Capture stopped' };
  }
  return { success: false, error: 'No capture process running' };
});

ipcMain.handle('check-adb', async () => {
  return new Promise((resolve, reject) => {
    let output = '';
    let error = '';

    const process = executeScript(
      'common',
      [],
      (data) => { output += data; },
      (data) => { error += data; },
      (code) => {
        if (code === 0) {
          resolve({ success: true, output });
        } else {
          reject({ success: false, error, output });
        }
      }
    );
  });
}); 