from lxml import html
import re
from typing import List, TypedDict

# HTML block-level elements
# Separate text with newlines at each block level element.
# All other elements are concatenated without a separator.
# Selected from list at https://www.w3schools.com/tAGS/default.asp
BLOCK_TAGS = {
    "address",
    "article",
    "aside",
    "blockquote",
    "body",
    "br",
    "caption",
    "dd",
    "details",
    "dialog",
    "div",
    "dl",
    "dt",
    "fieldset",
    "figcaption",
    "figure",
    "footer",
    "form",
    "h1",
    "h2",
    "h3",
    "h4",
    "h5",
    "h6",
    "header",
    "hgroup",
    "hr",
    "html",
    "label",
    "legend",
    "li",
    "main",
    "menu",
    "nav",
    "ol",
    "optgroup",
    "option",
    "p",
    "pre",
    "section",
    "select",
    "summary",
    "table",
    "tbody",
    "td",
    "tfoot",
    "th",
    "thead",
    "tr",
    "ul",
}


class PathData(TypedDict):
    frequency: int
    first_text: str | None
    links: List[str]


class PathElementDetails(TypedDict):
    text: str
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
    b'<html><body><div><p>Test</p></div></body></html>'
    >>> print(root.tag)
    html
    >>> print(root[0].tag)
    body

    >>> root2 = parse_html_to_tree("<p>Hi")
    >>> html.tostring(root2)
    b'<html><body><p>Hi</p></body></html>'
    """
    return html.document_fromstring(html_string)


def get_path_stats(root: html.HtmlElement) -> List[PathFrequency]:
    """
    Traverses the tree and returns root-to-node paths with occurrence
    frequencies, sorted descending by frequency.
    Paths include all tags from root to each node, e.g. 'html/body/div/p'.
    These paths can be used with root.xpath() by prefixing '/',
    e.g. root.xpath(f"/{entry['path']}").
    Each entry also includes the first text content found at that path,
    extracted recursively from the node, stripped, and truncated to 100 chars,
    and an array of hyperlink references found in the subtree.

    >>> root = html.document_fromstring("<div><span>A</span><span>B</span></div>")
    >>> freqs = get_path_stats(root)
    >>> len(freqs)
    4
    >>> freqs[0]['path']
    'html/body/div/span'
    >>> freqs[0]['frequency']
    2
    >>> freqs[0]['first_text']
    'A'
    >>> freqs[1]['first_text']
    'AB'
    >>> len(root.xpath(f"/{freqs[0]['path']}"))
    2
    >>> freqs[0]['links']
    []

    >>> root2 = html.document_fromstring('<div><a href="/a">A</a><a href="/b">B</a></div>')
    >>> freqs2 = get_path_stats(root2)
    >>> freqs2[0]['path']
    'html/body/div/a'
    >>> freqs2[1]['links']
    ['/a', '/b']
    """
    data: dict[str, PathData] = {}

    def _traverse(node: html.HtmlElement, current_path: str) -> None:
        path = f"{current_path}/{str(node.tag)}" if current_path else str(node.tag)
        if path not in data:
            raw, links = _extract_node_data(node)
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


def _extract_text(node: html.HtmlElement) -> str:
    r"""
    Extracts text content from an HTML element, inserting newlines at
    block-level elements.

    >>> _extract_text(html.document_fromstring("<div></div>"))
    '\n'

    >>> _extract_text(html.document_fromstring("<span>A <b>bold</b> span</span>"))
    '\nA bold span'

    >>> _extract_text(html.document_fromstring("<div><p>First</p><p>Second</p></div>"))
    '\nFirst\nSecond'

    >>> _extract_text(html.document_fromstring("<form><label>Username</label><input><label>Password</label><input></form>"))
    '\nUsername\nPassword'

    >>> _extract_text(html.document_fromstring("<label>Options</label><select><option>A</option><option>B</option></select>"))
    '\nOptions\nA\nB'

    >>> _extract_text(html.document_fromstring("<label>Options</label><select><optgroup><option>One</option></optgroup><optgroup><option>Two</option></optgroup></select>"))
    '\nOptions\nOne\nTwo'

    >>> _extract_text(html.document_fromstring("<select><option>A</option></select><select><option>B</option></select>"))
    '\nA\nB'

    >>> _extract_text(html.document_fromstring("<div>Hello <p>World<p>!</div>"))
    '\nHello \nWorld\n!'

    >>> _extract_text(html.document_fromstring("<div>Hello <p>World<p>!</div><div>From Python</div>"))
    '\nHello \nWorld\n!\nFrom Python'

    >>> _extract_text(html.document_fromstring("<div>Hello <p>World<p>!</div><div>From<br>Python</div>"))
    '\nHello \nWorld\n!\nFrom\nPython'
    """
    parts: list[str] = []
    if node.text:
        parts.append(node.text)
    for child in node:
        child_text = _extract_text(child)
        if child.tag in BLOCK_TAGS:
            parts.append("\n")
        parts.append(child_text)
        if child.tail:
            parts.append(child.tail)
    parts_string = "".join(parts)
    # squish consecutive newlines into one newline
    return re.sub(r"\n+", "\n", parts_string)


def _extract_node_data(
    node: html.HtmlElement,
) -> tuple[str, list[str]]:
    r"""
    Extracts text content and hyperlink references from an HTML element.

    >>> node = html.document_fromstring("<p>Hello</p>")
    >>> _extract_node_data(node)
    ('Hello', [])

    >>> node2 = html.document_fromstring('<div>Text <a href="/link">here</a></div>')
    >>> _extract_node_data(node2)
    ('Text here', ['/link'])

    >>> node3 = html.document_fromstring('<a href="/click">Click me</a>')
    >>> _extract_node_data(node3)
    ('Click me', ['/click'])

    >>> node4 = html.document_fromstring("<div></div>")
    >>> _extract_node_data(node4)
    ('', [])

    >>> node5 = html.document_fromstring("<div><p>1</p><p>2</p></div>")
    >>> _extract_node_data(node5)
    ('1\n2', [])

    """
    raw = _extract_text(node).strip()
    links: list[str] = node.xpath(".//a/@href")
    if node.tag == "a" and "href" in node.attrib:
        links.append(node.attrib["href"])
    return raw, links


def get_content_for_path(
    root: html.HtmlElement, path: str, limit: int | None = None
) -> List[PathElementDetails]:
    r"""
    Returns the complete text and links for the first `limit` items
    at the specified PATH in ROOT.

    >>> root = html.document_fromstring('<div><span>One <a href="/a">A</a></span><span>Two</span><span>Three</span></div>')
    >>> details = get_content_for_path(root, 'html/body/div/span', limit=2)
    >>> len(details)
    2
    >>> details[0]['text']
    'One A'
    >>> details[0]['links']
    ['/a']
    >>> details[1]['text']
    'Two'
    >>> details[1]['links']
    []

    >>> details_all = get_content_for_path(root, 'html/body/div/span', limit=None)
    >>> len(details_all)
    3
    >>> details_all[2]['text']
    'Three'

    >>> root2 = html.document_fromstring('<div><div><p>1</p><p>2</p></div></div>')
    >>> details2 = get_content_for_path(root2, 'html/body/div')
    >>> len(details2)
    1
    >>> details2[0]['text']
    '1\n2'

    >>> root3 = html.document_fromstring('<div></div>')
    >>> details3 = get_content_for_path(root3, 'div')
    >>> len(details3)
    0

    >>> root4 = html.document_fromstring('<div><div></div><div>1</div></div>')
    >>> details4 = get_content_for_path(root4, 'html/body/div/div', limit = 1)
    >>> len(details4)
    1

    """
    nodes = root.xpath(f"/{path}")
    results = []
    i = 0
    for node in nodes:
        raw, links = _extract_node_data(node)
        # Only include nodes that have text up to limit if specified
        if raw:
            results.append(PathElementDetails(text=raw, links=links))
            i += 1
        if limit is not None and i == limit:
            break
    return results
