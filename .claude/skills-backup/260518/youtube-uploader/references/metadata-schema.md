# YouTube Video Metadata Schema

## Complete Metadata Structure

```json
{
  "title": "string (required, max 100 chars)",
  "description": "string (optional, max 5000 chars)",
  "tags": ["array", "of", "strings"],
  "categoryId": "number (default: 22 for People & Blogs)",
  "privacyStatus": "public|unlisted|private (default: public)",
  "thumbnail": "path/to/thumbnail.jpg (optional)",
  "language": "ko (default)",
  "defaultLanguage": "ko (default)",
  "recordingDate": "YYYY-MM-DD (optional)",
  "location": {
    "latitude": "number (optional)",
    "longitude": "number (optional)",
    "description": "string (optional)"
  },
  "madeForKids": false,
  "embeddable": true,
  "publicStatsViewable": true,
  "publishAt": "YYYY-MM-DDTHH:MM:SS.000Z (optional, for scheduled uploads)"
}
```

## Minimal Example

```json
{
  "title": "My Video Title",
  "description": "This is my video description",
  "privacyStatus": "unlisted"
}
```

## Field Descriptions

- **title**: Video title (required, max 100 characters)
- **description**: Video description (optional, max 5000 characters)
- **tags**: Array of search keywords (max 500 characters total)
- **categoryId**: YouTube category (22 = People & Blogs)
- **privacyStatus**: public, unlisted, or private
- **thumbnail**: Path to custom thumbnail image
- **language**: Video language code (ISO 639-1)
- **recordingDate**: When the video was recorded
- **madeForKids**: COPPA compliance flag
- **publishAt**: Schedule future publication (ISO 8601 format)
