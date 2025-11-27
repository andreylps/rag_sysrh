import asyncio
import logging
import os

from watchdog.events import FileSystemEventHandler
from watchdog.observers import Observer

# Import the connection manager instance to send broadcasts
from src.api.v1.endpoints.chat import manager
from src.rag_sysrh.ingestion_service import ingest_uploaded_file

logger = logging.getLogger(__name__)


class KnowledgeBaseEventHandler(FileSystemEventHandler):
    """
    Handles file system events for the Knowledge Base data directory.
    Triggers ingestion and notifies users via WebSocket.
    """

    def __init__(self, loop):
        self.loop = loop

    def _process_event(self, event):
        if event.is_directory:
            return

        filename = os.path.basename(event.src_path)
        if filename.startswith("~") or filename.startswith("."):
            return  # Ignore temp/hidden files

        if filename.endswith(".json"):
            return  # Ignore system JSON files (schedules, reports)

        logger.info(f"Detected change in {event.src_path} ({event.event_type})")

        # Notify start of update
        self._notify_ui("[SISTEMA_START]")

        try:
            # Run ingestion (this is blocking, so maybe run in executor if heavy)
            # For now, running directly as it's in a separate thread from the main loop (watchdog thread)
            chunks = ingest_uploaded_file(event.src_path)

            if chunks > 0:
                self._notify_ui(f"✅ Base atualizada: {filename}")
                self._notify_ui("[SISTEMA_END]")
            else:
                self._notify_ui(f"⚠ Arquivo vazio/ignorado: {filename}")
                self._notify_ui("[SISTEMA_END]")  # Even if empty, we stop the loading

        except Exception as e:
            logger.error(f"Error processing file {event.src_path}: {e}")
            self._notify_ui(f"❌ Erro em '{filename}'")
            self._notify_ui("[SISTEMA_END]")  # Stop loading on error too

    def _notify_ui(self, message: str):
        """
        Sends a message to all connected WebSocket clients.
        Since this runs in a separate thread, we need to schedule it on the main event loop.
        """
        if self.loop and self.loop.is_running():
            asyncio.run_coroutine_threadsafe(
                manager.broadcast(f"[SISTEMA] {message}"), self.loop
            )

    def on_created(self, event):
        self._process_event(event)

    def on_modified(self, event):
        self._process_event(event)


class FileWatcherService:
    def __init__(self, directory_to_watch: str):
        self.directory = directory_to_watch
        self.observer = Observer()

    def start(self):
        if not os.path.exists(self.directory):
            logger.warning(f"Directory to watch does not exist: {self.directory}")
            return

        # Get the running event loop to schedule async tasks from the thread
        try:
            loop = asyncio.get_running_loop()
        except RuntimeError:
            loop = None
            logger.warning("No running event loop found for FileWatcherService.")

        event_handler = KnowledgeBaseEventHandler(loop)
        self.observer.schedule(event_handler, self.directory, recursive=True)
        self.observer.start()
        logger.info(f"FileWatcherService started monitoring: {self.directory}")

    def stop(self):
        self.observer.stop()
        self.observer.join()
        logger.info("FileWatcherService stopped.")
