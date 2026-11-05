# The Local Game — complete root-level GitHub upload

## Deploy
1. Unzip the package. Upload **all files inside**, not the enclosing directory, to the root of the existing GitHub repository.
2. Existing files with the same names must be replaced. GitHub's browser uploader may not replace them automatically: edit existing files using the pencil editor, or use GitHub Desktop to copy the package files into the checked-out repository, commit and push.
3. Netlify builds automatically from main. Base directory blank, build command `npm run build`, publish directory `dist`.
4. Keep existing `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` settings. No database migration is required for the press settings because they are stored in round JSON.

## Rules
Pigeon: 1v1 net Nassau with separate front/back/overall units and optional presses at two holes down. Canyon: two-person teams, low net and high net each worth a point per hole; presses available when a team is two points down in a parent unit. Presses start at the next hole and run to the end of that unit. Each press pays the normal Nassau unit amount. The sweep applies only to the original front/back/overall units.

## Caution
This is a prototype. The project was not production-build verified in this environment because dependencies were not installed. Supabase policies from the original prototype are not production secure. Verify all course tee data, hole stroke indexes, and handicap allowances before relying on financial settlements.
