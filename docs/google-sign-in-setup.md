# Google sign-in setup

The Flutter button uses Supabase OAuth. It does not contain a Google Client
Secret, and it should never do so.

## Configure Google Cloud

1. Create an OAuth **Web application** client in Google Cloud.
2. Add the local origin you run during development, for example
   `http://localhost:51170`, under **Authorized JavaScript origins**. Add the
   deployed web origin for production.
3. In **Authorized redirect URIs**, add the callback URL displayed by
   **Supabase Dashboard → Authentication → Providers → Google**. This is the
   Supabase callback URL, not the Flutter localhost URL.

## Configure Supabase

1. In **Authentication → Providers → Google**, enable Google and paste the
   Google OAuth Client ID and Client Secret there.
2. In **Authentication → URL Configuration**, add each exact Flutter web URL
   to the Redirect URL allow list, for example `http://localhost:51170/**` and
   your production URL.
3. Keep only `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` in the ignored
   `.env` file. Do not add the Google Client Secret or a Supabase service-role
   key to Flutter, Git, or a browser environment.

When the button is clicked in Flutter web, Supabase redirects the browser to
Google and restores the session when the browser comes back. The app now reads
that restored session and opens `/home` automatically.
