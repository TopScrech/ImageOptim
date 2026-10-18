#!/usr/bin/env python3
"""Compare checked-out tool sources with upstream stable releases/tags

Requires Python 3.9+ and curl, does not modify dependencies
Exit codes: 0 success, 1 outdated with --check, 2 incomplete audit
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent


def read_version(path, pattern):
    match = re.search(pattern, (ROOT / path).read_text(), re.MULTILINE)
    if not match:
        raise ValueError(f"Version missing in {path}")
    return match.group(1)


def cargo_version(path):
    # Only inspect the package section, not dependency versions
    text = (ROOT / path).read_text().split('[package]', 1)[1].split('\n[', 1)[0]
    return re.search(r'^version\s*=\s*"([^"]+)"', text, re.MULTILINE).group(1)


def fetch(url):
    # curl uses the system certificate configuration on macOS
    return subprocess.check_output(
        ['curl', '--fail', '--silent', '--show-error', '--location',
         '--max-time', '30', '--retry', '2', '--user-agent', 'ImageOptim-version-audit', url],
        text=True, stderr=subprocess.PIPE,
    )


def version_key(value):
    parts = tuple(int(part) for part in value.split('.'))
    return parts + (0,) * max(0, 4 - len(parts))


def github_latest(repo):
    # Tags cover projects that do not publish GitHub Releases (e.g. MozJPEG)
    tags = json.loads(fetch(f'https://api.github.com/repos/{repo}/tags?per_page=100'))
    candidates = []
    for tag in tags:
        match = re.fullmatch(r'(?:v|zopfli-|RELEASE\.)?(\d+\.\d+(?:\.\d+)*)', tag['name'])
        if match:
            candidates.append((match[1], tag['name']))
    if not candidates:
        raise ValueError(f'No stable version tags found for {repo}')
    version, tag = max(candidates, key=lambda item: version_key(item[0]))
    return version, f'https://github.com/{repo}/releases/tag/{tag}'


def pngcrush_latest():
    url = 'https://sourceforge.net/projects/pmt/files/pngcrush/'
    versions = re.findall(r'/pngcrush/(\d+\.\d+\.\d+)/', fetch(url))
    if not versions:
        raise ValueError('No PNGCrush releases found')
    return max(versions, key=version_key), url


def pngout_latest():
    url = 'https://www.jonof.id.au/kenutils.html'
    dates = re.findall(r'pngout-(\d{8})-mac\.zip', fetch(url))
    if not dates:
        raise ValueError('No macOS PNGOUT release found')
    return max(dates), url


def zopfli_version():
    return '.'.join(read_version('zopfli-png/zopfli/CMakeLists.txt',
        rf'set\(ZOPFLI_VERSION_{part} (\d+)\)') for part in ('MAJOR', 'MINOR', 'PATCH'))


def svgo_version():
    lock = json.loads((ROOT / 'svgo/package-lock.json').read_text())
    return lock['packages']['node_modules/svgo']['version']


def source_revision(path):
    return subprocess.check_output(['git', '-C', str(ROOT / path), 'describe',
        '--tags', '--always'], text=True, stderr=subprocess.DEVNULL).strip()


TOOLS = [
    ('pngquant', lambda: cargo_version('pngquant/src/Cargo.toml'), 'kornelski/pngquant', 'pngquant/src'),
    ('OxiPNG', lambda: cargo_version('oxipng/oxipng/Cargo.toml'), 'oxipng/oxipng', 'oxipng/oxipng'),
    ('JPEGOptim', lambda: read_version('jpegoptim/src/jpegoptim.c', r'^#define VERSION "([^"]+)"'), 'tjko/jpegoptim', 'jpegoptim/src'),
    ('Gifsicle', lambda: read_version('gifsicle/orig/configure.ac', r'AC_INIT\(\[gifsicle\],\s*\[([^]]+)\]'), 'kohler/gifsicle', 'gifsicle/orig'),
    ('PNGCrush', lambda: read_version('pngcrush/Makefile', r'^VERSION\s*=\s*(\S+)'), pngcrush_latest, None),
    ('AdvPNG', lambda: read_version('advpng/Makefile', r'^VERSION\s*=\s*(\S+)'), 'amadvance/advancecomp', None),
    ('SVGO', svgo_version, 'svg/svgo', None),
    ('jpegtran / MozJPEG', lambda: read_version('libjpeg/src/CMakeLists.txt', r'set\(VERSION ([\d.]+)\)'), 'mozilla/mozjpeg', 'libjpeg/src'),
    ('ZopfliPNG', zopfli_version, 'google/zopfli', 'zopfli-png/zopfli'),
    # Guetzli has no source version constant; its nearest release tag is the base
    ('Guetzli', lambda: re.match(r'v?([\d.]+)', source_revision('guetzli/guetzli')).group(1), 'google/guetzli', 'guetzli/guetzli'),
    ('svgcleaner', lambda: cargo_version('svgcleaner/src/Cargo.toml'), 'RazrFalcon/svgcleaner', 'svgcleaner/src'),
    ('PNGOUT (macOS)', lambda: read_version('imageoptim/Makefile', r'pngout-(\d{8})-mac'), pngout_latest, None),
]


def inspect(tool):
    name, local, upstream, path = tool
    result = {'tool': name, 'current': None, 'latest': None, 'status': 'error'}
    try:
        result['current'] = local()
        if path:
            result['revision'] = source_revision(path)
        latest, url = github_latest(upstream) if isinstance(upstream, str) else upstream()
        result.update(latest=latest, url=url)
        current_key, latest_key = version_key(result['current']), version_key(latest)
        result['status'] = ('outdated' if current_key < latest_key else
                            'ahead / development' if current_key > latest_key else 'current base')
    except (OSError, ValueError, KeyError, IndexError, AttributeError, subprocess.SubprocessError) as error:
        result['error'] = (error.stderr.strip() if isinstance(error, subprocess.CalledProcessError)
                           and error.stderr else str(error))
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--json', action='store_true', help='Print machine-readable results')
    parser.add_argument('--check', action='store_true', help='Exit 1 if any dependency is outdated')
    args = parser.parse_args()
    with ThreadPoolExecutor(max_workers=6) as executor:
        results = list(executor.map(inspect, TOOLS))
    if args.json:
        print(json.dumps({'checked_at': datetime.now(timezone.utc).isoformat(), 'tools': results}, indent=2))
    else:
        print(f"{'Tool':<21} {'Local source':<15} {'Latest stable':<15} Status")
        for item in results:
            print(f"{item['tool']:<21} {item['current'] or '?':<15} {item['latest'] or '?':<15} {item['status']}")
            if 'error' in item:
                print(f"  {item['error']}")
            if 'revision' in item:
                print(f"  Checkout: {item['revision']}")
        print('\nCompared source versions and stable upstream tags, not built app binaries')
        print('Matching base versions may still contain fork-specific patches')
    if any(item['status'] == 'error' for item in results):
        return 2
    return int(args.check and any(item['status'] == 'outdated' for item in results))


if __name__ == '__main__':
    sys.exit(main())
