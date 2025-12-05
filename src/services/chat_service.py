import datetime

from sqlalchemy.orm import Session

from src.models.chat_model import ChatMessage, ChatSession


class ChatService:
    def __init__(self, db: Session):
        self.db = db

    def create_session(self, title: str = "New Chat") -> ChatSession:
        session = ChatSession(title=title)
        self.db.add(session)
        self.db.commit()
        self.db.refresh(session)
        return session

    def get_sessions(self) -> list[ChatSession]:
        return self.db.query(ChatSession).order_by(ChatSession.updated_at.desc()).all()

    def get_session(self, session_id: str) -> ChatSession:
        return self.db.query(ChatSession).filter(ChatSession.id == session_id).first()

    def delete_session(self, session_id: str):
        session = self.get_session(session_id)
        if session:
            self.db.delete(session)
            self.db.commit()

    def save_message(
        self, session_id: str, sender: str, content: str, attachments: list = None
    ) -> ChatMessage:
        if not session_id:
            # Create a new session if none exists (though usually frontend should create one)
            session = self.create_session()
            session_id = session.id

        # Update session timestamp
        session = self.get_session(session_id)
        if session:
            session.updated_at = datetime.datetime.utcnow()
            # Auto-generate title from first user message if title is "New Chat"
            if session.title == "New Chat" and sender == "user":
                session.title = content[:30] + "..." if len(content) > 30 else content
            self.db.add(session)

        message = ChatMessage(
            session_id=session_id,
            sender=sender,
            content=content,
            attachments=attachments or [],
        )
        self.db.add(message)
        self.db.commit()
        self.db.refresh(message)
        return message

    def get_messages(self, session_id: str) -> list[ChatMessage]:
        return (
            self.db.query(ChatMessage)
            .filter(ChatMessage.session_id == session_id)
            .order_by(ChatMessage.timestamp.asc())
            .all()
        )
