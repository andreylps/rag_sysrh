import logging
import os
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

logger = logging.getLogger(__name__)


class EmailService:
    def __init__(self):
        self.smtp_server = os.getenv("SMTP_SERVER", "smtp.gmail.com")
        self.smtp_port = int(os.getenv("SMTP_PORT", "587"))
        self.smtp_user = os.getenv("SMTP_USER")
        self.smtp_password = os.getenv("SMTP_PASSWORD")
        self.sender_email = self.smtp_user or "noreply@sysrh.com"

    def send_email(self, to_email: str, subject: str, body: str, is_html: bool = False):
        """
        Envia um e-mail usando SMTP.
        Retorna (success, status_code).
        status_code: 'sent', 'simulated', 'error'
        """
        if not self.smtp_user or not self.smtp_password:
            logger.warning(
                "Credenciais SMTP não configuradas. Simulando envio de e-mail."
            )
            logger.info(
                f"--- SIMULAÇÃO DE E-MAIL ---\nPara: {to_email}\nAssunto: {subject}\nCorpo: {body}\n---------------------------"
            )
            return True, "simulated"

        try:
            msg = MIMEMultipart()
            msg["From"] = self.sender_email
            msg["To"] = to_email
            msg["Subject"] = subject

            msg.attach(MIMEText(body, "html" if is_html else "plain"))

            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()
                server.login(self.smtp_user, self.smtp_password)
                server.send_message(msg)

            logger.info(f"E-mail enviado com sucesso para {to_email}")
            return True, "sent"

        except Exception as e:
            logger.error(f"Falha ao enviar e-mail: {e}")
            return False, "error"

    def send_rcm_approval_link(
        self, to_email: str, issue_number: int, issue_title: str
    ):
        """
        Envia o link de aprovação do RCM para o cliente.
        """
        link = f"http://localhost:5173/cliente/aprovacao/{issue_number}"
        subject = f"Aprovação Necessária: RCM #{issue_number} - {issue_title}"

        body = f"""
        <html>
            <body style="font-family: Arial, sans-serif; color: #333;">
                <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
                    <h2 style="color: #047081;">Validação de Orçamento e Escopo</h2>
                    <p>Olá,</p>
                    <p>A Memória de Cálculo (RCM) para a demanda <strong>#{issue_number} - {issue_title}</strong> foi revisada e está pronta para sua aprovação.</p>
                    <p>Por favor, acesse o Portal do Cliente para revisar os detalhes, baixar o documento e registrar sua decisão:</p>
                    <div style="text-align: center; margin: 30px 0;">
                        <a href="{link}" style="background-color: #047081; color: white; padding: 15px 25px; text-decoration: none; border-radius: 5px; font-weight: bold; font-size: 16px;">Acessar Portal do Cliente</a>
                    </div>
                    <p style="font-size: 12px; color: #777;">Se o botão acima não funcionar, copie e cole o link abaixo no seu navegador:</p>
                    <p style="font-size: 12px; color: #555;"><a href="{link}">{link}</a></p>
                    <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
                    <p style="font-size: 12px; color: #999;">Este é um e-mail automático do Sistema RAG SYS-RH.</p>
                </div>
            </body>
        </html>
        """

        return self.send_email(to_email, subject, body, is_html=True)
