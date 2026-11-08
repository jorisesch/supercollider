"""Package the Infinite DJ web player, browser runtime, and synthesis source."""
import argparse
import hashlib
import html
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / 'site'
DJ = Path('infinite/experiments/dj')
DJ_SOURCES = (
    'engine.scd',
    'library.scd',
    'style.scd',
    'pop-style.scd',
    'e-style.scd',
    'modes.scd',
    'variety.scd',
    'rock-style.scd',
    'rock-expression.scd',
    'rock-players.scd',
    'rock-physical-style.scd',
    'instruments.scd',
    'palette-instruments.scd',
    'pop-instruments.scd',
    'e-instruments.scd',
    'rock-instruments.scd',
    'rock-expressive-instruments.scd',
    'rock-circuits.scd',
    'rock-physical-instruments.scd',
    'guitar-pickups/model.scd',
)
RUNTIME_FILES = ('sclang.js', 'sclang.data', 'sclang.wasm', 'scsynth.js', 'scsynth.wasm')


def copy_file(source, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)


def build_site(output, repository_url):
    runtime = SITE / 'runtime'
    checksums = {}
    for line in (runtime / 'SHA256SUMS').read_text(encoding='ascii').splitlines():
        digest, name = line.split()
        checksums[name] = digest
    for name in RUNTIME_FILES:
        if hashlib.sha256((runtime / name).read_bytes()).hexdigest() != checksums[name]:
            raise SystemExit(f'SuperCollider runtime checksum mismatch: {name}')

    for name in ('index.html', 'style.css', 'app.js', 'isolation-sw.js'):
        copy_file(SITE / name, output / name)
    for name in (*RUNTIME_FILES, 'COPYING', 'LICENSE', 'SOURCE.txt', 'SHA256SUMS'):
        copy_file(runtime / name, output / 'runtime' / name)
    copy_file(ROOT / 'docs/images/infinite-dj-banner.webp', output / 'assets/infinite-dj-banner.webp')

    # Select only synthesis code. Local recipes, feedback, and desktop UI are never packaged.
    sources = [DJ / name for name in DJ_SOURCES]
    sources.extend((Path('infinite/infinite-engine.scd'), Path('infinite/infinite-instruments.scd')))
    for source in sources:
        copy_file(ROOT / source, output / 'dj' / source)
    entry = DJ / 'dj.scd'
    copy_file(SITE / 'dj.scd', output / 'dj' / entry)
    manifest = {
        'files': [path.as_posix() for path in sources],
        'entry': entry.as_posix(),
        'sources': {path.as_posix(): (output / 'dj' / path).read_bytes().decode('utf-8')
                    for path in [*sources, entry]},
    }
    bundle = (json.dumps(manifest, indent=2) + '\n').encode('utf-8')
    (output / 'dj/manifest.json').write_bytes(bundle)

    index = output / 'index.html'
    version = hashlib.sha256(
        (SITE / 'app.js').read_bytes() + (SITE / 'style.css').read_bytes() + bundle
    ).hexdigest()[:12]
    page = index.read_text(encoding='utf-8')
    page = page.replace('src="app.js"', f'src="app.js?v={version}"')
    page = page.replace('href="style.css"', f'href="style.css?v={version}"')
    if repository_url:
        url = html.escape(repository_url.rstrip('/'), quote=True)
        page = page.replace('<head>', f'<head>\n  <meta name="repository-url" content="{url}">', 1)
    index.write_text(page, encoding='utf-8')
    (output / '.nojekyll').touch()
    print(f'Static page built: {output}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / '_site')
    parser.add_argument('--repository-url', default='')
    args = parser.parse_args()
    build_site(args.output.resolve(), args.repository_url)
