from redisearch import Document
from sitesearch.config import Config
from sitesearch.models import TYPE_PAGE
from sitesearch.transformer import transform_documents


config = Config()

def test_transform_documents_elides_body_if_longer_than_max():
    doc = Document(
        id="123",
        title="Title",
        section_title="Section",
        hierarchy='["one","two"]',
        url="http://example.com/1",
        body="This is the body",
        type=TYPE_PAGE,
        position=0
    )

    docs = transform_documents([doc], config.default_search_site, 'test', 5)

    assert docs[0]['body'] == "This ..."


def test_transform_documents_retains_body_if_shorter_than_max():
    doc = Document(
        id="123",
        title="Title",
        section_title="Section",
        hierarchy='["one","two"]',
        url="http://example.com/1",
        body="This is the body",
        type=TYPE_PAGE,
        position=0
    )

    docs = transform_documents([doc], config.default_search_site, 'test')

    assert docs[0]['body'] == "This is the body"


def test_transform_documents_decodes_hierarchy():
    doc = Document(
        id="123",
        title="Title",
        section_title="Section",
        hierarchy='["one","two"]',
        url="http://example.com/1",
        body="This is the body",
        type=TYPE_PAGE,
        position=0
    )

    docs = transform_documents([doc], config.default_search_site, 'test')

    assert docs[0]['hierarchy'] == ["one", "two"]


def test_transform_documents_raises_parse_error_with_bad_hierarchy():
    doc = Document(
        id="123",
        title="Title",
        section_title="Section",
        hierarchy='bad json',
        url="http://example.com/1",
        body="This is the body",
        type=TYPE_PAGE,
        position=0
    )

    docs = transform_documents([doc], config.default_search_site, 'test')

    assert docs[0]['hierarchy'] == []
