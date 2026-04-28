# TeamDynamix Release Notes Viewer

A web-based release notes aggregator and viewer for TeamDynamix products. Import, organize, search, and share release notes across your team with soft-delete recovery and collaborative features.

## Features

- 📥 **Multi-Format Import**: Import HTML folders (with images), PDF files, or JSON exports
- 🔍 **Smart Search**: Search across titles, descriptions, versions, and categories
- 🏷️ **Advanced Filtering**: Filter by product, version, category, and release
- 🎨 **Rich Display**: Full HTML support with images, tables, and formatting
- 🖼️ **Image Viewer**: Click images to view full-size in a modal with navigation
- ☁️ **Shared JSON**: Support for central data source with browser localStorage fallback
- 🔄 **Undo & Recovery**: Soft-delete with undo functionality to prevent data loss
- ✏️ **Manual Entries**: Add, edit, or delete release notes directly in the app
- 📊 **Product Support**: Conversational AI, Work Management, AI Service Assist, iPaaS
- 💾 **Export**: Save all release notes as JSON for backup or sharing

## Quick Start

1. Open `index.html` in your browser
2. Click **"Import HTML Folder"** to import a saved TeamDynamix release notes page with images
3. Or paste **HTML/PDF content** directly
4. Search, filter, and organize as needed
5. Export to JSON to backup or share with teammates

## Setup for Team Collaboration

### Option 1: GitHub Pages (Recommended)
1. Enable GitHub Pages in repo settings
2. Set source to `main` branch (root directory)
3. App will be live at `https://yourusername.github.io/teamdynamix-release-notes/`
4. Share this URL with your team

### Option 2: Internal Hosting
- IIS Server
- SharePoint
- Azure Static Web Apps
- Any HTTP server hosting static files

### Shared Data Source Setup
1. Export your release notes as JSON from the app
2. Host the JSON file at a stable URL (e.g., internal server, GitHub raw content)
3. Set `SHARED_DATA_URL = 'your-url-here'` in the code, or place as `./release-notes.json`
4. Users will load shared data on startup with local backup

## Switch To A New Supabase Project

When quota is exhausted on one Supabase account, you can move this app to another project quickly:

1. In the app, open **Options -> Supabase Connection**.
2. Run [supabase/new-project-setup.sql](supabase/new-project-setup.sql) in the new project's SQL editor.
3. In the app, run **Options -> Run Supabase Check** to verify tables, policies, and storage access.
4. Enter the new project URL (`https://<project-ref>.supabase.co`) and anon/publishable key.
5. In the old app/project, **Export JSON**. Then in the new project connection, **Import JSON** and save.

Tip: The app now attempts to externalize embedded `data:image/...` blobs into Supabase Storage during save, which sharply reduces database egress.

### Supabase Migration Runbook

Use this order for repeatable, low-risk cutovers:

1. **Bootstrap**
	- Run [supabase/new-project-setup.sql](supabase/new-project-setup.sql) in the target Supabase project.
2. **Connect**
	- In the app: **Options -> Supabase Connection**.
	- Enter new project URL and anon/publishable key.
3. **Import**
	- In old environment: **Export JSON**.
	- In new environment: **Import JSON** and save once.
4. **Verify (baseline)**
	- In app: **Options -> Run Supabase Check**.
	- Run read checks, then write probes.
5. **Harden**
	- Run [supabase/hardened-policies.sql](supabase/hardened-policies.sql).
6. **Verify (post-hardening)**
	- Re-run **Run Supabase Check** with write probes enabled.
7. **Operate**
	- Export a fresh backup JSON.
	- Monitor Supabase usage for 24-48 hours.

Optional: temporarily disable writes without code changes:

```sql
update public.app_config
set value = 'false'
where key = 'write_enabled';
```

Re-enable writes:

```sql
update public.app_config
set value = 'true'
where key = 'write_enabled';
```

### Supabase Check Troubleshooting

Use this quick matrix when **Options -> Run Supabase Check** reports a failure.

