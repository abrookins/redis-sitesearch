import logging

import click

from sitesearch import tasks
from sitesearch.config import AppConfiguration


config = AppConfiguration()
log = logging.getLogger(__name__)


@click.argument('site')
@click.command()
def index(site: str):
    """Index the app's configured sites in RediSearch."""
    site = config.sites.get(site)

    if site is None:
        valid_sites = ", ".join(config.sites.keys())
        raise click.BadArgumentUsage(
            f"The site you gave does not exist. Valid sites: {valid_sites}")

    tasks.index(site, force=True)
