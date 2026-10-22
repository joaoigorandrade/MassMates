#!/bin/sh
# =============================================================================
# A1 · pgTAP transcript rewriter
# =============================================================================
# Turns a pgTAP test file into a run that returns EVERY TAP line, so a failing
# assertion can be identified. See supabase/tests/README.md §7.
#
# Usage:
#   sh supabase/tests/tap_transcript.sh \
#      supabase/tests/<agent_id>/<topic>.sql \
#      /tmp/<topic>_transcript.sql
#
# Then run the transformed file exactly like the original (one execute_sql
# query) — it returns one row per assertion:
#   {"n":42,"line":"ok 42 - is_group_member: admin is a member"}
#   {"n":43,"line":"not ok 43 - ...\n#       have: ...\n#       want: ..."}
# =============================================================================
set -e

in="$1"
out="$2"

if [ -z "$in" ] || [ -z "$out" ]; then
  echo "usage: $0 <input.sql> <output.sql>" >&2
  exit 2
fi

awk '
  /^set local search_path/ {
    print
    print "create temporary table tap_log (n serial primary key, line text) on commit drop;"
    print "grant insert, select on tap_log to authenticated, anon;"
    print "grant usage, select on all sequences in schema pg_temp to authenticated, anon;"
    next
  }
  /^select public\.pgtap_summary \(\) as result;$/ {
    print "select n, line from tap_log order by n;"
    next
  }
  {
    line = $0
    if (line ~ /^select (ok|has_extension|has_enum|has_table|has_column|has_function|has_trigger|is|isnt|throws_ok|lives_ok|enum_has_labels|results_eq) \(/) {
      sub(/^select /, "insert into tap_log (line) select ", line)
    }
    print line
  }
' "$in" > "$out"

echo "wrote $out"
