from pydantic import BaseModel, EmailStr
from typing import Optional

class User(BaseModel):
    username: EmailStr
    full_name: Optional[str] = None
    role: str
    disabled: Optional[bool] = None

class UserInDB(User):
    hashed_password: str