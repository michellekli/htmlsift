from lxml import html, etree
from typing import List, TypedDict


class PathData(TypedDict):
    frequency: int
    first_text: str | None
    links: List[str]


class PathFrequency(TypedDict):
    path: str
    frequency: int
    first_text: str | None
    links: List[str]


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

    >>> root2 = parse_html_to_tree("<p>Hi")
    >>> html.tostring(root2)
    b'<p>Hi</p>'
    """
    return html.fromstring(html_string)


def get_path_stats(root: html.HtmlElement) -> List[PathFrequency]:
    """
    Traverses the tree and returns root-to-node paths with occurrence
    frequencies, sorted descending by frequency.
    Paths include all tags from root to each node, e.g. 'html/body/div/p'.
    These paths can be used with root.xpath() by prefixing '//',
    e.g. root.xpath(f"//{entry['path']}").
    Each entry also includes the first text content found at that path,
    extracted recursively from the node, stripped, and truncated to 100 chars,
    and an array of hyperlink references found in the subtree.

    >>> root = html.fromstring("<div><span>A</span><span>B</span></div>")
    >>> freqs = get_path_stats(root)
    >>> len(freqs)
    2
    >>> freqs[0]['path']
    'div/span'
    >>> freqs[0]['frequency']
    2
    >>> freqs[0]['first_text']
    'A'
    >>> freqs[1]['first_text']
    'AB'
    >>> len(root.xpath(f"//{freqs[0]['path']}"))
    2
    >>> freqs[0]['links']
    []

    >>> root2 = html.fromstring('<div><a href="/a">A</a><a href="/b">B</a></div>')
    >>> freqs2 = get_path_stats(root2)
    >>> freqs2[0]['path']
    'div/a'
    >>> freqs2[1]['links']
    ['/a', '/b']
    """
    data: dict[str, PathData] = {}

    def _traverse(node: html.HtmlElement, current_path: str) -> None:
        path = f"{current_path}/{str(node.tag)}" if current_path else str(node.tag)
        if path not in data:
            raw = etree.tostring(node, method="text", encoding="unicode").strip()
            links = node.xpath(".//a/@href")
            if node.tag == "a" and "href" in node.attrib:
                href = node.attrib["href"]
                if href not in links:
                    links.append(href)
            data[path] = {
                "frequency": 0,
                "first_text": raw[:100] if raw else None,
                "links": links,
            }
        data[path]["frequency"] += 1
        for child in node:
            _traverse(child, path)

    _traverse(root, "")

    result: List[PathFrequency] = [
        PathFrequency(
            path=path,
            frequency=entry["frequency"],
            first_text=entry["first_text"],
            links=entry["links"],
        )
        for path, entry in data.items()
    ]
    result.sort(key=lambda x: x["frequency"], reverse=True)
    return result
