from datetime import datetime
from typing import List

from rag_sysrh.engine.models import AuditVerdict, NonConformity, ResultadoSISP
from rag_sysrh.services.audit_tools import AuditTools


class AuditorAgent:
    """
    Agente Auditor de Qualidade & Compliance (AuditorAI).
    Atua como Quality Gate final.
    """

    def __init__(self):
        self.tools = AuditTools()

    def audit_delivery(
        self, resultado: ResultadoSISP, diagnostico_tecnico: str
    ) -> AuditVerdict:
        """
        Executa a bateria de testes e gera o veredito.
        """
        non_conformities: List[NonConformity] = []

        # 1. Integridade dos Templates
        non_conformities.extend(self.tools.verify_template_integrity(resultado))

        # Se arquivos não existem, aborta checks profundos
        critical_integrity = any(nc.severity == "CRITICAL" for nc in non_conformities)

        if not critical_integrity:
            # 2. Compliance SISP (Numérico)
            non_conformities.extend(self.tools.audit_sisp_process_compliance(resultado))

            # 3. Segurança (PII)
            non_conformities.extend(self.tools.scan_for_security_risks(resultado))

        # 4. Clareza Técnica (LLM)
        # Executa mesmo se houver erro de arquivo, para dar feedback completo sobre o texto
        score, critique = self.tools.evaluate_technical_clarity_llm(diagnostico_tecnico)

        if score < 3.0:
            non_conformities.append(
                NonConformity(
                    type="TECHNICAL_CLARITY",
                    severity="MEDIUM",
                    description=f"Baixa clareza técnica (Nota {score}/5.0). Crítica: {critique}",
                )
            )

        # Decisão Final
        # Reprova se houver qualquer CRITICAL ou HIGH, ou se score < 2.5
        is_approved = not any(
            nc.severity in ["CRITICAL", "HIGH"] for nc in non_conformities
        )

        status = "APROVADO" if is_approved else "REPROVADO"

        final_comments = "Entrega validada com sucesso."
        if not is_approved:
            final_comments = "Entrega bloqueada. Corrija as não-conformidades listadas."
        elif non_conformities:
            final_comments = "Aprovado com ressalvas (avisos de baixa severidade)."

        return AuditVerdict(
            audit_status=status,
            audit_timestamp=datetime.now().isoformat(),
            quality_score=score,
            non_conformities=non_conformities,
            final_comments=final_comments,
        )
