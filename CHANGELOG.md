# Midnight Routine

## [v12.0.11](https://github.com/LoyalFTW/Midnight-Routine/tree/v12.0.11) (2026-03-03)
[Full Changelog](https://github.com/LoyalFTW/Midnight-Routine/compare/v12.0.10...v12.0.11) [Previous Releases](https://github.com/LoyalFTW/Midnight-Routine/releases)

- Remove comment for resize dragger  
    Removed comment about resize dragger in UI.lua.  
- Merge pull request #1 from fostot/feature/height-option-and-resize-handle  
    Add HEIGHT option and drag-to-resize handle  
- Add HEIGHT option and drag-to-resize handle  
    - Add a HEIGHT slider to the Options panel (between WIDTH and FONT SIZE)  
      allowing users to set a fixed frame height (100-800px, step 10)  
    - Frame now uses the stored height instead of auto-sizing to content,  
      letting content scroll when it overflows  
    - Add a resize grip in the bottom-right corner of the main frame using  
      the standard WoW chat resize grabber texture  
    - Dragging the grip adjusts both width and height in real-time, and on  
      release saves the new values to the database (updating the config  
      sliders if the Options panel is open)  
    - Resize grip respects Lock Frame (disabled when locked) and hides  
      when the frame is minimized  
