from lxml import html


def parse_html_to_tree(html_string: str) -> html.HtmlElement:
    """
    Returns a hierarchical tree structure parsed from HTML_STRING.

    >>> tree = parse_html_to_tree("<div><p>Test</p></div>")
    >>> len(tree.xpath('//p'))
    1
    >>> tree.xpath('//p')[0].text
    'Test'
    """
    try:
        tree = html.fromstring(html_string)
        return tree
    except Exception as e:
        raise ValueError(f"Failed to parse HTML: {e}")
