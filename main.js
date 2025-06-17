const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const path = require('path');
const { spawn } = require('child_process');
const os = require('os');
const fs = require('fs');

let mainWindow;
let captureProcess = null;
let tempScriptDir = null;

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

  // Add keyboard shortcut to open dev tools in built version
  mainWindow.webContents.on('before-input-event', (event, input) => {
    if (input.control && input.key.toLowerCase() === 'f12') {
      mainWindow.webContents.openDevTools();
    }
  });
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

// Helper function to get the correct app path
function getAppPath() {
  try {
    const app = require('electron').app;
    console.log('App isPackaged:', app.isPackaged);
    console.log('App getAppPath():', app.getAppPath());
    console.log('__dirname:', __dirname);
    
    if (app.isPackaged) {
      // In packaged app, let's try different possible locations
      const possiblePaths = [
        app.getAppPath(),
        path.join(app.getAppPath(), 'app'),
        path.join(process.resourcesPath, 'app'),
        __dirname
      ];
      
      console.log('Possible paths:', possiblePaths);
      
      // Check which path actually contains our scripts
      const fs = require('fs');
      for (const testPath of possiblePaths) {
        const testScriptPath = path.join(testPath, 'macos', 'checkStatus.sh');
        console.log('Testing path:', testPath, 'Script exists:', fs.existsSync(testScriptPath));
        if (fs.existsSync(testScriptPath)) {
          console.log('Found scripts at:', testPath);
          return testPath;
        }
      }
      
      // If none found, return the app path
      return app.getAppPath();
    } else {
      // In development, use current directory
      return __dirname;
    }
  } catch (error) {
    console.error('Error getting app path:', error);
    // Fallback to current directory
    return __dirname;
  }
}

// Function to extract scripts from asar to temp directory
function extractScriptsToTemp() {
  if (tempScriptDir) {
    return tempScriptDir; // Already extracted
  }
  
  const app = require('electron').app;
  const platform = getScriptDir();
  
  if (!app.isPackaged) {
    // In development, use the original directory
    tempScriptDir = path.join(__dirname, platform);
    return tempScriptDir;
  }
  
  // In packaged app, extract scripts to temp directory
  const tempDir = path.join(os.tmpdir(), 'aria-at-talkback-capture');
  const platformTempDir = path.join(tempDir, platform);
  
  // Create temp directory if it doesn't exist
  if (!fs.existsSync(tempDir)) {
    fs.mkdirSync(tempDir, { recursive: true });
  }
  if (!fs.existsSync(platformTempDir)) {
    fs.mkdirSync(platformTempDir, { recursive: true });
  }
  
  // Get the asar path
  const asarPath = app.getAppPath();
  const scriptExt = getScriptExt();
  
  // List of scripts to extract
  const scripts = [
    'checkStatus' + scriptExt,
    'common' + scriptExt,
    'enableTalkback' + scriptExt,
    'disableTalkback' + scriptExt,
    'openWebPage' + scriptExt,
    'captureUtterances' + scriptExt,
    'captureLogs' + scriptExt
  ];
  
  console.log('Extracting scripts from asar to:', platformTempDir);
  
  // Extract each script
  scripts.forEach(scriptName => {
    const asarScriptPath = path.join(asarPath, platform, scriptName);
    const tempScriptPath = path.join(platformTempDir, scriptName);
    
    if (fs.existsSync(asarScriptPath)) {
      try {
        const scriptContent = fs.readFileSync(asarScriptPath, 'utf8');
        fs.writeFileSync(tempScriptPath, scriptContent);
        
        // Make executable on Unix systems
        if (os.platform() !== 'win32') {
          fs.chmodSync(tempScriptPath, 0o755);
        }
        
        console.log('Extracted:', scriptName);
      } catch (error) {
        console.error('Error extracting script:', scriptName, error);
      }
    }
  });
  
  tempScriptDir = platformTempDir;
  return tempScriptDir;
}

