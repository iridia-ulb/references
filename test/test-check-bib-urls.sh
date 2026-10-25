#!/usr/bin/env bash
# Offline self-check of URL/DOI extraction and --staged line mapping in scripts/check-bib-urls.
set -eu
script=$(cd "$(dirname "$0")/.." && pwd)/scripts/check-bib-urls
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cd "$tmp"
git init -q .
git config user.email t@example.org; git config user.name t
cat > t.bib <<'BIB'
@article{a,
  doi = {10.1000/abc_1},
  url = {https://example.org/a\_b?x=1\&y=2},
  % url = {https://example.org/commented},
  note = {See https://example.org/note.},
  howpublished = {\url{https://doi.org/10.1000/xyz}},
}
BIB
printf '*ignored.example.org*\n*10.1000/skip*\n' > ign
expected=$(printf 'doi\t10.1000/abc_1\tt.bib:2\nurl\thttps://example.org/a_b?x=1&y=2\tt.bib:3\nurl\thttps://example.org/note\tt.bib:5\ndoi\t10.1000/xyz\tt.bib:6\n')
actual=$("$script" --list --ignore ign t.bib)
[ "$actual" = "$expected" ] || { echo "FAIL extract"; echo "$actual"; exit 1; }

# ignore patterns
printf '  doi = {10.1000/skip},\n  url = {https://ignored.example.org/x},\n' >> t.bib
actual=$("$script" --list --ignore ign t.bib)
[ "$actual" = "$expected" ] || { echo "FAIL ignore"; echo "$actual"; exit 1; }

# staged: only added lines, with correct line numbers
git add t.bib; git commit -q -m init
sed -i '1a\  url = {https://new.example.org/one},' t.bib
echo '  url = {https://new.example.org/two},' >> t.bib
git add t.bib
actual=$("$script" --list --staged --ignore ign)
expected=$(printf 'url\thttps://new.example.org/one\tt.bib:2\nurl\thttps://new.example.org/two\tt.bib:11\n')
[ "$actual" = "$expected" ] || { echo "FAIL staged"; echo "$actual"; exit 1; }
echo "check-bib-urls: all tests passed"
