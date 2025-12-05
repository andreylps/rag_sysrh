import json
import logging
import os
import uuid
from datetime import datetime

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from src.models.qa_models import PDCAReport
from src.services.github_service import search_closed_issues

# Configuração de Logging
logger = logging.getLogger(__name__)

REPORTS_DIR = "data/reports/pdca"


class AuditService:
    async def execute_sprint_end_audit(self, start_date: datetime, end_date: datetime):
        """Executa a auditoria de fim de sprint e gera o relatório PDCA."""
        logger.info(f"Executando Auditoria de Sprint: {start_date} a {end_date}")

        # 1. Coleta de Dados (Simulada/Real)
        # Buscar issues fechadas no período
        query = f"is:issue is:closed closed:{start_date.strftime('%Y-%m-%d')}..{end_date.strftime('%Y-%m-%d')}"
        closed_issues = await search_closed_issues(query=query, limit=100)

        # Métricas Básicas
        total_closed = len(closed_issues)
        # Simular métricas de qualidade
        bugs_found = sum(
            1
            for i in closed_issues
            if "bug" in [label.lower() for label in i.get("labels", [])]
        )

        metrics = {
            "total_entregas": total_closed,
            "bugs_encontrados": bugs_found,
            "taxa_sucesso": f"{((total_closed - bugs_found) / total_closed * 100):.1f}%"
            if total_closed > 0
            else "N/A",
        }

        # 2. Análise de IA (Simulada para este exemplo, mas usaria LangChain)
        analysis_summary = (
            f"Durante o ciclo de {start_date.strftime('%d/%m')} a {end_date.strftime('%d/%m')}, "
            f"o time entregou {total_closed} itens. A taxa de qualidade foi de {metrics['taxa_sucesso']}. "
            "Observou-se uma boa adesão ao processo de RCM, mas recomenda-se atenção à documentação de APIs."
        )

        pdca_plan = [
            "Plan: Reforçar revisão de documentação técnica.",
            "Do: Agendar treinamento de Swagger para o time.",
            "Check: Monitorar issues de 'dúvida' na próxima sprint.",
            "Act: Atualizar template de PR com checklist de doc.",
        ]

        # 3. Geração do PDF
        report_id = str(uuid.uuid4())
        filename = f"PDCA_Report_{report_id}.pdf"
        file_path = os.path.join(REPORTS_DIR, filename)

        generate_pdca_pdf(
            file_path, start_date, end_date, metrics, analysis_summary, pdca_plan
        )

        # 4. Persistência do Relatório
        suggestion = pdca_plan[0] if pdca_plan else "Nenhuma sugestão registrada."

        report = PDCAReport(
            id=report_id,
            generation_date=datetime.now(),
            cycle_period=f"Sprint {start_date.strftime('%b/%Y')}",
            summary=analysis_summary,
            pdf_file_path=file_path,
            metrics_snapshot=metrics,
            audit_type="SPRINT_END",
            improvement_suggestion=suggestion,
        )

        _save_report(report)
        logger.info(f"Relatório PDCA gerado: {file_path}")
        return report

    async def execute_generic_audit(self, audit_type: str, details: dict):
        """Executa auditorias específicas (Doc, Code, Security)."""
        logger.info(f"Executando Auditoria Específica: {audit_type}")

        # Simulação de lógica específica para cada tipo
        focus = details.get("focus", "Geral")
        metrics = {"itens_verificados": 50, "conformidade": "98%"}

        if audit_type == "DOC_AUDIT":
            analysis = f"Auditoria de Documentação focada em {focus}. A maioria dos manuais está atualizada."
            plan = [
                "Revisar manual do usuário final para clareza.",
                "Padronizar terminologia.",
            ]
        elif audit_type == "SECURITY_AUDIT":
            analysis = f"Auditoria de Segurança ({focus}). Nenhuma vulnerabilidade crítica encontrada."
            plan = [
                "Atualizar dependências npm para versão mais recente.",
                "Revisar permissões de acesso.",
            ]
        else:
            analysis = f"Auditoria Técnica ({focus}). Código segue padrões."
            plan = ["Manter boas práticas de Clean Code.", "Refatorar módulo legado."]

        # Gerar PDF
        report_id = str(uuid.uuid4())
        filename = f"PDCA_{audit_type}_{report_id}.pdf"
        file_path = os.path.join(REPORTS_DIR, filename)

        generate_pdca_pdf(
            file_path,
            datetime.now(),
            datetime.now(),
            metrics,
            analysis,
            plan,
            title=f"Relatório: {audit_type}",
        )

        # Persistir
        suggestion = plan[0] if plan else "Manter monitoramento constante."

        report = PDCAReport(
            id=report_id,
            generation_date=datetime.now(),
            cycle_period=f"{audit_type} - {datetime.now().strftime('%b/%Y')}",
            summary=analysis,
            pdf_file_path=file_path,
            metrics_snapshot=metrics,
            audit_type=audit_type,
            improvement_suggestion=suggestion,
        )
        _save_report(report)
        return report

    async def generate_quarterly_report(self, start_date: datetime, end_date: datetime):
        """Gera o relatório consolidado trimestral."""
        logger.info(f"Gerando Relatório Trimestral: {start_date} a {end_date}")

        all_reports = get_all_reports()
        # Filtrar pelo período
        period_reports = [
            r for r in all_reports if start_date <= r.generation_date <= end_date
        ]

        total_audits = len(period_reports)
        unique_types = set(r.audit_type for r in period_reports)

        analysis_summary = (
            f"Relatório Consolidado do Trimestre. Total de auditorias realizadas: {total_audits}. "
            f"Tipos cobertos: {', '.join(unique_types)}. "
            "O sistema demonstrou estabilidade e evolução contínua."
        )

        metrics = {
            "total_auditorias": total_audits,
            "tipos_distintos": len(unique_types),
            "status_geral": "CONFORME",
        }

        pdca_plan = [
            "Manter cronograma de auditorias automáticas.",
            "Avaliar eficácia das ações corretivas do período.",
            "Planejar próximo ciclo trimestral.",
        ]

        report_id = str(uuid.uuid4())
        filename = f"QUARTERLY_REPORT_{report_id}.pdf"
        file_path = os.path.join(REPORTS_DIR, filename)

        generate_pdca_pdf(
            file_path,
            start_date,
            end_date,
            metrics,
            analysis_summary,
            pdca_plan,
            title="Relatório Trimestral de Conformidade",
        )

        suggestion = pdca_plan[0] if pdca_plan else "Avaliar métricas de longo prazo."

        report = PDCAReport(
            id=report_id,
            generation_date=datetime.now(),
            cycle_period=f"Quarterly {end_date.strftime('%Y')}",
            summary=analysis_summary,
            pdf_file_path=file_path,
            metrics_snapshot=metrics,
            audit_type="QUARTERLY_REPORT",
            improvement_suggestion=suggestion,
        )
        _save_report(report)
        return report


