from lxml import html
from collections import Counter
from typing import List, TypedDict


class PathFrequency(TypedDict):
    path: str
    frequency: int


def parse_html_to_tree(html_string: str) -> html.HtmlElement:
    """
    Returns a hierarchical tree structure parsed from HTML_STRING.

    >>> root = parse_html_to_tree("<div><p>Test</p></div>")
    >>> html.tostring(root)
    b'<div><p>Test</p></div>'
    >>> print(root.tag)
    div
    >>> print(root[0].tag)
    p

    >>> root = parse_html_to_tree("<p>Hi")
    >>> html.tostring(root)
    b'<p>Hi</p>'
    """
    return html.fromstring(html_string)


def get_path_frequencies(root: html.HtmlElement) -> List[PathFrequency]:
    """
    Traverses the tree and returns root-to-node paths with occurrence
    frequencies, sorted descending by frequency.
    Paths include all tags from root to each node, e.g. 'html/body/div/p'.
    These paths can be used with root.xpath() by prefixing '//',
    e.g. root.xpath(f"//{entry['path']}").

    >>> root = html.fromstring("<div><span>A</span><span>B</span></div>")
    >>> freqs = get_path_frequencies(root)
    >>> len(freqs)
    2
    >>> freqs
    [{'path': 'div/span', 'frequency': 2}, {'path': 'div', 'frequency': 1}]
    >>> freqs[0]['path']
    'div/span'
    >>> freqs[0]['frequency']
    2
    >>> len(root.xpath(f"//{freqs[0]['path']}"))
    2
    """
    path_counts: Counter[str] = Counter()

    # Traverse document and accumulate in path_counts.
    def _traverse(node: html.HtmlElement, current_path: str) -> None:
        path = f"{current_path}/{str(node.tag)}" if current_path else str(node.tag)
        path_counts[path] += 1
        for child in node:
            _traverse(child, path)

    _traverse(root, "")

    result: List[PathFrequency] = [
        {"path": path, "frequency": count} for path, count in path_counts.items()
    ]
    result.sort(key=lambda x: x["frequency"], reverse=True)
    return result
