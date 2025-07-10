from fastapi import APIRouter, Depends, HTTPException, status
from typing import List

from app.core.auth import get_current_admin_user, FAKE_USER_DB, get_user
from app.core.security import get_password_hash
from app.models.user import User, UserCreate

router = APIRouter()

@router.get("/users", response_model=List[User])
async def read_users(
    current_admin: User = Depends(get_current_admin_user)
):
    """
    Retrieve all users. Only accessible to administrators.
    """
    # In a real app with a proper database, you would query the users table.
    # For our mock DB, we convert the dictionary values to User models.
    return [User(**user_data) for user_data in FAKE_USER_DB.values()]

@router.post("/users", response_model=User, status_code=status.HTTP_201_CREATED)
async def create_user(
    user_in: UserCreate,
    current_admin: User = Depends(get_current_admin_user)
):
    """
    Create a new user. Only accessible to administrators.
    """
    user = get_user(user_in.username)
    if user:
        raise HTTPException(
            status_code=400,
            detail="The user with this username already exists in the system.",
        )
    
    hashed_password = get_password_hash(user_in.password)
    user_data = user_in.model_dump()
    user_data.pop("password") # Remove plain password before storing
    user_data["hashed_password"] = hashed_password
    user_data["disabled"] = False
    
    # In a real app, this would save to a database. Here we update our mock DB.
    FAKE_USER_DB[user_in.username] = user_data
    
    # Return a User model, not the one with the hashed password
    return User(**user_data)