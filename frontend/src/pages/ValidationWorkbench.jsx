// frontend/src/pages/ValidationWorkbench.jsx

import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { toast } from "react-toastify"; // Usaremos para notificações
import Select from "react-select"; // Vamos instalar para campos de seleção bonitos
import CreatableSelect from "react-select/creatable"; // Para RCMs que podem ser novas
import ReactMarkdown from "react-markdown";
import HistoryTable from "../components/HistoryTable"; // Novo componente
import { API_BASE_URL } from "../config";

const ValidationWorkbench = () => {
  const { issue_number } = useParams(); // Pega o número da issue da URL
  const navigate = useNavigate();

  // Estados para os detalhes da issue original (somente leitura)
  const [issueDetails, setIssueDetails] = useState(null);
  const [loadingIssue, setLoadingIssue] = useState(true);
  const [errorIssue, setErrorIssue] = useState(null);

  // Estados para os dados validados pelo analista (editáveis)
  const [tipoSolicitacao, setTipoSolicitacao] = useState("");
  const [prioridade, setPrioridade] = useState("");
  const [esforcoEstimado, setEsforcoEstimado] = useState("");
  const [rcmsRelacionadas, setRcmsRelacionadas] = useState([]); // Array de objetos { value, label }
  const [rcmDraft, setRcmDraft] = useState(null); // Estado para o rascunho de RCM
  const [comentariosValidacao, setComentariosValidacao] = useState("");
  const [clientEmail, setClientEmail] = useState(""); // Novo estado para e-mail do cliente
  const [emailStatus, setEmailStatus] = useState(null); // 'sent', 'simulated', 'error', 'not_configured'

  const [submitting, setSubmitting] = useState(false); // Estado para o botão de aprovação
  const [generatedLink, setGeneratedLink] = useState(null); // Estado para mostrar o link gerado

  // --- NOVOS ESTADOS PARA HISTÓRICO ---
  const [activeTab, setActiveTab] = useState("pending"); // 'pending' ou 'history'
  const [historyIssues, setHistoryIssues] = useState([]);
  const [loadingHistory, setLoadingHistory] = useState(false);

  // Busca o histórico quando a aba é ativada
  useEffect(() => {
    if (activeTab === "history" && historyIssues.length === 0) {
      const fetchHistory = async () => {
        setLoadingHistory(true);
        try {
          const response = await fetch(`${API_BASE_URL}/validacao/history`);
          if (!response.ok) throw new Error("Erro ao buscar histórico");
          const data = await response.json();
          setHistoryIssues(data);
        } catch (error) {
          console.error("Erro no histórico:", error);
          toast.error("Não foi possível carregar o histórico.");
        } finally {
          setLoadingHistory(false);
        }
      };
      fetchHistory();
    }
  }, [activeTab, historyIssues.length]);

  // Opções para os Selects (devem estar em sync com os Enums do backend)
  const tipoOptions = [
    { value: "Evolutiva", label: "Evolutiva" },
    { value: "Operação", label: "Operação" },
    { value: "Corretiva", label: "Corretiva" },
    { value: "Garantia", label: "Garantia" },
    { value: "Migração", label: "Migração" },
    { value: "Correção de dados", label: "Correção de dados" },
    {
      value: "Transferencia Conhecimento",
      label: "Transferência de Conhecimento",
    },
  ];

  const prioridadeOptions = [
    { value: "Baixa", label: "Baixa" },
    { value: "Média", label: "Média" },
    { value: "Alta", label: "Alta" },
    { value: "Crítica", label: "Crítica" },
  ];

  // Função para buscar os detalhes da issue (mock ou do backend real)
  useEffect(() => {
    const fetchIssueDetails = async () => {
      setLoadingIssue(true);
      setErrorIssue(null);
      try {
        // --- BUSCA REAL DO BACKEND ---
        const response = await fetch(
          `${API_BASE_URL}/validacao/issues/${issue_number}`
        );

        if (!response.ok) {
          if (response.status === 404) {
            throw new Error("Demanda não encontrada.");
          }
          throw new Error(`Erro ao carregar issue: ${response.status}`);
        }

        const issue = await response.json();
        setIssueDetails(issue);

        setRcmDraft(issue.rcm_draft || null); // Carrega o rascunho se existir

        // Tenta pré-preencher com dados da descrição se a IA já tiver analisado
        // (Lógica simples de regex ou apenas defaults por enquanto)
        setTipoSolicitacao("Melhoria");
        setPrioridade("Média");
        setEsforcoEstimado("");
        setRcmsRelacionadas([]);
        setComentariosValidacao("");
      } catch (err) {
        console.error("Erro ao buscar detalhes da issue:", err);
        setErrorIssue("Não foi possível carregar os detalhes da demanda.");
      } finally {
        setLoadingIssue(false);
      }
    };

    fetchIssueDetails();
  }, [issue_number]);

  // Função para lidar com a submissão do formulário
  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setErrorIssue(null);
    setGeneratedLink(null);

    const payload = {
      tipo_solicitacao: tipoSolicitacao,
      prioridade: prioridade,
      esforco_estimado: parseFloat(esforcoEstimado) || null, // Garante que seja float ou null
      rcms_relacionadas: rcmsRelacionadas.map((rcm) => rcm.value), // Extrai apenas os valores
      comentarios_validacao: comentariosValidacao,
      rcm_draft: rcmDraft, // Envia o rascunho editado
    };

    // Determina se é fluxo de RCM de forma consistente
    // Considera RCM se tiver a label OU se tiver um rascunho de RCM carregado (permitindo edição mesmo se label sumir)
    const isRcmMode =
      (issueDetails.labels &&
        issueDetails.labels.includes("status:aguardando-validacao-rcm")) ||
      (rcmDraft && rcmDraft.length > 0);

    try {
      let response;

      if (isRcmMode) {
        // --- FLUXO RCM ---
        const rcmPayload = {
          final_rcm_text: rcmDraft,
          analyst_comments: comentariosValidacao,
          client_email: clientEmail || null, // Envia o e-mail se preenchido
        };

        response = await fetch(`${API_BASE_URL}/rcm/${issue_number}/approve`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(rcmPayload),
        });
      } else {
        // --- FLUXO PADRÃO ---
        response = await fetch(
          `${API_BASE_URL}/validacao/${issue_number}/approve`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(payload),
          }
        );
      }

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || `Erro API: ${response.status}`);
      }

      const data = await response.json();
      toast.success(`Demanda #${issue_number} validada com sucesso!`);

      // Se for RCM, mostra o link gerado antes de sair
      if (isRcmMode) {
        const link = `${window.location.origin}/cliente/aprovacao/${issue_number}`;
        setGeneratedLink(link);
        if (data.email_status) {
          setEmailStatus(data.email_status);
        }
        // Não navega imediatamente para dar tempo de copiar o link
      } else {
        navigate("/validacao");
      }
    } catch (err) {
      console.error("Erro ao aprovar validação:", err);
      toast.error(`Falha ao validar demanda: ${err.message}`);
      setErrorIssue(err.message);
    } finally {
      setSubmitting(false);
    }
  };

  if (loadingIssue) {
    return (
      <div className="page-content flex justify-center items-center h-full">
        <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-cyan-500"></div>
        <p className="ml-4 text-slate-400">Carregando demanda...</p>
      </div>
    );
  }

  if (errorIssue && !issueDetails) {
    // Mostrar erro se não conseguiu carregar a issue
    return (
      <div className="page-content card bg-red-900/20 border-red-900 text-red-400 p-6 text-center">
        <h3 className="font-bold text-lg mb-2">Erro</h3>
        <p>{errorIssue}</p>
        <button
          onClick={() => navigate("/validacao")}
          className="mt-4 underline hover:text-red-300"
        >
          Voltar para o Backlog
        </button>
      </div>
    );
  }

  if (!issueDetails) {
    // Caso a issue não seja encontrada (ex: URL inválida)
    return (
      <div className="page-content card bg-orange-900/20 border-orange-900 text-orange-400 p-6 text-center">
        <h3 className="font-bold text-lg mb-2">Demanda Não Encontrada</h3>
        <p>A demanda com o número #{issue_number} não foi localizada.</p>
        <button
          onClick={() => navigate("/validacao")}
          className="mt-4 underline hover:text-orange-300"
        >
          Voltar para o Backlog
        </button>
      </div>
    );
  }

  if (generatedLink) {
    return (
      <div className="page-content flex flex-col items-center justify-center h-full text-center space-y-6">
        <div className="bg-emerald-900/20 border border-emerald-500/50 p-8 rounded-xl max-w-2xl w-full shadow-2xl">
          <div className="text-6xl mb-4">✅</div>
          <h2 className="text-3xl font-bold text-white mb-2">
            RCM Aprovada com Sucesso!
          </h2>
          <p className="text-slate-300 mb-6 text-lg">
            A demanda foi movida para a fase de aprovação do cliente.
          </p>

          <div className="bg-slate-900 p-4 rounded-lg border border-slate-700 mb-6">
            <label className="block text-xs text-slate-500 uppercase font-bold mb-2 text-left">
              Link para o Cliente:
            </label>
            <div className="flex items-center gap-2">
              <input
                type="text"
                value={generatedLink}
                readOnly
                className="w-full bg-transparent text-cyan-400 font-mono text-sm outline-none"
              />
              <button
                onClick={() => {
                  navigator.clipboard.writeText(generatedLink);
                  toast.success("Link copiado!");
                }}
                className="text-slate-400 hover:text-white p-2"
                title="Copiar Link"
              >
                📋
              </button>
            </div>
          </div>

          {clientEmail && (
            <div
              className={`p-4 rounded-lg border mb-6 text-left flex items-start gap-3 ${
                emailStatus === "sent"
                  ? "bg-blue-900/20 border-blue-700/50"
                  : emailStatus === "simulated"
                  ? "bg-yellow-900/20 border-yellow-700/50"
                  : "bg-red-900/20 border-red-700/50"
              }`}
            >
              <span className="text-2xl">
                {emailStatus === "sent"
                  ? "📧"
                  : emailStatus === "simulated"
                  ? "⚠️"
                  : "❌"}
              </span>
              <div>
                <h4
                  className={`font-bold ${
                    emailStatus === "sent"
                      ? "text-blue-300"
                      : emailStatus === "simulated"
                      ? "text-yellow-300"
                      : "text-red-300"
                  }`}
                >
                  {emailStatus === "sent"
                    ? "E-mail Enviado"
                    : emailStatus === "simulated"
                    ? "Modo Simulação (E-mail Não Enviado)"
                    : "Falha no Envio"}
                </h4>
                <p
                  className={`text-sm ${
                    emailStatus === "sent"
                      ? "text-blue-200"
                      : emailStatus === "simulated"
                      ? "text-yellow-200"
                      : "text-red-200"
                  }`}
                >
                  {emailStatus === "sent"
                    ? `Uma notificação foi enviada para ${clientEmail}.`
                    : emailStatus === "simulated"
                    ? `O sistema simulou o envio para ${clientEmail}. Verifique os logs do backend.`
                    : `Houve um erro ao tentar enviar para ${clientEmail}.`}
                </p>
              </div>
            </div>
          )}

          <div className="flex gap-4 justify-center">
            <button
              onClick={() => navigate("/validacao")}
              className="bg-slate-700 hover:bg-slate-600 text-white font-bold py-3 px-8 rounded-lg transition-colors"
            >
              Voltar para o Backlog
            </button>
            <button
              onClick={() =>
                window.open(`/cliente/aprovacao/${issue_number}`, "_blank")
              }
              className="bg-cyan-600 hover:bg-cyan-500 text-white font-bold py-3 px-8 rounded-lg transition-colors flex items-center gap-2"
            >
              <span>👁️</span> Ver como Cliente
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="page-content flex flex-col h-full">
      <div className="flex justify-between items-start mb-6">
        <header className="page-header mb-0">
          <h1>
            ✨ Workbench de Validação{" "}
            <span className="text-cyan-400">#{issueDetails.number}</span>
          </h1>
          <p className="text-slate-400">
            Revise e aprove a análise da IA para a demanda selecionada.
          </p>
        </header>
        <button
          onClick={() =>
            window.open(`/cliente/aprovacao/${issue_number}`, "_blank")
          }
          className="mt-2 text-sm bg-slate-800 hover:bg-slate-700 text-cyan-400 border border-cyan-900/30 px-4 py-2 rounded-lg transition-colors flex items-center gap-2 shadow-lg"
          title="Abrir visualização do cliente em nova aba"
        >
          <span>👁️</span> Ver como Cliente
        </button>
      </div>

      {/* --- NAVEGAÇÃO POR ABAS --- */}
      <div className="flex space-x-4 mb-6 border-b border-slate-700">
        <button
          onClick={() => setActiveTab("pending")}
          className={`pb-2 px-4 font-medium transition-colors ${
            activeTab === "pending"
              ? "text-cyan-400 border-b-2 border-cyan-400"
              : "text-slate-400 hover:text-slate-200"
          }`}
        >
          Validação Atual (Pendente)
        </button>
        <button
          onClick={() => setActiveTab("history")}
          className={`pb-2 px-4 font-medium transition-colors ${
            activeTab === "history"
              ? "text-cyan-400 border-b-2 border-cyan-400"
              : "text-slate-400 hover:text-slate-200"
          }`}
        >
          Histórico de Validações
        </button>
      </div>

      {/* --- CONTEÚDO DA ABA: HISTÓRICO --- */}
      {activeTab === "history" && (
        <div className="grow overflow-auto">
          {loadingHistory ? (
            <div className="flex justify-center items-center h-32">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-cyan-500"></div>
            </div>
          ) : (
            <HistoryTable
              issues={historyIssues}
              onIssueUpdate={() => {
                setHistoryIssues([]); // Força recarregamento
              }}
            />
          )}
        </div>
      )}

      {/* --- CONTEÚDO DA ABA: PENDENTE (Formulário Original) --- */}
      {activeTab === "pending" && (
        <form onSubmit={handleSubmit} className="grow flex flex-col space-y-6">
          {/* Botão de Atualizar */}
          <div className="flex justify-end">
            <button
              type="button"
              onClick={() => {
                setLoadingIssue(true);
                // Simula um refresh recarregando os dados
                setTimeout(() => {
                  window.location.reload();
                }, 500);
              }}
              className="text-sm text-cyan-400 hover:text-cyan-300 flex items-center gap-1"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={1.5}
                stroke="currentColor"
                className="w-4 h-4"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99"
                />
              </svg>
              Atualizar
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 grow">
            {/* Coluna Esquerda: Detalhes da Demanda Original (Read-only) */}
            <div className="card bg-slate-800/50 p-6 flex flex-col h-full">
              <h2 className="text-xl font-semibold text-slate-200 mb-4">
                Demanda Original (GitHub)
              </h2>
              <div className="grow overflow-y-auto pr-2">
                <h3 className="text-lg font-bold text-slate-300 mb-2">
                  {issueDetails.title}
                </h3>
                <div className="text-slate-400 text-sm prose prose-invert max-w-none">
                  <ReactMarkdown>
                    {issueDetails.body || "Sem descrição."}
                  </ReactMarkdown>
                </div>
              </div>
              <div className="mt-4 pt-4 border-t border-slate-700">
                {/* Extração de Métricas da Análise da IA (se houver) */}
                {(() => {
                  // Tenta encontrar o comentário da IA com as estimativas
                  const aiComment = issueDetails.comments?.find((c) =>
                    c.body.includes("## 🤖 Análise Automática de Requisitos")
                  );

                  if (aiComment) {
                    // Regex robusto para extrair os valores (suporta variações de prompt)
                    // Tenta capturar:
                    // **Estimativa de Pontos de Função (PF):** 10
                    // **Pontos de Função:** 10
                    const pfMatch = aiComment.body.match(
                      /\*\*(?:Estimativa de )?Pontos de Função(?: \(PF\))?:?\*\*\s*([\d\.,]+)/i
                    );

                    // Tenta capturar:
                    // **Prazo Estimado:** 15 dias
                    // **Prazo:** 15
                    const prazoMatch = aiComment.body.match(
                      /\*\*(?:Prazo Estimado|Prazo):?\*\*\s*(\d+)/i
                    );

                    const pf = pfMatch ? pfMatch[1] : "N/A";
                    const prazo = prazoMatch ? prazoMatch[1] : "N/A";

                    return (
                      <div className="grid grid-cols-2 gap-4 mb-4 bg-slate-900/50 p-3 rounded">
                        <div>
                          <span className="block text-xs text-slate-400 uppercase font-bold">
                            Pontos de Função
                          </span>
                          <span className="text-lg text-cyan-400 font-mono">
                            {pf}
                          </span>
                        </div>
                        <div>
                          <span className="block text-xs text-slate-400 uppercase font-bold">
                            Prazo (Dias Úteis)
                          </span>
                          <span className="text-lg text-cyan-400 font-mono">
                            {prazo}
                          </span>
                        </div>
                      </div>
                    );
                  }
                  return null;
                })()}

                <div className="text-sm text-right mt-4">
                  <a
                    href={issueDetails.html_url}
                    target="_blank"
                    rel="noreferrer"
                    className="text-cyan-500 hover:underline"
                  >
                    Abrir no GitHub &rarr;
                  </a>
                </div>
              </div>

              {/* Seção de Análise da IA (Visualização) */}
              {rcmDraft && (
                <div className="mt-6 pt-4 border-t border-slate-700">
                  <h3 className="text-lg font-bold text-slate-300 mb-2">
                    🤖 Análise da IA (RCM Preliminar)
                  </h3>
                  <div className="bg-slate-900/50 p-4 rounded text-slate-400 text-sm prose prose-invert max-w-none max-h-64 overflow-y-auto">
                    <ReactMarkdown>{rcmDraft}</ReactMarkdown>
                  </div>
                </div>
              )}

              {/* Seção de Feedback do Cliente (Se houver rejeição) */}
              {(() => {
                const rejectionComment = issueDetails.comments
                  ?.slice()
                  .reverse()
                  .find((c) =>
                    c.body.includes("⚠️ **RCM Devolvida pelo Cliente**")
                  );
                if (rejectionComment) {
                  const reason =
                    rejectionComment.body.split("**Motivo:**")[1]?.trim() ||
                    rejectionComment.body;
                  return (
                    <div className="mt-6 p-4 bg-red-900/20 border border-red-700/50 rounded-lg animate-pulse">
                      <h3 className="text-lg font-bold text-red-400 mb-2 flex items-center gap-2">
                        <span>⚠️</span> Atenção: RCM Devolvida pelo Cliente
                      </h3>
                      <p className="text-slate-300 text-sm italic">
                        "{reason}"
                      </p>
                      <p className="text-xs text-red-400 mt-2 font-bold">
                        Por favor, ajuste o RCM com base neste feedback e
                        reenvie para aprovação.
                      </p>
                    </div>
                  );
                }
                return null;
              })()}
            </div>

            {/* Coluna Direita: Análise da IA para Validação (Editável) */}
            <div className="card p-6 flex flex-col h-full">
              <h2 className="text-xl font-semibold text-slate-200 mb-4">
                {issueDetails.labels &&
                issueDetails.labels.includes("status:aguardando-liberacao-dev")
                  ? "⚡ Modo Fast Track (Correção/Esforço)"
                  : issueDetails.labels &&
                    issueDetails.labels.includes(
                      "status:aguardando-validacao-rcm"
                    ) &&
                    rcmDraft
                  ? "Revisão de RCM (IA)"
                  : "Análise da IA (Revisar e Ajustar)"}
              </h2>
              <div className="grow overflow-y-auto pr-2 space-y-4">
                {issueDetails.labels &&
                issueDetails.labels.includes(
                  "status:aguardando-liberacao-dev"
                ) ? (
                  // --- MODO FAST TRACK ---
                  <div className="flex flex-col h-full justify-center items-center text-center space-y-6">
                    <div className="bg-emerald-900/30 p-6 rounded-lg border border-emerald-700/50">
                      <h3 className="text-lg font-bold text-emerald-400 mb-2">
                        Demanda de Correção / Esforço Direto
                      </h3>
                      <p className="text-slate-300 mb-4">
                        Esta demanda foi classificada como uma correção rápida
                        ou tarefa de esforço direto.
                        <br />
                        <strong>
                          Não requer fluxo completo de RCM ou aprovação do
                          cliente.
                        </strong>
                      </p>
                      <p className="text-sm text-slate-400">
                        Revise a descrição ao lado e, se estiver de acordo,
                        libere diretamente para a fila de desenvolvimento.
                      </p>
                    </div>

                    <button
                      type="button"
                      onClick={async () => {
                        if (
                          window.confirm(
                            "Confirmar liberação direta para desenvolvimento?"
                          )
                        ) {
                          setSubmitting(true);
                          try {
                            const response = await fetch(
                              `${API_BASE_URL}/workflow/${issue_number}/release-fast-track`,
                              {
                                method: "POST",
                              }
                            );
                            if (!response.ok) throw new Error("Erro na API");
                            toast.success(
                              "🚀 Fast Track liberado com sucesso!"
                            );
                            navigate("/validacao");
                          } catch (err) {
                            toast.error("Erro ao liberar Fast Track.");
                            console.error(err);
                          } finally {
                            setSubmitting(false);
                          }
                        }
                      }}
                      disabled={submitting}
                      className="bg-emerald-600 hover:bg-emerald-500 text-white font-bold py-4 px-8 rounded-lg shadow-lg transform transition hover:scale-105 flex items-center space-x-2"
                    >
                      <span className="text-2xl">🚀</span>
                      <span>Liberar para Desenvolvimento Direto</span>
                    </button>
                  </div>
                ) : issueDetails.labels &&
                  issueDetails.labels.includes(
                    "status:aguardando-validacao-rcm"
                  ) &&
                  rcmDraft ? (
                  // --- MODO RCM: Exibe Editor de Rascunho ---
                  <div>
                    <label className="block text-slate-300 text-sm font-bold mb-2">
                      Rascunho da RCM (Edite conforme necessário):
                    </label>
                    <textarea
                      rows="15"
                      value={rcmDraft}
                      onChange={(e) => setRcmDraft(e.target.value)}
                      className="shadow appearance-none border rounded w-full py-2 px-3 text-slate-200 leading-tight focus:outline-none focus:shadow-outline bg-slate-800 border-slate-600 focus:border-cyan-500 font-mono text-sm"
                    ></textarea>

                    {/* Botões de Download (Fase 6.3.1) */}
                    <div className="mt-2 text-right space-y-1">
                      <div>
                        <button
                          type="button"
                          onClick={() =>
                            window.open(
                              `${API_BASE_URL}/rcm/${issue_number}/download-memoria`,
                              "_blank"
                            )
                          }
                          className="text-sm text-emerald-400 hover:text-emerald-300 underline inline-flex items-center gap-1"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                            strokeWidth={1.5}
                            stroke="currentColor"
                            className="w-4 h-4"
                          >
                            <path
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              d="M3.375 19.5h17.25m-17.25 0a1.125 1.125 0 0 1-1.125-1.125M3.375 19.5h7.5c.621 0 1.125-.504 1.125-1.125m-9.75 0V5.625m0 12.75v-1.5c0-.621.504-1.125 1.125-1.125m18.375 2.625V5.625m0 12.75c0 .621-.504 1.125-1.125 1.125m1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125m0 3.75h-7.5A1.125 1.125 0 0 1 12 18.375m9.75-12.75c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125m19.5 0v1.5c0 .621-.504 1.125-1.125 1.125M2.25 5.625v1.5c0 .621.504 1.125 1.125 1.125m0 0h17.25m-17.25 0h7.5c.621 0 1.125.504 1.125 1.125M3.375 8.25c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125m17.25-3.75h-7.5c-.621 0-1.125.504-1.125 1.125m8.625-1.125c.621 0 1.125.504 1.125 1.125v1.5c0 .621-.504 1.125-1.125 1.125m-17.25 0h7.5m-7.5 0c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125M12 10.875v-1.5m0 1.5c0 .621-.504 1.125-1.125 1.125M12 10.875c0 .621.504 1.125 1.125 1.125m-2.25 0c.621 0 1.125.504 1.125 1.125M13.125 12h7.5m-7.5 0c-.621 0-1.125.504-1.125 1.125M20.625 12c.621 0 1.125.504 1.125 1.125v1.5c0 .621-.504 1.125-1.125 1.125m-17.25 0h7.5M12 14.625v-1.5m0 1.5c0 .621-.504 1.125-1.125 1.125M12 14.625c0 .621.504 1.125 1.125 1.125m-2.25 0c.621 0 1.125.504 1.125 1.125m0 1.5v-1.5m0 1.5c0 .621-.504 1.125-1.125 1.125M13.125 16.125h7.5"
                            />
                          </svg>
                          Baixar Memória de Cálculo (XLSX)
                        </button>
                      </div>
                      <div>
                        <button
                          type="button"
                          onClick={() =>
                            window.open(
                              `${API_BASE_URL}/docs/rcm/${issue_number}/download`,
                              "_blank"
                            )
                          }
                          className="text-sm text-cyan-400 hover:text-cyan-300 underline inline-flex items-center gap-1"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                            strokeWidth={1.5}
                            stroke="currentColor"
                            className="w-4 h-4"
                          >
                            <path
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              d="M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5M16.5 12 12 16.5m0 0L7.5 12m4.5 4.5V3"
                            />
                          </svg>
                          Baixar RCM (DOCX)
                        </button>
                      </div>
                    </div>

                    {/* NOVO CAMPO: E-mail do Cliente */}
                    <div className="mt-6 pt-6 border-t border-slate-700">
                      <label className="block text-slate-300 text-sm font-bold mb-2">
                        📧 E-mail do Cliente (Opcional):
                      </label>
                      <p className="text-xs text-slate-500 mb-2">
                        Se preenchido, um link de aprovação será enviado
                        automaticamente para este endereço.
                      </p>
                      <input
                        type="email"
                        value={clientEmail}
                        onChange={(e) => setClientEmail(e.target.value)}
                        placeholder="exemplo@cliente.com"
                        className="shadow appearance-none border rounded w-full py-2 px-3 text-slate-200 leading-tight focus:outline-none focus:shadow-outline bg-slate-800 border-slate-600 focus:border-cyan-500"
                      />
                    </div>
                  </div>
                ) : (
                  // --- MODO PADRÃO: Exibe Campos de Validação ---
                  <>
                    {/* Campo: Tipo de Solicitação */}
                    <div>
                      <label className="block text-slate-300 text-sm font-bold mb-2">
                        Tipo de Solicitação:
                      </label>
                      <Select
                        options={tipoOptions}
                        value={tipoOptions.find(
                          (opt) => opt.value === tipoSolicitacao
                        )}
                        onChange={(option) =>
                          setTipoSolicitacao(option ? option.value : "")
                        }
                        placeholder="Selecione o tipo..."
                        isClearable
                        classNamePrefix="react-select"
                        styles={{
                          control: (baseStyles) => ({
                            ...baseStyles,
                            backgroundColor: "#1E293B",
                            borderColor: "#475569",
                            color: "#E2E8F0",
                          }),
                          singleValue: (baseStyles) => ({
                            ...baseStyles,
                            color: "#E2E8F0",
                          }),
                          input: (baseStyles) => ({
                            ...baseStyles,
                            color: "#E2E8F0",
                          }),
                          placeholder: (baseStyles) => ({
                            ...baseStyles,
                            color: "#94A3B8",
                          }),
                          menu: (baseStyles) => ({
                            ...baseStyles,
                            backgroundColor: "#1E293B",
                            zIndex: 9999,
                          }),
                          option: (baseStyles, state) => ({
                            ...baseStyles,
                            backgroundColor: state.isFocused
                              ? "#334155"
                              : "#1E293B",
                            color: state.isSelected ? "#06B6D4" : "#E2E8F0",
                            "&:active": {
                              backgroundColor: "#334155",
                            },
                          }),
                        }}
                      />
                    </div>
                    {/* Campo: Prioridade */}
                    <div>
                      <label className="block text-slate-300 text-sm font-bold mb-2">
                        Prioridade Sugerida:
                      </label>
                      <Select
                        options={prioridadeOptions}
                        value={prioridadeOptions.find(
                          (opt) => opt.value === prioridade
                        )}
                        onChange={(option) =>
                          setPrioridade(option ? option.value : "")
                        }
                        placeholder="Selecione a prioridade..."
                        isClearable
                        classNamePrefix="react-select"
                        styles={{
                          control: (baseStyles) => ({
                            ...baseStyles,
                            backgroundColor: "#1E293B",
                            borderColor: "#475569",
                            color: "#E2E8F0",
                          }),
                          singleValue: (baseStyles) => ({
                            ...baseStyles,
                            color: "#E2E8F0",
                          }),
                          input: (baseStyles) => ({
                            ...baseStyles,
                            color: "#E2E8F0",
                          }),
                          placeholder: (baseStyles) => ({
                            ...baseStyles,
                            color: "#94A3B8",
                          }),
                          menu: (baseStyles) => ({
                            ...baseStyles,
                            backgroundColor: "#1E293B",
                            zIndex: 9999,
                          }),
                          option: (baseStyles, state) => ({
                            ...baseStyles,
                            backgroundColor: state.isFocused
                              ? "#334155"
                              : "#1E293B",
                            color: state.isSelected ? "#06B6D4" : "#E2E8F0",
                            "&:active": { backgroundColor: "#334155" },
                          }),
                        }}
                      />
                    </div>
                    {/* Campo: Esforço Estimado */}
                    <div>
                      <label
                        htmlFor="esforco"
                        className="block text-slate-300 text-sm font-bold mb-2"
                      >
                        Esforço Estimado (horas/PF):
                      </label>
                      <input
                        type="number"
                        id="esforco"
                        value={esforcoEstimado}
                        onChange={(e) => setEsforcoEstimado(e.target.value)}
                        className="shadow appearance-none border rounded w-full py-2 px-3 text-slate-200 leading-tight focus:outline-none focus:shadow-outline bg-slate-800 border-slate-600 focus:border-cyan-500"
                        placeholder="Ex: 40.5"
                        step="0.5"
                      />
                    </div>
                    {/* Campo: RCMs Relacionadas (Creatable Select) */}
                    <div>
                      <label className="block text-slate-300 text-sm font-bold mb-2">
                        RCMs Relacionadas:
                      </label>
                      <CreatableSelect
                        isMulti
                        options={[]}
                        value={rcmsRelacionadas}
                        onChange={(newValue) => setRcmsRelacionadas(newValue)}
                        placeholder="Adicione ou selecione RCMs..."
                        classNamePrefix="react-select"
                        styles={{
                          control: (baseStyles) => ({
                            ...baseStyles,
                            backgroundColor: "#1E293B",
                            borderColor: "#475569",
                            color: "#E2E8F0",
                          }),
                          multiValue: (baseStyles) => ({
                            ...baseStyles,
                            backgroundColor: "#334155",
                            color: "#E2E8F0",
                          }),
                          multiValueLabel: (baseStyles) => ({
                            ...baseStyles,
                            color: "#E2E8F0",
                          }),
                          multiValueRemove: (baseStyles) => ({
                            ...baseStyles,
                            color: "#94A3B8",
                            "&:hover": {
                              backgroundColor: "#475569",
                              color: "#E2E8F0",
                            },
                          }),
                          singleValue: (baseStyles) => ({
                            ...baseStyles,
                            color: "#E2E8F0",
                          }),
                          input: (baseStyles) => ({
                            ...baseStyles,
                            color: "#E2E8F0",
                          }),
                          placeholder: (baseStyles) => ({
                            ...baseStyles,
                            color: "#94A3B8",
                          }),
                          menu: (baseStyles) => ({
                            ...baseStyles,
                            backgroundColor: "#1E293B",
                            zIndex: 9999,
                          }),
                          option: (baseStyles, state) => ({
                            ...baseStyles,
                            backgroundColor: state.isFocused
                              ? "#334155"
                              : "#1E293B",
                            color: state.isSelected ? "#06B6D4" : "#E2E8F0",
                            "&:active": { backgroundColor: "#334155" },
                          }),
                        }}
                      />
                    </div>
                  </>
                )}

                {/* Campo: Comentários de Validação (Comum a ambos) */}
                <div>
                  <label
                    htmlFor="comentarios"
                    className="block text-slate-300 text-sm font-bold mb-2"
                  >
                    Comentários da Validação:
                  </label>
                  <textarea
                    id="comentarios"
                    rows="4"
                    value={comentariosValidacao}
                    onChange={(e) => setComentariosValidacao(e.target.value)}
                    className="shadow appearance-none border rounded w-full py-2 px-3 text-slate-200 leading-tight focus:outline-none focus:shadow-outline bg-slate-800 border-slate-600 focus:border-cyan-500"
                    placeholder="Adicione observações ou justificativas para as alterações..."
                  ></textarea>
                </div>
              </div>
            </div>
          </div>

          {/* Rodapé com Botões de Ação */}
          <div className="flex justify-end space-x-4 pt-4 border-t border-slate-800">
            <button
              type="button"
              onClick={() => navigate("/validacao")}
              className="bg-slate-700 hover:bg-slate-600 text-white font-bold py-2 px-6 rounded shadow transition-colors"
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={submitting}
              className={`bg-cyan-600 hover:bg-cyan-700 text-white font-bold py-2 px-6 rounded shadow transition-colors ${
                submitting ? "opacity-50 cursor-not-allowed" : ""
              }`}
            >
              {submitting
                ? "Processando..."
                : issueDetails &&
                  issueDetails.labels &&
                  issueDetails.labels.includes(
                    "status:aguardando-liberacao-dev"
                  )
                ? "" // Botão oculto no modo Fast Track (tem botão próprio)
                : issueDetails &&
                  issueDetails.labels &&
                  issueDetails.labels.includes(
                    "status:aguardando-validacao-rcm"
                  ) &&
                  rcmDraft
                ? "Aprovar RCM e Enviar ao Cliente"
                : "APROVA E IMPLANTAR"}
            </button>
          </div>
        </form>
      )}
    </div>
  );
};

export default ValidationWorkbench;
