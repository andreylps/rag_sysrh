// src/pages/ValidationBacklog.jsx

import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom"; // Para navegar para a tela de detalhes no futuro
import { API_BASE_URL } from "../config";

const ValidationBacklog = () => {
  const [issues, setIssues] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const navigate = useNavigate();

  // --- NOVOS ESTADOS PARA HISTÓRICO ---
  const [activeTab, setActiveTab] = useState("pending"); // 'pending' ou 'history'
  const [historyIssues, setHistoryIssues] = useState([]);
  const [loadingHistory, setLoadingHistory] = useState(false);

  // Busca o histórico quando a aba é ativada
  useEffect(() => {
    if (activeTab === "history" && historyIssues.length === 0) {
      fetchHistory();
    }
  }, [activeTab]);

  const fetchHistory = async () => {
    setLoadingHistory(true);
    try {
      const response = await fetch(`${API_BASE_URL}/validacao/history`);
      if (!response.ok) throw new Error("Erro ao buscar histórico");
      const data = await response.json();
      setHistoryIssues(data);
    } catch (error) {
      console.error("Erro no histórico:", error);
      // toast.error("Não foi possível carregar o histórico."); // Se tiver toast
    } finally {
      setLoadingHistory(false);
    }
  };

  // Busca os dados do backlog ao carregar a página
  useEffect(() => {
    fetchBacklog();
  }, []);

  const fetchBacklog = async () => {
    setLoading(true);
    try {
      // Chama o endpoint que acabamos de testar com sucesso
      const response = await fetch(`${API_BASE_URL}/validacao/backlog`);

      if (!response.ok) {
        throw new Error(`Erro na requisição: ${response.status}`);
      }

      const data = await response.json();
      setIssues(data);
      setError(null);
    } catch (err) {
      console.error("Falha ao buscar backlog:", err);
      setError(
        "Não foi possível carregar o backlog de validação. Verifique a conexão com o servidor."
      );
    } finally {
      setLoading(false);
    }
  };

  // Função temporária para o botão de ação

  const handleOpenValidation = (issueNumber) => {
    // Agora navegamos para o Workbench real!
    navigate(`/validacao/${issueNumber}`);
  };

  // Formata a data para um formato mais amigável (DD/MM/AAAA)
  const formatDate = (dateString) => {
    try {
      const options = { day: "2-digit", month: "2-digit", year: "numeric" };
      return new Date(dateString).toLocaleDateString("pt-BR", options);
    } catch (e) {
      return dateString;
    }
  };

  return (
    <div className="page-content">
      <header className="page-header flex justify-between items-center">
        <div>
          <h1>📋 Backlog de Validação</h1>
          <p>Demandas analisadas pela IA aguardando revisão humana.</p>
        </div>
        <button
          onClick={fetchBacklog}
          className="bg-slate-800 hover:bg-slate-700 text-slate-300 font-bold py-2 px-4 rounded shadow flex items-center transition-colors text-sm border border-slate-700"
          title="Recarregar lista"
        >
          {/* Ícone de Refresh */}
          <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            strokeWidth={1.5}
            stroke="currentColor"
            className="w-5 h-5 mr-2"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99"
            />
          </svg>
          Atualizar
        </button>
      </header>

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
          Pendentes
        </button>
        <button
          onClick={() => setActiveTab("history")}
          className={`pb-2 px-4 font-medium transition-colors ${
            activeTab === "history"
              ? "text-cyan-400 border-b-2 border-cyan-400"
              : "text-slate-400 hover:text-slate-200"
          }`}
        >
          Histórico
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
            <div className="card overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-slate-300">
                  <thead className="text-xs uppercase bg-slate-900/50 text-slate-400 border-b border-slate-800">
                    <tr>
                      <th scope="col" className="px-6 py-4 w-24">
                        ID
                      </th>
                      <th scope="col" className="px-6 py-4">
                        Título
                      </th>
                      <th scope="col" className="px-6 py-4 w-32 text-center">
                        Data
                      </th>
                      <th scope="col" className="px-6 py-4 w-32 text-center">
                        Status
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800">
                    {historyIssues.length === 0 ? (
                      <tr>
                        <td
                          colSpan="4"
                          className="px-6 py-8 text-center text-slate-500"
                        >
                          Nenhum histórico encontrado.
                        </td>
                      </tr>
                    ) : (
                      historyIssues.map((issue) => (
                        <tr
                          key={issue.number}
                          className="hover:bg-slate-800/30 transition-colors"
                        >
                          <td className="px-6 py-4 font-mono text-cyan-400">
                            <a
                              href={issue.html_url}
                              target="_blank"
                              rel="noreferrer"
                              className="hover:underline"
                            >
                              #{issue.number}
                            </a>
                          </td>
                          <td className="px-6 py-4 font-medium">
                            {issue.title}
                            <div className="flex flex-wrap gap-2 mt-1">
                              {issue.labels &&
                                issue.labels.map((label) => (
                                  <span
                                    key={label}
                                    className="text-[10px] px-1.5 py-0.5 rounded bg-slate-700 text-slate-400 border border-slate-600"
                                  >
                                    {label}
                                  </span>
                                ))}
                            </div>
                          </td>
                          <td className="px-6 py-4 text-center text-sm text-slate-400">
                            {formatDate(issue.closed_at || issue.updated_at)}
                          </td>
                          <td className="px-6 py-4 text-center">
                            {(() => {
                              const labels = issue.labels || [];
                              const lowerLabels = labels.map((l) =>
                                l.toLowerCase()
                              );
                              let statusText = "Finalizado";
                              let statusClass =
                                "bg-slate-700 text-slate-300 border-slate-600";

                              if (issue.state === "closed") {
                                if (
                                  lowerLabels.some(
                                    (l) =>
                                      l.includes("validado") ||
                                      l.includes("deploy")
                                  )
                                ) {
                                  statusText = "Concluído";
                                  statusClass =
                                    "bg-green-900/30 text-green-300 border-green-700/50";
                                } else {
                                  statusText = "Fechado/Recusado";
                                  statusClass =
                                    "bg-red-900/30 text-red-300 border-red-700/50";
                                }
                              } else {
                                if (
                                  lowerLabels.some((l) =>
                                    l.includes("aguardando-aprovacao-cliente")
                                  )
                                ) {
                                  statusText = "Aguardando Cliente";
                                  statusClass =
                                    "bg-blue-900/30 text-blue-300 border-blue-700/50";
                                } else if (
                                  lowerLabels.some((l) =>
                                    l.includes("validado")
                                  )
                                ) {
                                  statusText = "Validado";
                                  statusClass =
                                    "bg-emerald-900/30 text-emerald-300 border-emerald-700/50";
                                } else if (
                                  lowerLabels.some((l) =>
                                    l.includes("fast-track")
                                  )
                                ) {
                                  statusText = "Fast Track";
                                  statusClass =
                                    "bg-yellow-900/30 text-yellow-300 border-yellow-700/50";
                                } else {
                                  statusText = "Em Andamento";
                                  statusClass =
                                    "bg-slate-700 text-slate-300 border-slate-600";
                                }
                              }

                              return (
                                <span
                                  className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${statusClass}`}
                                >
                                  {statusText}
                                </span>
                              );
                            })()}
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      )}

      {activeTab === "pending" && (
        <>
          {loading ? (
            // Estado de Carregamento (Skeleton ou Spinner)
            <div className="flex justify-center items-center h-64 card">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-cyan-500"></div>
            </div>
          ) : error ? (
            // Estado de Erro
            <div className="card bg-red-900/20 border-red-900 text-red-400 p-6 text-center">
              <h3 className="font-bold text-lg mb-2">Erro ao carregar</h3>
              <p>{error}</p>
              <button
                onClick={fetchBacklog}
                className="mt-4 underline hover:text-red-300"
              >
                Tentar novamente
              </button>
            </div>
          ) : issues.length === 0 ? (
            // Estado de Lista Vazia
            <div className="card p-8 text-center text-slate-500">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={1.5}
                stroke="currentColor"
                className="w-16 h-16 mx-auto mb-4 opacity-50"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0z"
                />
              </svg>
              <h3 className="font-bold text-lg text-slate-300">Tudo limpo!</h3>
              <p>Não há demandas pendentes de validação no momento.</p>
            </div>
          ) : (
            // Tabela de Dados (Backlog)
            <div className="card overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-slate-300">
                  <thead className="text-xs uppercase bg-slate-900/50 text-slate-400 border-b border-slate-800">
                    <tr>
                      <th scope="col" className="px-6 py-4 w-24">
                        ID
                      </th>
                      <th scope="col" className="px-6 py-4">
                        Título
                      </th>
                      <th scope="col" className="px-6 py-4 w-32 text-center">
                        Data
                      </th>
                      <th scope="col" className="px-6 py-4 w-32 text-center">
                        Ação
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800">
                    {issues.map((issue) => (
                      <tr
                        key={issue.github_id}
                        className="hover:bg-slate-800/30 transition-colors"
                      >
                        <td className="px-6 py-4 font-mono text-cyan-400">
                          <a
                            href={issue.html_url}
                            target="_blank"
                            rel="noreferrer"
                            className="hover:underline"
                            title="Abrir no GitHub"
                          >
                            #{issue.number}
                          </a>
                        </td>
                        <td className="px-6 py-4 font-medium">
                          <a
                            href={issue.html_url}
                            target="_blank"
                            rel="noreferrer"
                            className="hover:underline hover:text-cyan-400 transition-colors"
                          >
                            {issue.title}
                          </a>
                          {/* Exibe todas as labels com cores dinâmicas */}
                          <div className="flex flex-wrap gap-2 mt-1">
                            {issue.labels.map((label) => {
                              let colorClass = "bg-slate-700 text-slate-300"; // Default
                              const lowerLabel = label.toLowerCase();

                              if (
                                lowerLabel.includes("aguardando-validacao") ||
                                lowerLabel.includes("aguardando-review")
                              ) {
                                colorClass =
                                  "bg-orange-900/50 text-orange-300 border border-orange-800";
                              } else if (
                                lowerLabel.includes("validado") ||
                                lowerLabel.includes("aprovado")
                              ) {
                                colorClass =
                                  "bg-green-900/50 text-green-300 border border-green-800";
                              } else if (lowerLabel.includes("evolutiva")) {
                                colorClass =
                                  "bg-blue-900/50 text-blue-300 border border-blue-800";
                              } else if (lowerLabel.includes("rcm-rejeitada")) {
                                colorClass =
                                  "bg-red-900/50 text-red-300 border border-red-800 font-bold animate-pulse";
                                label = "⚠️ Rejeitado pelo Cliente"; // Override text for clarity
                              } else if (
                                lowerLabel.includes("fast-track") ||
                                lowerLabel.includes("liberacao-dev")
                              ) {
                                colorClass =
                                  "bg-yellow-900/50 text-yellow-300 border border-yellow-800 font-medium";
                                label = "⚡ Fast Track"; // Add icon for emphasis
                              }

                              return (
                                <span
                                  key={label}
                                  className={`text-xs px-2 py-0.5 rounded-full ${colorClass}`}
                                >
                                  {label}
                                </span>
                              );
                            })}
                          </div>
                        </td>
                        <td className="px-6 py-4 text-sm text-slate-400 text-center whitespace-nowrap">
                          {formatDate(issue.created_at)}
                        </td>
                        <td className="px-6 py-4 text-center">
                          <button
                            onClick={() => handleOpenValidation(issue.number)}
                            className="bg-cyan-600 hover:bg-cyan-700 text-white font-bold py-2 px-4 rounded shadow transition-colors text-sm flex items-center mx-auto"
                          >
                            <svg
                              xmlns="http://www.w3.org/2000/svg"
                              fill="none"
                              viewBox="0 0 24 24"
                              strokeWidth={2}
                              stroke="currentColor"
                              className="w-4 h-4 mr-2"
                            >
                              <path
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                d="M13.5 6H5.25A2.25 2.25 0 0 0 3 8.25v10.5A2.25 2.25 0 0 0 5.25 21h10.5A2.25 2.25 0 0 0 18 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25"
                              />
                            </svg>
                            Validar
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
};

export default ValidationBacklog;
