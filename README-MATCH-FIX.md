The Local Game v15 match-creation fix

Both Pigeon and Nassau now have explicit Player 1 selection. Commissioner can create matches without joining the golfer roster. All selected golfers must be distinct.

Installation: Upload application files from this folder to the existing GitHub repository, commit, and wait for Netlify automatic deployment. No new Supabase SQL required for this change. Do not rerun prior upgrade SQL unless needed.

Test: As commissioner not on roster, create a Pigeon match with two different golfers, then a Nassau with four different golfers. Verify each saves and appears.

Not tested against production Supabase.
