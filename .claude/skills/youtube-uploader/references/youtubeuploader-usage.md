# youtubeuploader CLI Reference

## Installation

```bash
brew install youtubeuploader
```

## Basic Upload

```bash
youtubeuploader \
  -filename "video.mp4" \
  -title "My Video Title" \
  -description "Video description" \
  -privacy "unlisted"
```

## Upload with Metadata File

```bash
youtubeuploader \
  -filename "video.mp4" \
  -metaJSON "metadata.json"
```

## Upload with Thumbnail

```bash
youtubeuploader \
  -filename "video.mp4" \
  -metaJSON "metadata.json" \
  -thumbnail "thumbnail.jpg"
```

## Common Options

| Option | Description | Example |
|--------|-------------|---------|
| `-filename` | Path to video file (required) | `-filename "video.mp4"` |
| `-metaJSON` | Path to metadata JSON file | `-metaJSON "meta.json"` |
| `-title` | Video title | `-title "My Video"` |
| `-description` | Video description | `-description "Description"` |
| `-privacy` | Privacy status | `-privacy "unlisted"` |
| `-thumbnail` | Thumbnail image path | `-thumbnail "thumb.jpg"` |
| `-tags` | Comma-separated tags | `-tags "tag1,tag2,tag3"` |
| `-categoryId` | YouTube category ID | `-categoryId 22` |
| `-secrets` | OAuth2 client secrets file | `-secrets client_secret.json` |
| `-cache` | OAuth2 token cache file | `-cache token.json` |

## Authentication Files

- **client_secret.json**: OAuth2 credentials from Google Cloud Console
- **token.json**: Cached access token (auto-generated after first auth)

Default locations:
- macOS/Linux: `~/.config/youtubeuploader/`
- Windows: `%APPDATA%\youtubeuploader\`

## Return Values

- **Success**: Prints video URL to stdout
- **Failure**: Non-zero exit code with error message to stderr

## Example Output

```
Video uploaded successfully: https://www.youtube.com/watch?v=VIDEO_ID
```

## Privacy Levels

- `public`: Anyone can search and view
- `unlisted`: Only people with the link can view
- `private`: Only you and users you choose can view

## Notes

- First run requires browser authentication
- Subsequent runs use cached token
- Video processing may take time after upload
- Maximum file size: 256 GB or 12 hours (whichever is less)
