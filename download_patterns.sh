# https://stackoverflow.com/a/52269934
git clone -n --depth=1 --filter=tree:0 https://github.com/hyphenation/tex-hyphen.git
cd tex-hyphen/
git sparse-checkout set --no-cone hyph-utf8/tex/generic/hyph-utf8/patterns/txt
git checkout

mv hyph-utf8/tex/generic/hyph-utf8/patterns/txt/* ./

# delete nested dir
find hyph-utf8/ -type d -empty -print -delete

# TODO gleam run -m hyphenation/internal/codegen
