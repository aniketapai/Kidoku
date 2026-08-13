"""Small caching HTTP fetch helper so re-running the pipeline during
development doesn't re-download JMdict (~11MB compressed) or re-scrape
Aozora Bunko on every invocation.
"""

from pathlib import Path

import requests

_TIMEOUT = 30
_USER_AGENT = "yomu-ingestion/1 (+https://github.com/; contact via app store listing)"


def fetch_cached(url: str, cache_path: Path) -> bytes:
    cache_path.parent.mkdir(parents=True, exist_ok=True)
    if cache_path.exists():
        return cache_path.read_bytes()

    response = requests.get(url, timeout=_TIMEOUT, headers={"User-Agent": _USER_AGENT})
    response.raise_for_status()
    cache_path.write_bytes(response.content)
    return response.content