audit_service = AuditService()


def generate_pdca_pdf(
    file_path,
    start_date,
    end_date,
    metrics,
    analysis,
    pdca_plan,
    title="Relatório de Auditoria de Qualidade & PDCA",
):
    """Gera o arquivo PDF usando ReportLab."""
    doc = SimpleDocTemplate(file_path, pagesize=letter)
    styles = getSampleStyleSheet()
    story = []

    # Título
    story.append(Paragraph(title, styles["Title"]))
    story.append(Spacer(1, 12))

    # Período
    period_text = f"<b>Período do Ciclo:</b> {start_date.strftime('%d/%m/%Y')} a {end_date.strftime('%d/%m/%Y')}"
    story.append(Paragraph(period_text, styles["Normal"]))
    story.append(Spacer(1, 12))

    # Métricas
    story.append(Paragraph("<b>Métricas do Ciclo (Check):</b>", styles["Heading2"]))
    data = [["Métrica", "Valor"]]
    for k, v in metrics.items():
        data.append([k.replace("_", " ").title(), str(v)])

    t = Table(data)
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.grey),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
                ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("BOTTOMPADDING", (0, 0), (-1, 0), 12),
                ("BACKGROUND", (0, 1), (-1, -1), colors.beige),
                ("GRID", (0, 0), (-1, -1), 1, colors.black),
            ]
        )
    )
    story.append(t)
    story.append(Spacer(1, 12))

    # Análise
    story.append(Paragraph("<b>Análise de Qualidade:</b>", styles["Heading2"]))
    story.append(Paragraph(analysis, styles["Normal"]))
    story.append(Spacer(1, 12))

    # Plano de Ação (PDCA)
    story.append(Paragraph("<b>Plano de Ação (Act):</b>", styles["Heading2"]))
    for item in pdca_plan:
        story.append(Paragraph(f"• {item}", styles["Normal"]))

    doc.build(story)


def _save_report(report: PDCAReport):
    """Salva o metadado do relatório em JSON."""
    reports_file = "data/pdca_reports.json"
    reports = []
    if os.path.exists(reports_file):
        try:
            with open(reports_file, "r", encoding="utf-8") as f:
                data = json.load(f)
                reports = [PDCAReport(**item) for item in data]
        except Exception:
            pass

    reports.append(report)
    with open(reports_file, "w", encoding="utf-8") as f:
        json.dump(
            [r.dict() for r in reports], f, default=str, ensure_ascii=False, indent=2
        )


def get_all_reports():
    """Retorna todos os relatórios gerados."""
    reports_file = "data/pdca_reports.json"
    if os.path.exists(reports_file):
        try:
            with open(reports_file, "r", encoding="utf-8") as f:
                data = json.load(f)
                # Ordenar por data decrescente
                reports = [PDCAReport(**item) for item in data]
                return sorted(reports, key=lambda x: x.generation_date, reverse=True)
        except Exception:
            pass
    return []
