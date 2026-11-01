"""Package the buildless companion page and its selected public media."""
import argparse
import html
import shutil
from pathlib import Path

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path, default=root / '_site')
parser.add_argument('--repository-url', default='')
args = parser.parse_args()
output = args.output.resolve()
output.mkdir(parents=True, exist_ok=True)
for name in ('index.html', 'style.css', 'app.js'):
    shutil.copyfile(root / 'site' / name, output / name)
for folder, files in {
    'assets': ('infinite-dj-banner.png', 'infinite-dj-controls.png'),
    'audio': ('edm-e-set.m4a', 'dj-pop-preview.m4a', 'infinite-soundscape.m4a'),
}.items():
    (output / folder).mkdir(exist_ok=True)
    for name in files:
        source = root / ('docs/images' if folder == 'assets' else 'audio') / name
        shutil.copyfile(source, output / folder / name)
if args.repository_url:
    index = output / 'index.html'
    index.write_text(index.read_text().replace('<head>', '<head>\n  <meta name="repository-url" content="'
        + html.escape(args.repository_url.rstrip('/'), quote=True) + '">', 1))
(output / '.nojekyll').touch()
print(f'Static page built: {output}')