| Failed Check | Typical Cause | Quick Fix |
|---|---|---|
| `release_notes read` | Missing table or missing SELECT policy | Re-run [supabase/new-project-setup.sql](supabase/new-project-setup.sql), then re-run check |
| `release_notes write/delete probe` | `write_enabled` is `false` or write policies missing | Run `update public.app_config set value='true' where key='write_enabled';` then re-run [supabase/hardened-policies.sql](supabase/hardened-policies.sql) |
| `app_config read` | app_config table/policies not present | Re-run [supabase/new-project-setup.sql](supabase/new-project-setup.sql) and ensure key visibility policies exist |
| `app_config write/delete probe` | Health-check keys blocked by RLS | Re-run latest [supabase/hardened-policies.sql](supabase/hardened-policies.sql) (includes `healthcheck-%` compatibility) |
| `release-note-images bucket access` | Bucket missing or storage SELECT policy missing | Confirm bucket exists as `release-note-images`; re-run [supabase/new-project-setup.sql](supabase/new-project-setup.sql) |
| `release-note-images upload/remove probe` | INSERT/DELETE policy missing on `storage.objects` for bucket | Re-run [supabase/hardened-policies.sql](supabase/hardened-policies.sql) and verify storage policies |

If policy creation errors with "already exists", run:

```sql
rollback;
```

Then re-run the latest [supabase/hardened-policies.sql](supabase/hardened-policies.sql), which is safe to rerun.

## How to Use

### Importing Release Notes

**HTML Method** (with images):
1. Export TeamDynamix release notes as HTML
2. Save the HTML folder locally
3. Click **"+ Import HTML Folder"** from Options
4. Select the folder
5. Review and confirm import

**PDF Method**:
1. Export as single or multi-page PDF
2. Click **"+ Import PDF/Text"** from Options
3. Select the PDF file
4. Review parsed entries and confirm

**Manual Entry**:
1. Click **"+ Add Entry"** from Options
2. Fill in product, version, release date, category, title, and details
3. Save

### Searching & Filtering
- Use **Search** to find text in titles and descriptions
- **Product Filter**: Show only specific products
- **Version Filter**: Show only specific versions
- **Category Filter**: Show only specific categories (New Feature, Bug Fix, etc.)
- **Sort By**: Date, version, category, or section order

### Import Preview & Validation
When importing, you'll see:
- Auto-detected product, version, release, and date
- Option to override any field
- Per-entry Remove button to discard unwanted entries
- Validation prevents importing incomplete entries

### Browsing Images
- Click any image in release notes to view full-size
- Use **arrow buttons** or **← →** arrow keys to navigate
- Click outside image or press **Escape** to close
- Counter shows current image position

### Data Management
- **Edit**: Click "Edit" button on any entry to modify
- **Delete**: Soft-delete removes data but allows undo
- **Undo**: Yellow bar appears after delete — click "Undo" to restore
- **Clear All**: Remove all entries (with undo option)
- **Export**: Download all notes as JSON backup

## Product Detection

Automatically detects product from:
- HTML metadata (og:title, article:section, article:tag)
- File name patterns
- PDF text content

Products recognized:
- **Conversational AI** (aliases: CAI, AI & Automation)
- **Work Management** (aliases: WM)
- **AI Service Assist** (aliases: ASA)
- **iPaaS** (aliases: Integration Platform)

## Supported Categories

General, New Feature, Improvement, Enhancement, Bug Fix, Breaking Change, Administration, API, Connector, UI/UX, Performance, Security, Other

## Technical Details

- **Framework**: Vanilla JavaScript (no external dependencies)
- **Storage**: Browser localStorage + optional shared JSON
- **File Format**: Export/import as JSON
- **Image Support**: PNG, JPG, JPEG, GIF, WebP, SVG
- **PDF Parser**: Built-in PDF.js library

## File Structure

```
├── index.html           # Single-file app with all HTML, CSS, JS
├── release-notes.json   # Optional shared data file (host externally)
├── README.md           # This file
└── .gitignore          # Git ignore rules
```

## Browser Support

- Chrome/Edge (latest)
- Firefox (latest)
- Safari (latest)
- Requires modern JavaScript (ES2020+)

## License

MIT License — feel free to use, modify, and share

## Support

- Check the app's import preview for validation messages
- Use soft-delete and undo to experiment safely
- Export regularly for data backup
- Check browser console (F12) for any errors

---

**Made for TeamDynamix Release Notes Management** | Share with your team!
