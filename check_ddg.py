try:
    import duckduckgo_search

    print(f"duckduckgo_search version: {duckduckgo_search.__version__}")
except ImportError as e:
    print(f"Failed to import duckduckgo_search: {e}")

try:
    from langchain_community.tools import DuckDuckGoSearchRun

    print("Successfully imported DuckDuckGoSearchRun")
    search = DuckDuckGoSearchRun()
    # Don't run it, just check instantiation
    print("Successfully instantiated DuckDuckGoSearchRun")
except Exception as e:
    print(f"Failed to use DuckDuckGoSearchRun: {e}")

try:
    from duckduckgo_search import DDGS

    print("Successfully imported DDGS from duckduckgo_search")
    with DDGS() as ddgs:
        results = list(ddgs.text("python", max_results=1))
        print(f"Search results: {results}")
except ImportError as e:
    print(f"Failed to import DDGS: {e}")
except Exception as e:
    print(f"Failed to run DDGS: {e}")

try:
    import ddgs

    print("Successfully imported ddgs module")
except ImportError:
    print("Failed to import ddgs module")
