const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  // TalkBack control
  enableTalkback: () => ipcRenderer.invoke('enable-talkback'),
  disableTalkback: () => ipcRenderer.invoke('disable-talkback'),
  
  // Web page control
  openWebpage: (url) => ipcRenderer.invoke('open-webpage', url),
  
  // Capture control
  startCapture: () => ipcRenderer.invoke('start-capture'),
  stopCapture: () => ipcRenderer.invoke('stop-capture'),
  
  // System check
  checkAdb: () => ipcRenderer.invoke('check-adb'),
  
  // Event listeners for real-time capture data
  onCaptureData: (callback) => ipcRenderer.on('capture-data', callback),
  onCaptureError: (callback) => ipcRenderer.on('capture-error', callback),
  onCaptureFinished: (callback) => ipcRenderer.on('capture-finished', callback),
  
  // Remove event listeners
  removeAllListeners: (channel) => ipcRenderer.removeAllListeners(channel)
}); 