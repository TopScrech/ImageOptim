#!/usr/bin/env python3
"""Compare bundled CLI tool versions with upstream stable releases/tags

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


MANIFEST = json.loads((ROOT / 'Tools/versions.json').read_text())


def source_revision(name):
    return next(tool['revision'] for tool in MANIFEST if tool['tool'] == name)


TOOLS = [
    (tool['tool'], lambda tool=tool: tool['version'],
     {'pngout_latest': pngout_latest, 'pngcrush_latest': pngcrush_latest}.get(tool['upstream'], tool['upstream']),
     tool['tool'] if tool.get('revision') else None)
    for tool in MANIFEST
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
        print(f"{'Tool':<21} {'Bundled':<15} {'Latest stable':<15} Status")
        for item in results:
            print(f"{item['tool']:<21} {item['current'] or '?':<15} {item['latest'] or '?':<15} {item['status']}")
            if 'error' in item:
                print(f"  {item['error']}")
            if 'revision' in item:
                print(f"  Source revision: {item['revision']}")
        print('\nCompared the bundled tool manifest with stable upstream tags')
        print('Matching base versions may still contain fork-specific patches')
    if any(item['status'] == 'error' for item in results):
        return 2
    return int(args.check and any(item['status'] == 'outdated' for item in results))


if __name__ == '__main__':
    sys.exit(main())
