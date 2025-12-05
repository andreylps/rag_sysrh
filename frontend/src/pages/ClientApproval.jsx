import React, { useState, useEffect } from "react";
import { useParams } from "react-router-dom";
import ReactMarkdown from "react-markdown";
import { toast } from "react-toastify";
import {
  CheckCircle,
  XCircle,
  Clock,
  FileText,
  Download,
  History,
  AlertTriangle,
  Box,
  Calendar,
  DollarSign,
  ArrowLeft,
} from "lucide-react";
import { API_BASE_URL } from "../config";

const ClientApproval = () => {
  const { issue_number } = useParams();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [details, setDetails] = useState(null);

  const [showRejectReason, setShowRejectReason] = useState(false);
  const [rejectReason, setRejectReason] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [finalDecision, setFinalDecision] = useState(null); // 'approve' or 'reject'

  useEffect(() => {
    const fetchDetails = async () => {
      setLoading(true);
      try {
        const response = await fetch(
          `${API_BASE_URL}/rcm/${issue_number}/details`
        );

        if (!response.ok) {
          throw new Error("Não foi possível carregar os detalhes da proposta.");
        }

        const data = await response.json();
        setDetails(data);
      } catch (err) {
        console.error(err);
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchDetails();
  }, [issue_number]);

  const handleAction = async (action) => {
    if (action === "reject" && !rejectReason.trim()) {
      toast.error("Por favor, informe o motivo da devolução.");
      return;
    }

    setSubmitting(true);
    try {
      const payload = {
        action: action,
        client_comments: action === "reject" ? rejectReason : null,
      };

      const response = await fetch(
        `${API_BASE_URL}/rcm/${issue_number}/client-action`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        }
      );

      if (!response.ok) {
        const errData = await response.json();
        throw new Error(errData.detail || "Erro ao processar ação.");
      }

      setFinalDecision(action);
      setSubmitted(true);
      toast.success(
        action === "approve"
          ? "Orçamento aprovado com sucesso!"
          : "Solicitação de revisão enviada."
      );
    } catch (err) {
      console.error(err);
      toast.error(`Erro: ${err.message}`);
    } finally {
      setSubmitting(false);
    }
  };

  const handleDownload = async () => {
    try {
      const response = await fetch(
        `${API_BASE_URL}/rcm/${issue_number}/download`
      );
      if (!response.ok) throw new Error("Erro ao baixar arquivo.");

      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `RCM_${issue_number}.docx`;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
    } catch (err) {
      toast.error("Não foi possível baixar o arquivo.");
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-[#047081] flex justify-center items-center">
        <div className="animate-spin rounded-full h-16 w-16 border-b-4 border-white"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-[#047081] flex justify-center items-center p-4">
        <div className="bg-white shadow-2xl p-8 rounded-2xl max-w-lg text-center">
          <AlertTriangle className="w-16 h-16 text-red-500 mx-auto mb-6" />
          <h1 className="text-2xl font-bold text-gray-800 mb-2">
            Proposta Indisponível
          </h1>
          <p className="text-gray-600 mb-6">{error}</p>
          <button
            onClick={() => window.location.reload()}
            className="px-6 py-2 bg-gray-100 hover:bg-gray-200 text-gray-800 rounded-lg font-medium transition-colors"
          >
            Tentar Novamente
          </button>
        </div>
      </div>
    );
  }

  if (submitted) {
    return (
      <div className="min-h-screen bg-[#047081] flex justify-center items-center p-4">
        <div className="bg-white p-12 rounded-3xl shadow-2xl max-w-lg text-center animate-fade-in-up">
          <div className="mb-8 flex justify-center">
            {finalDecision === "approve" ? (
              <div className="h-28 w-28 bg-teal-50 rounded-full flex items-center justify-center animate-bounce-short">
                <CheckCircle className="w-16 h-16 text-[#047081]" />
              </div>
            ) : (
              <div className="h-28 w-28 bg-orange-50 rounded-full flex items-center justify-center animate-bounce-short">
                <Clock className="w-16 h-16 text-orange-500" />
              </div>
            )}
          </div>
          <h1 className="text-3xl font-bold text-gray-900 mb-4">
            {finalDecision === "approve"
              ? "Aprovação Confirmada!"
              : "Solicitação Enviada"}
          </h1>
          <p className="text-gray-600 mb-10 text-lg leading-relaxed">
            {finalDecision === "approve"
              ? "Obrigado por aprovar o orçamento. Nossa equipe iniciará o desenvolvimento imediatamente."
              : "Sua solicitação de revisão foi enviada para nosso analista. Entraremos em contato em breve."}
          </p>
          <div className="inline-block px-4 py-2 bg-gray-50 rounded-full text-sm text-gray-500 font-mono border border-gray-100">
            Protocolo: #{issue_number}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#047081] font-sans text-gray-800 pb-12 transition-colors duration-500">
      {/* Top Bar - Transparent/Minimalist */}
      <div className="w-full px-6 py-6 flex justify-between items-center text-white">
        <div className="flex items-center gap-3">
          <div className="bg-white/10 p-2 rounded-xl backdrop-blur-md border border-white/10">
            <Box size={24} className="text-white" />
          </div>
          <div>
            <h1 className="text-xl font-bold leading-none tracking-tight">
              Portal do Cliente
            </h1>
            <p className="text-xs text-white/80 uppercase tracking-widest mt-1 font-medium">
              Aprovação de Projetos
            </p>
          </div>
        </div>
        <div className="hidden md:flex items-center gap-4 text-right">
          <div>
            <div className="text-lg font-semibold">{details.title}</div>
            <div className="text-sm text-white/70">Demanda #{issue_number}</div>
          </div>
          <button
            onClick={() => window.open(`/validacao/${issue_number}`, "_blank")}
            className="bg-white/10 hover:bg-white/20 text-white border border-white/20 px-4 py-2 rounded-lg transition-colors flex items-center gap-2 text-sm font-medium backdrop-blur-sm"
            title="Abrir visualização do analista em nova aba"
          >
            <span>🛠️</span> Ver como Analista
          </button>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 md:px-6 grid grid-cols-1 lg:grid-cols-12 gap-8 mt-4">
        {/* Left Column: Content (8 cols) */}
        <div className="lg:col-span-8 space-y-6">
          {/* Dashboard Cards Row */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* Card 1 */}
            <div className="bg-white rounded-2xl p-6 shadow-lg shadow-teal-900/10 flex flex-col items-center text-center transform hover:-translate-y-1 transition-transform duration-300">
              <div className="bg-teal-50 p-3 rounded-full mb-3">
                <Box className="w-6 h-6 text-[#047081]" />
              </div>
              <span className="text-xs text-gray-500 font-bold uppercase tracking-wider mb-1">
                Tamanho
              </span>
              <span className="text-3xl font-extrabold text-gray-900">
                {details.pontos_funcao}{" "}
                <span className="text-sm font-medium text-gray-400">PF</span>
              </span>
            </div>

            {/* Card 2 */}
            <div className="bg-white rounded-2xl p-6 shadow-lg shadow-teal-900/10 flex flex-col items-center text-center transform hover:-translate-y-1 transition-transform duration-300">
              <div className="bg-purple-50 p-3 rounded-full mb-3">
                <Calendar className="w-6 h-6 text-purple-600" />
              </div>
              <span className="text-xs text-gray-500 font-bold uppercase tracking-wider mb-1">
                Prazo
              </span>
              <span className="text-3xl font-extrabold text-gray-900">
                {details.prazo_dias}{" "}
                <span className="text-sm font-medium text-gray-400">dias</span>
              </span>
            </div>

            {/* Card 3 */}
            <div className="bg-white rounded-2xl p-6 shadow-lg shadow-teal-900/10 flex flex-col items-center text-center transform hover:-translate-y-1 transition-transform duration-300">
              <div className="bg-emerald-50 p-3 rounded-full mb-3">
                <DollarSign className="w-6 h-6 text-emerald-600" />
              </div>
              <span className="text-xs text-gray-500 font-bold uppercase tracking-wider mb-1">
                Investimento
              </span>
              <span className="text-2xl font-extrabold text-gray-900 truncate w-full px-2">
                R${" "}
                {details.custo_total.toLocaleString("pt-BR", {
                  minimumFractionDigits: 2,
                })}
              </span>
            </div>
          </div>

          {/* Document Viewer */}
          <div className="bg-white rounded-3xl shadow-xl shadow-teal-900/20 overflow-hidden">
            <div className="bg-gray-50/50 px-8 py-6 border-b border-gray-100 flex justify-between items-center">
              <div className="flex items-center gap-3">
                <div className="bg-white p-2 rounded-lg shadow-sm border border-gray-100">
                  <FileText size={20} className="text-[#047081]" />
                </div>
                <div>
                  <h3 className="font-bold text-gray-800">
                    Memória de Cálculo
                  </h3>
                  <p className="text-xs text-gray-500">
                    Documento Técnico RCM-{issue_number}
                  </p>
                </div>
              </div>
              <button
                onClick={handleDownload}
                className="flex items-center gap-2 px-4 py-2 bg-white border border-gray-200 rounded-lg text-sm font-semibold text-gray-600 hover:text-[#047081] hover:border-[#047081] transition-all shadow-sm hover:shadow-md"
              >
                <Download size={16} />
                Baixar PDF
              </button>
            </div>
            <div className="p-10 prose prose-slate max-w-none prose-headings:text-gray-800 prose-p:text-gray-600 prose-strong:text-gray-900 prose-a:text-[#047081]">
              <ReactMarkdown>{details.rcm_text}</ReactMarkdown>
            </div>
          </div>
        </div>

        {/* Right Column: Actions & History (4 cols) */}
        <div className="lg:col-span-4 space-y-6">
          {/* Action Card - Sticky */}
          <div className="bg-white rounded-3xl shadow-xl shadow-teal-900/20 p-8 sticky top-6">
            <h2 className="text-xl font-bold text-gray-900 mb-2">
              Decisão do Cliente
            </h2>
            <p className="text-sm text-gray-500 mb-8 leading-relaxed">
              Revise os detalhes ao lado. Ao aprovar, o projeto seguirá
              automaticamente para a esteira de desenvolvimento.
            </p>

            {!showRejectReason ? (
              <div className="space-y-4">
                <button
                  onClick={() => handleAction("approve")}
                  disabled={submitting}
                  className="w-full py-4 px-6 bg-[#047081] hover:bg-[#035e6b] text-white font-bold rounded-xl shadow-lg shadow-teal-500/30 transition-all transform hover:-translate-y-1 flex items-center justify-center gap-3 text-lg"
                >
                  {submitting ? (
                    "Processando..."
                  ) : (
                    <>
                      <CheckCircle size={24} />
                      Aprovar Agora
                    </>
                  )}
                </button>
                <button
                  onClick={() => setShowRejectReason(true)}
                  disabled={submitting}
                  className="w-full py-4 px-6 bg-white border-2 border-gray-100 text-gray-600 font-bold rounded-xl hover:bg-gray-50 hover:border-gray-200 transition-all flex items-center justify-center gap-3"
                >
                  <XCircle size={20} />
                  Solicitar Ajustes
                </button>
              </div>
            ) : (
              <div className="animate-fade-in">
                <label className="block text-sm font-bold text-gray-700 mb-2">
                  O que precisa ser ajustado?
                </label>
                <textarea
                  value={rejectReason}
                  onChange={(e) => setRejectReason(e.target.value)}
                  className="w-full bg-gray-50 border border-gray-200 rounded-xl p-4 text-gray-800 focus:border-[#047081] focus:ring-2 focus:ring-[#047081]/20 outline-none transition-all mb-4 text-sm resize-none"
                  rows="5"
                  placeholder="Descreva suas observações..."
                  autoFocus
                ></textarea>
                <div className="flex gap-3">
                  <button
                    onClick={() => setShowRejectReason(false)}
                    className="flex-1 py-3 text-gray-500 hover:text-gray-800 text-sm font-bold bg-gray-100 rounded-lg transition-colors"
                  >
                    Voltar
                  </button>
                  <button
                    onClick={() => handleAction("reject")}
                    disabled={submitting}
                    className="flex-1 py-3 bg-red-500 hover:bg-red-600 text-white font-bold rounded-lg text-sm shadow-lg shadow-red-500/30 transition-all"
                  >
                    {submitting ? "Enviando..." : "Devolver"}
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* History Timeline */}
          <div className="bg-white/10 backdrop-blur-md rounded-3xl p-6 border border-white/20">
            <div className="flex items-center gap-3 mb-6 text-white">
              <History size={20} />
              <h3 className="font-bold text-lg">Linha do Tempo</h3>
            </div>

            <div className="space-y-6 relative before:absolute before:inset-0 before:ml-2.5 before:-translate-x-px before:h-full before:w-0.5 before:bg-white/20">
              {details.history && details.history.length > 0 ? (
                details.history.map((item, index) => (
                  <div key={index} className="relative flex items-start group">
                    <div
                      className={`absolute left-0 h-5 w-5 rounded-full border-2 border-[#047081] shadow-sm z-10 ${
                        item.action.includes("Aprovado") ||
                        item.action.includes("Validado")
                          ? "bg-white"
                          : item.action.includes("Rejeitado")
                          ? "bg-red-400 border-red-400"
                          : "bg-blue-400 border-blue-400"
                      }`}
                    ></div>
                    <div className="ml-8 text-white">
                      <div className="flex flex-col mb-1">
                        <span className="font-bold text-sm">{item.action}</span>
                        <span className="text-xs text-white/60">
                          {new Date(item.date).toLocaleDateString()} às{" "}
                          {new Date(item.date).toLocaleTimeString([], {
                            hour: "2-digit",
                            minute: "2-digit",
                          })}
                        </span>
                      </div>
                      <p className="text-xs text-white/80 mb-2">
                        por {item.user}
                      </p>
                      {item.comments && (
                        <div className="text-xs text-gray-800 bg-white/90 p-3 rounded-lg shadow-sm italic">
                          "{item.comments}"
                        </div>
                      )}
                    </div>
                  </div>
                ))
              ) : (
                <div className="text-sm text-white/50 text-center py-4">
                  Nenhum histórico registrado.
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ClientApproval;
