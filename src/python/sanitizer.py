import nh3


def sanitize_html(html: str) -> str:
    """
    Returns the sanitized HTML string.

    >>> sanitize_html("<p>Hello</p>")
    '<p>Hello</p>'
    >>> sanitize_html("<script>alert('xss')</script><p>Hello</p>")
    '<p>Hello</p>'
    """
    return nh3.clean(html)
