from lxml import etree


def parse_html_to_tree(html_string: str) -> etree.Element:
    """
    Returns a hierarchical tree structure parsed from HTML_STRING.

    >>> root = parse_html_to_tree("<div><p>Test</p></div>")
    >>> etree.tostring(root)
    b'<div><p>Test</p></div>'

    >>> print(root.tag)
    div

    >>> print(root[0].tag)
    p

    """
    return etree.fromstring(html_string)
