# Deployment

## Netlify

1. Push this folder to GitHub.
2. Import the GitHub repo in Netlify.
3. Use:

```text
Build command: flutter build web --release
Publish directory: build/web
```

4. If Supabase is connected, add environment variables:

```text
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
```

5. Update the build command:

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY
```

## GitHub Pages

Use this after Flutter is installed locally:

```bash
flutter build web --release --base-href /vidyaledger/
```

Then publish the `build/web` folder to the `gh-pages` branch or use a GitHub Action.
