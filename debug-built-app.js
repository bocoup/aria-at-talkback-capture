#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

console.log('=== Built App Debug Script ===');

// Check if we're in the built app context
const appPath = process.env.ELECTRON_IS_DEV ? 'Development' : 'Built App';
console.log('App Context:', appPath);
console.log('Current Directory:', process.cwd());
console.log('__dirname:', __dirname);

// Check for script files
const platforms = ['macos', 'linux', 'win'];
const scriptName = 'checkStatus';

platforms.forEach(platform => {
    const scriptExt = platform === 'win' ? '.ps1' : '.sh';
    const scriptPath = path.join(__dirname, platform, scriptName + scriptExt);
    
    console.log(`\nChecking ${platform}:`);
    console.log('  Script path:', scriptPath);
    console.log('  Exists:', fs.existsSync(scriptPath));
    
    if (fs.existsSync(scriptPath)) {
        console.log('  File size:', fs.statSync(scriptPath).size, 'bytes');
        console.log('  Executable:', fs.statSync(scriptPath).mode & 0o111 ? 'Yes' : 'No');
    }
});

// Test script execution
console.log('\n=== Testing Script Execution ===');

const platform = process.platform === 'win32' ? 'win' : 
                 process.platform === 'darwin' ? 'macos' : 'linux';
const scriptExt = platform === 'win' ? '.ps1' : '.sh';
const scriptPath = path.join(__dirname, platform, scriptName + scriptExt);

if (fs.existsSync(scriptPath)) {
    console.log(`Executing ${scriptPath}...`);
    
    let command, commandArgs;
    
    if (platform === 'win') {
        command = 'powershell.exe';
        commandArgs = ['-ExecutionPolicy', 'Bypass', '-File', scriptPath];
    } else {
        command = 'bash';
        commandArgs = [scriptPath];
    }
    
    const process = spawn(command, commandArgs, {
        cwd: path.join(__dirname, platform)
    });
    
    process.stdout.on('data', (data) => {
        console.log('STDOUT:', data.toString());
    });
    
    process.stderr.on('data', (data) => {
        console.error('STDERR:', data.toString());
    });
    
    process.on('close', (code) => {
        console.log(`Script exited with code: ${code}`);
    });
    
    process.on('error', (error) => {
        console.error('Script execution error:', error);
    });
} else {
    console.error(`Script not found: ${scriptPath}`);
} 