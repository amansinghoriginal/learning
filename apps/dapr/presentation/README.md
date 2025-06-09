# Drasi + Dapr Presentation

This is a reveal.js presentation demonstrating how Drasi enhances Dapr microservices with intelligent change detection capabilities.

## Quick Start

### Option 1: Open Directly
Simply open `index.html` in your web browser.

### Option 2: Serve Locally
If you prefer to serve it locally (recommended for better performance):

```bash
# Using Python 3
python3 -m http.server 8000

# Using Node.js
npx http-server -p 8000

# Using any other static file server
# Then navigate to http://localhost:8000
```

## Presentation Structure

The presentation is divided into 4 main sections:

1. **Introduction** - What is Drasi and why Dapr users need it
2. **SignalR Demo** - Real-time dashboard without polling
3. **State Store Sync Demo** - Pre-computed read models for performance
4. **Pub/Sub Demo** - Business event generation from data changes

## Features

- **Mermaid Diagrams**: Interactive diagrams showing data flow
- **Syntax Highlighting**: Code examples with proper highlighting
- **Responsive Design**: Works on different screen sizes
- **Logo Integration**: CNCF and Drasi logos included
- **Custom Styling**: Dapr blue and Drasi green color scheme

## Navigation

- Use arrow keys to navigate
- Press `ESC` to see all slides
- Press `S` for speaker notes (if available)
- Press `F` for fullscreen

## Customization

To modify the presentation:

1. Edit `index.html`
2. Add/remove slides within `<section>` tags
3. Update styling in the `<style>` section
4. Replace logos in the `images/` directory if needed

## Dependencies

The presentation uses CDN-hosted versions of:
- Reveal.js 4.5.0
- Mermaid 10 for diagrams
- Highlight.js for code syntax

No installation required - everything loads from CDN!