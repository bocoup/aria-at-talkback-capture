// DOM elements
const adbStatus = document.getElementById('adb-status');
const deviceStatus = document.getElementById('device-status');
const talkbackStatus = document.getElementById('talkback-status');
const refreshStatusBtn = document.getElementById('refresh-status');
const enableTalkbackBtn = document.getElementById('enable-talkback');
const disableTalkbackBtn = document.getElementById('disable-talkback');
const urlInput = document.getElementById('url-input');
const openWebpageBtn = document.getElementById('open-webpage');
const startCaptureBtn = document.getElementById('start-capture');
const stopCaptureBtn = document.getElementById('stop-capture');
const clearOutputBtn = document.getElementById('clear-output');
const captureStatus = document.getElementById('capture-status');
const captureOutput = document.getElementById('capture-output');
const copyOutputBtn = document.getElementById('copy-output');
const saveOutputBtn = document.getElementById('save-output');
const statusMessages = document.getElementById('status-messages');

// State
let isCapturing = false;
let capturedText = '';

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    checkSystemStatus();
    setupEventListeners();
    setupCaptureListeners();
});

// Event listeners
function setupEventListeners() {
    refreshStatusBtn.addEventListener('click', checkSystemStatus);
    enableTalkbackBtn.addEventListener('click', enableTalkback);
    disableTalkbackBtn.addEventListener('click', disableTalkback);
    openWebpageBtn.addEventListener('click', openWebpage);
    startCaptureBtn.addEventListener('click', startCapture);
    stopCaptureBtn.addEventListener('click', stopCapture);
    clearOutputBtn.addEventListener('click', clearOutput);
    copyOutputBtn.addEventListener('click', copyOutput);
    saveOutputBtn.addEventListener('click', saveOutput);
    
    // Enter key in URL input
    urlInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            openWebpage();
        }
    });
}

// Setup capture event listeners
function setupCaptureListeners() {
    window.electronAPI.onCaptureData((event, data) => {
        appendToOutput(data);
        capturedText += data;
    });
    
    window.electronAPI.onCaptureError((event, error) => {
        appendToOutput(`ERROR: ${error}`, 'error');
    });
    
    window.electronAPI.onCaptureFinished((event, result) => {
        isCapturing = false;
        updateCaptureUI();
        showStatusMessage('Capture finished', 'info');
    });
}

// System status check
async function checkSystemStatus() {
    try {
        setStatusIndicator(adbStatus, 'Checking...', 'info');
        setStatusIndicator(deviceStatus, 'Checking...', 'info');
        setStatusIndicator(talkbackStatus, 'Checking...', 'info');
        
        const result = await window.electronAPI.checkAdb();
        
        if (result.success) {
            setStatusIndicator(adbStatus, 'Connected', 'success');
            setStatusIndicator(deviceStatus, 'Connected', 'success');
            setStatusIndicator(talkbackStatus, 'Unknown', 'warning');
        } else {
            setStatusIndicator(adbStatus, 'Not Found', 'error');
            setStatusIndicator(deviceStatus, 'Not Connected', 'error');
            setStatusIndicator(talkbackStatus, 'Unknown', 'error');
        }
    } catch (error) {
        setStatusIndicator(adbStatus, 'Error', 'error');
        setStatusIndicator(deviceStatus, 'Error', 'error');
        setStatusIndicator(talkbackStatus, 'Error', 'error');
        showStatusMessage('Failed to check system status', 'error');
    }
}

// TalkBack control
async function enableTalkback() {
    try {
        enableTalkbackBtn.disabled = true;
        showStatusMessage('Enabling TalkBack...', 'info');
        
        const result = await window.electronAPI.enableTalkback();
        
        if (result.success) {
            showStatusMessage('TalkBack enabled successfully', 'success');
            setStatusIndicator(talkbackStatus, 'Enabled', 'success');
        } else {
            showStatusMessage('Failed to enable TalkBack', 'error');
        }
    } catch (error) {
        showStatusMessage('Error enabling TalkBack', 'error');
    } finally {
        enableTalkbackBtn.disabled = false;
    }
}

async function disableTalkback() {
    try {
        disableTalkbackBtn.disabled = true;
        showStatusMessage('Disabling TalkBack...', 'info');
        
        const result = await window.electronAPI.disableTalkback();
        
        if (result.success) {
            showStatusMessage('TalkBack disabled successfully', 'success');
            setStatusIndicator(talkbackStatus, 'Disabled', 'warning');
        } else {
            showStatusMessage('Failed to disable TalkBack', 'error');
        }
    } catch (error) {
        showStatusMessage('Error disabling TalkBack', 'error');
    } finally {
        disableTalkbackBtn.disabled = false;
    }
}

