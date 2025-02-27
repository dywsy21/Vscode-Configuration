// Helper script to apply rainbow effect to the active line number (cursor position only)

(function() {
    // Wait for editor to initialize
    const interval = setInterval(() => {
        const editor = document.querySelector('.monaco-editor');
        if (!editor) return;
        
        // Clear interval once we've started
        clearInterval(interval);
        
        // Create our style for rainbow effect
        const style = document.createElement('style');
        style.textContent = `
            @keyframes rainbow-shift-line {
                0% { background-position: 0% 50%; }
                50% { background-position: 100% 50%; }
                100% { background-position: 0% 50%; }
            }
            
            .monaco-editor .margin-view-overlays .current-line-margin .line-numbers,
            .monaco-editor .margin-view-overlays .line-numbers.cursor-line-number {
                color: transparent !important;
                background: linear-gradient(to right,
                    #ff3333, #ffb700, #ffff33, #4dff4d, #33bbff, #bb66ff, #ff99ff, #ff3333
                ) !important;
                background-size: 200% auto !important;
                background-clip: text !important;
                -webkit-background-clip: text !important;
                -webkit-text-fill-color: transparent !important;
                animation: rainbow-shift-line 3s linear infinite !important;
                font-weight: bold !important;
                text-shadow: none !important;
            }
        `;
        document.head.appendChild(style);
        
        // Function to find current line number and add our class
        const updateLineNumbers = () => {
            try {
                // Find the current line
                const currentLine = editor.querySelector('.view-lines .view-line.focused') || 
                                    editor.querySelector('.view-lines .view-line.current-line');
                
                // Remove our class from all line numbers
                const allLineNumbers = editor.querySelectorAll('.margin-view-overlays .line-numbers');
                allLineNumbers.forEach(el => el.classList.remove('cursor-line-number'));
                
                if (currentLine) {
                    // Find the line index
                    const lines = Array.from(currentLine.parentElement.children);
                    const lineIndex = lines.indexOf(currentLine);
                    
                    // Find corresponding line number in margin
                    const marginLines = editor.querySelectorAll('.margin-view-overlays > div');
                    if (lineIndex >= 0 && lineIndex < marginLines.length) {
                        const lineNumber = marginLines[lineIndex].querySelector('.line-numbers');
                        if (lineNumber) {
                            lineNumber.classList.add('cursor-line-number');
                        }
                    }
                }
            } catch(e) {
                // Silent error handling to prevent crashes
            }
        };
        
        // Use a lighter weight observer that only looks for specific changes
        const observer = new MutationObserver(mutations => {
            let shouldUpdate = false;
            
            for (const mutation of mutations) {
                // Only process if classes changed or we found elements with our target classes
                if (mutation.type === 'attributes' && mutation.attributeName === 'class') {
                    const target = mutation.target;
                    if (target.classList.contains('current-line') || 
                        target.classList.contains('focused')) {
                        shouldUpdate = true;
                        break;
                    }
                }
            }
            
            if (shouldUpdate) {
                updateLineNumbers();
            }
        });
        
        // Start observing with a more focused configuration
        observer.observe(editor, {
            attributes: true,
            attributeFilter: ['class'],
            subtree: true
        });
        
        // Also add event listeners for cursor movement
        editor.addEventListener('click', updateLineNumbers);
        document.addEventListener('keyup', updateLineNumbers);
        
        // Run initially
        updateLineNumbers();
        
        // Periodically check as a fallback (low frequency to prevent performance issues)
        setInterval(updateLineNumbers, 500);
        
    }, 1000);
})();
