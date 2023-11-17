# Watermark on Video

## Challenging parts
- Adding a Watermark Layer in Playback: Adjusting for video orientation (portrait or landscape) to correctly place the watermark.
- Video Export Issues: Transforming portrait videos that were automatically saved as landscape, ensuring correct export functionality.

## Module Implementation:
- ViewModel Module: Contains the logic for the user interface.
- Core Module: Hosts my services, forming the backbone of the application.
- Shared Module: Features a beautifully crafted console logger. This logger is type-safe and provides insightful logging throughout the codebase.
## Utilization of Swinject: 
- For dependency injection, I have employed Swinject, which has streamlined the process of managing dependencies within the app.
## Demo App Features:
- First Screen: Allows users to set the rotation count and select a video.
- Second Screen: Offers watermark selection, play/pause, and seek functionalities with a moving watermark demonstration.
- Export Functionality: Includes an export button that saves videos in mp4 format, with potential adaptation for .mov format.

<img width="934" alt="image" src="https://github.com/johnharutyunyan/WatermarkForRenderForest/assets/26871856/ce007a85-3f10-4122-9870-3f19350802d1">

