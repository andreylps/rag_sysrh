import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { toast } from "react-toastify";
import CodeReviewViewer from "../components/CodeReviewViewer";
import HistoryTable from "../components/HistoryTable"; // Novo componente
import { API_BASE_URL } from "../config";

const TechnicalWorkbench = () => {
  const navigate = useNavigate();
  const [issues, setIssues] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Estado para controlar qual issue está sendo revisada (Modo Visualização)
  // Estado para controlar qual issue está sendo revisada (Modo Visualização)
  const [selectedIssueId, setSelectedIssueId] = useState(null);

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
          const response = await fetch(`${API_BASE_URL}/review/history`);
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

  useEffect(() => {
    const fetchIssues = async () => {
      setLoading(true);
      try {
        // Usando o endpoint existente de backlog, mas o backend precisará ser ajustado
        // para incluir a label 'status:aguardando-review-tecnico'
        const response = await fetch(`${API_BASE_URL}/review/backlog`);

        if (!response.ok) {
          throw new Error("Falha ao carregar backlog técnico.");
        }

        const data = await response.json();

        // Filtrar no frontend apenas por segurança, embora o backend deva mandar as certas
        const techReviewIssues = data.filter((issue) =>
          issue.labels.includes("status:aguardando-review-tecnico")
        );

        setIssues(techReviewIssues);
      } catch (err) {
        console.error(err);
        setError(err.message);
        toast.error("Erro ao carregar demandas para revisão.");
      } finally {
        setLoading(false);
      }
    };

    fetchIssues();
  }, []);

  if (loading) {
    return (
      <div className="page-content flex justify-center items-center h-full">
        <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-cyan-500"></div>
        <p className="ml-4 text-slate-400">
          Carregando demandas para revisão...
        </p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="page-content card bg-red-900/20 border-red-900 text-red-400 p-6 text-center">
        <h3 className="font-bold text-lg mb-2">Erro</h3>
        <p>{error}</p>
      </div>
    );
  }

  // --- MODO VISUALIZAÇÃO (REVIEW) ---
  if (selectedIssueId) {
    return (
      <div className="page-content flex flex-col h-full">
        <header className="page-header mb-6 flex justify-between items-center">
          <div>
            <h1>
              Revisão Técnica{" "}
              <span className="text-purple-400">#{selectedIssueId}</span>
            </h1>
            <p className="text-slate-400">
              Analise o código gerado pela IA antes de aprovar.
            </p>
          </div>
          <button
            onClick={() => setSelectedIssueId(null)}
            className="text-slate-400 hover:text-white underline"
          >
            &larr; Voltar para Lista
          </button>
        </header>

        <div className="grow flex flex-col space-y-6">
          {/* Componente de Visualização de Código */}
          <CodeReviewViewer issueId={selectedIssueId} />

          {/* Ações de Aprovação */}
          <div className="flex justify-end space-x-4 pt-4 border-t border-slate-800">
            <button
              onClick={() =>
                toast.info("Funcionalidade de rejeição em breve...")
              }
              className="bg-red-900/50 hover:bg-red-900 text-red-200 border border-red-800 font-bold py-2 px-6 rounded shadow transition-colors"
            >
              Solicitar Correções
            </button>
            <button
              onClick={async () => {
                if (
                  !window.confirm(
                    "Tem certeza que deseja aprovar e implantar? A demanda será movida para Aceite de Homologação."
                  )
                )
                  return;

                const toastId = toast.loading("Processando aprovação...");
                try {
                  const response = await fetch(
                    `${API_BASE_URL}/review/${selectedIssueId}/deploy`,
                    {
                      method: "POST",
                    }
                  );

                  if (!response.ok) throw new Error("Falha na aprovação.");

                  toast.update(toastId, {
                    render: "✅ Aprovado! Demanda movida para Homologação.",
                    type: "success",
                    isLoading: false,
                    autoClose: 3000,
                  });

                  // Remove a issue da lista local e volta para a tela inicial
                  setIssues((prev) =>
                    prev.filter((i) => i.number !== selectedIssueId)
                  );
                  setSelectedIssueId(null);
                } catch (err) {
                  console.error(err);
                  toast.update(toastId, {
                    render: "Erro ao realizar deploy.",
                    type: "error",
                    isLoading: false,
                    autoClose: 3000,
                  });
                }
              }}
              className="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-6 rounded shadow transition-colors flex items-center"
            >
              <svg
                className="w-5 h-5 mr-2"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  d="M5 13l4 4L19 7"
                ></path>
              </svg>
              Aprovar e Implantar
            </button>

            {/* Botão de Download Memória de Cálculo (Fase 6.3.2) */}
            <button
              onClick={() =>
                window.open(
                  `${API_BASE_URL}/docs/memcalc/${selectedIssueId}/download`,
                  "_blank"
                )
              }
              className="bg-slate-700 hover:bg-slate-600 text-slate-200 border border-slate-600 font-bold py-2 px-6 rounded shadow transition-colors flex items-center"
              title="Baixar Memória de Cálculo em Excel"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={1.5}
                stroke="currentColor"
                className="w-5 h-5 mr-2 text-green-400"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"
                />
              </svg>
              Baixar Memória (XLSX)
            </button>
          </div>
        </div>
      </div>
    );
  }

  // --- MODO LISTA (BACKLOG) ---
  return (
    <div className="page-content flex flex-col h-full">
      <header className="page-header mb-6">
        <h1>Technical Workbench 🛠️</h1>
        <p className="text-slate-400">
          Revisão de Código Gerado por IA e Aprovação Técnica.
        </p>
      </header>

      {/* --- NAVEGAÇÃO POR ABAS --- */}
      <div className="flex space-x-4 mb-6 border-b border-slate-700">
        <button
          onClick={() => setActiveTab("pending")}
          className={`pb-2 px-4 font-medium transition-colors ${
            activeTab === "pending"
              ? "text-purple-400 border-b-2 border-purple-400"
              : "text-slate-400 hover:text-slate-200"
          }`}
        >
          Revisões Pendentes
        </button>
        <button
          onClick={() => setActiveTab("history")}
          className={`pb-2 px-4 font-medium transition-colors ${
            activeTab === "history"
              ? "text-purple-400 border-b-2 border-purple-400"
              : "text-slate-400 hover:text-slate-200"
          }`}
        >
          Histórico de Revisões
        </button>
      </div>

      {/* --- CONTEÚDO DA ABA: HISTÓRICO --- */}
      {activeTab === "history" && (
        <div className="grow overflow-auto">
          {loadingHistory ? (
            <div className="flex justify-center items-center h-32">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-500"></div>
            </div>
          ) : (
            <HistoryTable
              issues={historyIssues}
              onIssueUpdate={() => {
                // Força recarregamento do histórico
                setHistoryIssues([]); // Limpa para forçar o useEffect a buscar novamente
              }}
            />
          )}
        </div>
      )}

      {/* --- CONTEÚDO DA ABA: PENDENTE (Lista Original) --- */}
      {activeTab === "pending" && (
        <div className="grow overflow-auto">
          <div className="flex justify-end mb-4">
            <button
              type="button"
              onClick={() => {
                setLoading(true);
                // Simula um refresh recarregando a página
                setTimeout(() => {
                  window.location.reload();
                }, 500);
              }}
              className="text-sm text-purple-400 hover:text-purple-300 flex items-center gap-1"
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
          {issues.length === 0 ? (
            <div className="card bg-slate-800/50 p-12 text-center border-dashed border-2 border-slate-700">
              <div className="text-6xl mb-4">✅</div>
              <h3 className="text-xl font-semibold text-slate-300 mb-2">
                Tudo Limpo!
              </h3>
              <p className="text-slate-500">
                Nenhuma demanda aguardando revisão técnica no momento.
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-4">
              {issues.map((issue) => (
                <div
                  key={issue.number}
                  className="card p-6 hover:bg-slate-800 transition-colors border-l-4 border-purple-500 flex justify-between items-center"
                >
                  <div>
                    <div className="flex items-center space-x-3 mb-2">
                      <span className="text-purple-400 font-mono font-bold">
                        #{issue.number}
                      </span>
                      <span className="px-2 py-0.5 rounded text-xs font-bold bg-purple-900/30 text-purple-300 border border-purple-700/50">
                        Aguardando Review
                      </span>
                    </div>
                    <h3 className="text-lg font-semibold text-slate-200 mb-1">
                      {issue.title}
                    </h3>
                    <p className="text-sm text-slate-500 line-clamp-1">
                      {issue.body
                        ? issue.body.substring(0, 100)
                        : "Sem descrição..."}
                    </p>
                  </div>

                  <button
                    onClick={() => setSelectedIssueId(issue.number)}
                    className="bg-slate-700 hover:bg-purple-600 text-white px-4 py-2 rounded shadow transition-all flex items-center space-x-2"
                  >
                    <span>Revisar Código</span>
                    <svg
                      className="w-4 h-4"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth="2"
                        d="M9 5l7 7-7 7"
                      ></path>
                    </svg>
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default TechnicalWorkbench;
