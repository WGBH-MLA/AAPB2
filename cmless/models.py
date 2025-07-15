from pydantic import BaseModel, Field


class CMLess(BaseModel):
    """
    CMLess document model
    """

    title: str = Field(..., alias="Title")
    slug: str = Field(..., alias="Slug")


class Collection(CMLess):
    """Special Collection model for CMLess documents"""

    summary: str | None = Field(None, alias="Summary")
    background: str | None = Field(None, alias="Background")
    featured: str | None = Field(None, alias="Featured")
    resources: str | None = Field(None, alias="Resources")
    funders: str | None = Field(None, alias="Funders")
    help: str | None = Field(None, alias="Help")
    terms: str | None = Field(None, alias="Terms")
    timeline: str | None = Field(None, alias="Timeline")
    sort: str | None = Field(None, alias="Sort")
