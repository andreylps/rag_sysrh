import logging
import os

from dotenv import load_dotenv
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_neo4j import Neo4jGraph
from langchain_openai import ChatOpenAI


class BaseAgent:
    """A base class for agents to share common initialization logic."""

    def __init__(self) -> None:
        load_dotenv()
        provider = os.getenv("LLM_PROVIDER", "openai").lower()

        if provider == "gemini":
            self.llm = ChatGoogleGenerativeAI(model="gemini-1.5-flash", temperature=0)
            logging.info("Using Gemini (Google) as LLM provider.")
        else:
            self.llm = ChatOpenAI(model="gpt-4o", temperature=0)
            logging.info("Using OpenAI as LLM provider.")

        self._connect_to_neo4j()

    def _connect_to_neo4j(self) -> None:
        """Initializes and validates the connection to the Neo4j database."""
        try:
            uri = os.getenv("NEO4J_URI")
            username = os.getenv("NEO4J_USERNAME")
            password = os.getenv("NEO4J_PASSWORD")
            if not all([uri, username, password]):
                msg = "NEO4J_URI, NEO4J_USERNAME, or NEO4J_PASSWORD environment variables are not set."
                raise ValueError(msg)

            self.graph = Neo4jGraph(url=uri, username=username, password=password)
            # Verify the connection by running a simple query
            self.graph.query("RETURN 1")
            logging.info(f"Neo4j connection successful for {self.__class__.__name__}.")
        except Exception as e:
            logging.exception(
                f"Failed to connect to Neo4j for {self.__class__.__name__}: {e}"
            )
            raise

    def set_llm(self, provider: str) -> None:
        """Switches the LLM provider dynamically."""
        provider = provider.lower()
        if provider == "gemini":
            self.llm = ChatGoogleGenerativeAI(
                model="gemini-1.5-flash-001", temperature=0
            )
            logging.info("Switched to Gemini (Google) LLM.")
        elif provider == "openai":
            self.llm = ChatOpenAI(model="gpt-4o", temperature=0)
            logging.info("Switched to OpenAI LLM.")
        else:
            logging.warning(f"Unknown provider {provider}, keeping current LLM.")
