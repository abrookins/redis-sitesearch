import re
from typing import List, Union

from docsearch.models import SynonymGroup
from redisearch import Query

UNSAFE_CHARS = re.compile('[\\[\\]\\-@+]')


def parse(query: str, synonyms: Union[List[SynonymGroup], None] = None) -> Query:
    # Dash postfixes confuse the query parser.
    query = query.strip().replace("-*", "*")
    query = UNSAFE_CHARS.sub(' ', query)
    query = query.strip()

    # For queries of a term that should result in an exact match, e.g.
    # "insight" (a synonym of RedisInsight), or "active-active", strip any star
    # postfix to avoid the query becoming a fuzzy search.
    if synonyms and query.endswith('*'):
        all_synonyms = set()
        exact_match_query = query.rstrip("*")
        for group in synonyms:
            all_synonyms |= group.synonyms
        if exact_match_query in all_synonyms:
            query = exact_match_query

    return Query(query).summarize(
        'body', context_len=10
    ).highlight(
        ('title', 'body', 'section_title')
    )
