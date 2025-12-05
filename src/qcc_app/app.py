import asyncio

from dotenv import load_dotenv
from flask import Flask, render_template
from flask_apscheduler import APScheduler

from src.qcc_app.config import Config
from src.services.quality_service import check_for_stale_issues

# Carrega variáveis de ambiente
load_dotenv()

app = Flask(__name__)
app.config.from_object(Config)

# Inicializa o Scheduler
scheduler = APScheduler()
scheduler.init_app(app)
scheduler.start()


def run_async_task(task_func):
    """Helper para rodar funções assíncronas no scheduler síncrono."""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(task_func())
    loop.close()


# Tarefa Agendada: Auditoria de Issues Estagnadas
@scheduler.task("interval", id="audit_stale_issues", days=10)
def scheduled_audit():
    print("⏰ [QCC Scheduler] Iniciando auditoria automática de issues estagnadas...")
    with app.app_context():
        run_async_task(check_for_stale_issues)


# Rotas
@app.route("/")
def dashboard():
    return render_template("dashboard.html")


@app.route("/reports")
def reports():
    return render_template("reports.html")


@app.route("/audits")
def audits():
    return render_template("audits.html")


if __name__ == "__main__":
    app.run(port=5001, debug=True)
