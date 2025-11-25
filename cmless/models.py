from pydantic import BaseModel, Field, ConfigDict, ValidationError, AfterValidator
from typing import Annotated
import markdown as md


def parse_markdown(text: str) -> dict:
    html = md.markdown(text)
    return html


class CMLess(BaseModel):
    """
    CMLess document model
    """

    model_config = ConfigDict(extra='forbid')

    title: str = Field(..., alias="Title")
    slug: str = Field(..., alias="Slug")

    summary: str | None = Field(None, alias="Summary")
    resources: str | None = Field(None, alias="Resources")


class Collection(CMLess):
    """Special Collection model for CMLess documents"""

    background: str | None = Field(None, alias="Background")
    featured: str | None = Field(None, alias="Featured")
    funders: str | None = Field(None, alias="Funders")
    help: str | None = Field(None, alias="Help")
    terms: str | None = Field(None, alias="Terms")
    timeline: str | None = Field(None, alias="Timeline")
    sort: str | None = Field(None, alias="Sort")
    thumbnail: str | None = Field(None, alias="Thumbnail")


class Exhibit(CMLess):
    """Exhibit model for CMLess documents"""

    extended: str | None = Field(None, alias="Extended")
    authors: str | None = Field(None, alias="Authors")
    main: str | None = Field(None, alias="Main")
    cover: str | None = Field(None, alias="Cover")
    gallery: str | None = Field(None, alias="Gallery")
    records: str | None = Field(None, alias="Records")
    page: int | None = Field(None, alias="Page")
