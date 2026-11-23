from pydantic import BaseModel, UUID4, Field
from typing import Optional, Literal
from datetime import datetime
import uuid

class HoldingBase(BaseModel):
    symbol: str = Field(..., example="AAPL")
    quantity_x10000: int = Field(..., description="Quantity stored as integer multiplied by 10000 to avoid floating point.")
    average_price_cents: int = Field(..., description="Price stored in cents.")

class HoldingCreate(HoldingBase):
    pass

class Holding(HoldingBase):
    id: str
    created_at: datetime

    class Config:
        orm_mode = True
        from_attributes = True

class Recommendation(BaseModel):
    symbol: str
    signal: Literal["Buy", "Hold", "Sell"]
    technical_score: int
    sentiment_score: int