// Execute script with real-time output
function executeScript(scriptName, args = [], onData, onError, onClose) {
  const scriptExt = getScriptExt();
  
  // Extract scripts to temp directory and get the path
  const scriptDir = extractScriptsToTemp();
  const scriptPath = path.join(scriptDir, scriptName + scriptExt);
  
  console.log('Executing script:', scriptPath);
  console.log('Script directory:', scriptDir);
  
  let command, commandArgs;
  
  if (os.platform() === 'win32') {
    command = 'powershell.exe';
    commandArgs = ['-ExecutionPolicy', 'Bypass', '-File', scriptPath, ...args];
  } else {
    command = 'bash';
    commandArgs = [scriptPath, ...args];
  }

  console.log('Command:', command);
  console.log('Args:', commandArgs);

  const process = spawn(command, commandArgs, {
    cwd: scriptDir
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

  process.on('error', (error) => {
    console.error('Process error:', error);
    onError(`Process error: ${error.message}`);
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

    const scriptExt = getScriptExt();
    
    // Extract scripts to temp directory and get the path
    const scriptDir = extractScriptsToTemp();
    const scriptPath = path.join(scriptDir, 'checkStatus' + scriptExt);
    
    console.log('Checking system status...');
    console.log('Script directory:', scriptDir);
    console.log('Script path:', scriptPath);
    console.log('Platform:', os.platform());

    // Check if script file exists
    if (!fs.existsSync(scriptPath)) {
      const errorMsg = `Script not found: ${scriptPath}`;
      console.error(errorMsg);
      reject({ success: false, error: errorMsg, output: '' });
      return;
    }

    const process = executeScript(
      'checkStatus',
      [],
      (data) => { 
        output += data;
        console.log('Status check output:', data);
      },
      (data) => { 
        error += data;
        console.error('Status check error:', data);
      },
      (code) => {
        console.log('Status check completed with code:', code);
        console.log('Final output:', output);
        console.log('Final error:', error);
        
        if (code === 0) {
          resolve({ success: true, output });
        } else {
          reject({ success: false, error, output });
        }
      }
    );
  });
});

ipcMain.handle('debug-files', async () => {
  const basePath = getAppPath();
  
  console.log('=== Debug Files ===');
  console.log('Base path:', basePath);
  
  const result = {
    basePath,
    tempScriptDir: tempScriptDir,
    files: {}
  };
  
  // Check each platform directory in the asar
  ['macos', 'linux', 'win'].forEach(platform => {
    const platformPath = path.join(basePath, platform);
    result.files[platform] = {
      path: platformPath,
      exists: fs.existsSync(platformPath),
      contents: []
    };
    
    if (fs.existsSync(platformPath)) {
      try {
        const files = fs.readdirSync(platformPath);
        result.files[platform].contents = files;
        
        // Check specific script files
        const scriptExt = platform === 'win' ? '.ps1' : '.sh';
        const checkStatusScript = path.join(platformPath, 'checkStatus' + scriptExt);
        const commonScript = path.join(platformPath, 'common' + scriptExt);
        
        result.files[platform].checkStatusExists = fs.existsSync(checkStatusScript);
        result.files[platform].commonExists = fs.existsSync(commonScript);
        
        if (fs.existsSync(checkStatusScript)) {
          const stats = fs.statSync(checkStatusScript);
          result.files[platform].checkStatusExecutable = (stats.mode & 0o111) !== 0;
          result.files[platform].checkStatusSize = stats.size;
        }
      } catch (error) {
        result.files[platform].error = error.message;
      }
    }
  });
  
  // Also check the temp directory if it exists
  if (tempScriptDir && fs.existsSync(tempScriptDir)) {
    result.tempFiles = {
      path: tempScriptDir,
      contents: fs.readdirSync(tempScriptDir)
    };
  }
  
  console.log('Debug result:', JSON.stringify(result, null, 2));
  return result;
});

// Function to recursively list all files in a directory
function listAllFiles(dir, maxDepth = 3, currentDepth = 0) {
  const fs = require('fs');
  const result = [];
  
  if (currentDepth >= maxDepth) return result;
  
  try {
    const items = fs.readdirSync(dir);
    for (const item of items) {
      const fullPath = path.join(dir, item);
      const stat = fs.statSync(fullPath);
      
      if (stat.isDirectory()) {
        result.push(`${'  '.repeat(currentDepth)}📁 ${item}/`);
        result.push(...listAllFiles(fullPath, maxDepth, currentDepth + 1));
      } else {
        result.push(`${'  '.repeat(currentDepth)}📄 ${item}`);
      }
    }
  } catch (error) {
    result.push(`❌ Error reading ${dir}: ${error.message}`);
  }
  
  return result;
}

ipcMain.handle('list-app-files', async () => {
  const basePath = getAppPath();
  console.log('Listing files in:', basePath);
  
  const files = listAllFiles(basePath, 4);
  console.log('Files found:', files);
  
  return {
    basePath,
    files
  };
}); 