// Web page control
async function openWebpage() {
    const url = urlInput.value.trim();
    
    if (!url) {
        showStatusMessage('Please enter a URL', 'warning');
        urlInput.focus();
        return;
    }
    
    if (!isValidUrl(url)) {
        showStatusMessage('Please enter a valid URL', 'warning');
        urlInput.focus();
        return;
    }
    
    try {
        openWebpageBtn.disabled = true;
        showStatusMessage('Opening webpage...', 'info');
        
        const result = await window.electronAPI.openWebpage(url);
        
        if (result.success) {
            showStatusMessage('Webpage opened successfully', 'success');
        } else {
            showStatusMessage('Failed to open webpage', 'error');
        }
    } catch (error) {
        showStatusMessage('Error opening webpage', 'error');
    } finally {
        openWebpageBtn.disabled = false;
    }
}

// Capture control
async function startCapture() {
    try {
        startCaptureBtn.disabled = true;
        showStatusMessage('Starting capture...', 'info');
        
        const result = await window.electronAPI.startCapture();
        
        if (result.success) {
            isCapturing = true;
            updateCaptureUI();
            showStatusMessage('Capture started', 'success');
            appendToOutput('=== Capture Started ===\n', 'info');
        } else {
            showStatusMessage('Failed to start capture', 'error');
        }
    } catch (error) {
        showStatusMessage('Error starting capture', 'error');
    } finally {
        startCaptureBtn.disabled = false;
    }
}

async function stopCapture() {
    try {
        stopCaptureBtn.disabled = true;
        showStatusMessage('Stopping capture...', 'info');
        
        const result = await window.electronAPI.stopCapture();
        
        if (result.success) {
            isCapturing = false;
            updateCaptureUI();
            showStatusMessage('Capture stopped', 'success');
            appendToOutput('=== Capture Stopped ===\n', 'info');
        } else {
            showStatusMessage('Failed to stop capture', 'error');
        }
    } catch (error) {
        showStatusMessage('Error stopping capture', 'error');
    } finally {
        stopCaptureBtn.disabled = false;
    }
}

function clearOutput() {
    captureOutput.textContent = '';
    capturedText = '';
    showStatusMessage('Output cleared', 'info');
}

async function copyOutput() {
    if (!capturedText.trim()) {
        showStatusMessage('No text to copy', 'warning');
        return;
    }
    
    try {
        await navigator.clipboard.writeText(capturedText);
        showStatusMessage('Text copied to clipboard', 'success');
    } catch (error) {
        showStatusMessage('Failed to copy text', 'error');
    }
}

async function saveOutput() {
    if (!capturedText.trim()) {
        showStatusMessage('No text to save', 'warning');
        return;
    }
    
    try {
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const filename = `talkback-capture-${timestamp}.txt`;
        
        const blob = new Blob([capturedText], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        
        showStatusMessage('File saved successfully', 'success');
    } catch (error) {
        showStatusMessage('Failed to save file', 'error');
    }
}

// Utility functions
function updateCaptureUI() {
    if (isCapturing) {
        startCaptureBtn.disabled = true;
        stopCaptureBtn.disabled = false;
        captureStatus.textContent = 'Capturing...';
        captureStatus.className = 'status-indicator success';
    } else {
        startCaptureBtn.disabled = false;
        stopCaptureBtn.disabled = true;
        captureStatus.textContent = 'Ready';
        captureStatus.className = 'status-indicator info';
    }
}

function appendToOutput(text, type = 'normal') {
    const timestamp = new Date().toLocaleTimeString();
    let formattedText = '';
    
    switch (type) {
        case 'error':
            formattedText = `[${timestamp}] ERROR: ${text}`;
            break;
        case 'info':
            formattedText = `[${timestamp}] INFO: ${text}`;
            break;
        default:
            formattedText = text;
    }
    
    captureOutput.textContent += formattedText;
    captureOutput.scrollTop = captureOutput.scrollHeight;
}

function setStatusIndicator(element, text, type) {
    element.textContent = text;
    element.className = `status-indicator ${type}`;
}

function showStatusMessage(message, type = 'info') {
    const messageElement = document.createElement('div');
    messageElement.className = `status-message ${type}`;
    messageElement.textContent = message;
    
    statusMessages.appendChild(messageElement);
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
        if (messageElement.parentNode) {
            messageElement.parentNode.removeChild(messageElement);
        }
    }, 5000);
}

function isValidUrl(string) {
    try {
        new URL(string);
        return true;
    } catch (_) {
        return false;
    }
}

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
    window.electronAPI.removeAllListeners('capture-data');
    window.electronAPI.removeAllListeners('capture-error');
    window.electronAPI.removeAllListeners('capture-finished');
}); 