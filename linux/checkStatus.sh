#!/bin/sh

SCRIPT_DIR="$(dirname "$0")"

# Source the common functions
. "$SCRIPT_DIR/common.sh"

echo "=== System Status Check ==="

# Check if adb is available
echo "Checking ADB availability..."
if find_adb; then
    echo "✅ ADB found at: $ADB_LOCATION"
    
    # Check if device is connected
    echo "Checking device connection..."
    if $ADB_LOCATION devices | grep -q "device$"; then
        echo "✅ Device connected"
        
        # Check developer mode
        echo "Checking developer mode..."
        if check_developer_mode; then
            echo "✅ Developer mode enabled"
            
            # Check TalkBack installation
            echo "Checking TalkBack installation..."
            if check_talkback_installed; then
                echo "✅ TalkBack is installed"
                
                # Check TalkBack status
                echo "Checking TalkBack status..."
                if check_talkback_enabled; then
                    echo "✅ TalkBack is enabled"
                else
                    echo "⚠️  TalkBack is not enabled"
                fi
            else
                echo "❌ TalkBack is not installed"
            fi
        else
            echo "❌ Developer mode not enabled"
        fi
    else
        echo "❌ No device connected"
    fi
else
    echo "❌ ADB not found"
fi

echo "=== Status Check Complete ===" 