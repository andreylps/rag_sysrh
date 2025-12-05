import React from "react";
import { API_BASE_URL } from "../config";

const HistoryTable = ({ issues, onIssueUpdate }) => {
  if (!issues || issues.length === 0) {
    return (
      <div className="text-center p-8 text-slate-500 bg-slate-800/30 rounded-lg border border-slate-700 border-dashed">
        <p>Nenhum histórico encontrado.</p>
      </div>
    );
  }

  // Função para formatar data
  const formatDate = (dateString) => {
    if (!dateString) return "N/A";
    try {
      const date = new Date(dateString);
      return date.toLocaleDateString("pt-BR", {
        day: "2-digit",
        month: "2-digit",
        year: "numeric",
      });
    } catch (e) {
      return dateString;
    }
  };

  return (
    <div className="overflow-x-auto rounded-lg border border-slate-700">
      <table className="w-full text-left text-sm text-slate-400">
        <thead className="bg-slate-900/50 text-xs uppercase text-slate-300 font-medium">
          <tr>
            <th scope="col" className="px-6 py-3">
              ID
            </th>
            <th scope="col" className="px-6 py-3">
              Título
            </th>
            <th scope="col" className="px-6 py-3 text-center">
              Fechado em
            </th>
            <th scope="col" className="px-6 py-3 text-center">
              Status
            </th>
            <th scope="col" className="px-6 py-3 text-center">
              Homologação
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-800 bg-slate-800/20">
          {issues.map((issue) => (
            <tr
              key={issue.number}
              className="hover:bg-slate-700/30 transition-colors"
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
              <td className="px-6 py-4 font-medium text-slate-200">
                {issue.title}
                <div className="flex flex-wrap gap-1 mt-1">
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
              <td className="px-6 py-4 text-center">
                {formatDate(issue.closed_at || issue.updated_at)}
              </td>
              <td className="px-6 py-4 text-center">
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-900/30 text-purple-300 border border-purple-700/50">
                  {issue.state === "closed" ? "Fechado" : issue.state}
                </span>
              </td>
              <td className="px-6 py-4 text-center">
                {issue.labels &&
                issue.labels.includes("status:aceite-homologacao") ? (
                  <button
                    onClick={async () => {
                      if (
                        window.confirm(
                          "Confirmar homologação? A issue será fechada."
                        )
                      ) {
                        try {
                          const response = await fetch(
                            `${API_BASE_URL}/review/${issue.number}/homologate`,
                            { method: "POST" }
                          );
                          if (response.ok) {
                            if (onIssueUpdate) {
                              onIssueUpdate();
                            } else {
                              window.location.reload();
                            }
                          } else {
                            alert("Erro ao homologar.");
                          }
                        } catch (e) {
                          console.error(e);
                          alert("Erro de conexão.");
                        }
                      }
                    }}
                    className="inline-flex items-center px-3 py-1 rounded text-xs font-bold bg-orange-600 hover:bg-orange-500 text-white transition-colors shadow-lg animate-pulse"
                    title="Clique para Homologar"
                  >
                    OK
                  </button>
                ) : issue.state === "closed" ||
                  (issue.labels &&
                    issue.labels.includes("status:homologado")) ? (
                  <span className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-green-500/20 text-green-400 border border-green-500/50">
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                      strokeWidth={2}
                      stroke="currentColor"
                      className="w-4 h-4"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        d="m4.5 12.75 6 6 9-13.5"
                      />
                    </svg>
                  </span>
                ) : (
                  <span className="text-slate-600">-</span>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default HistoryTable;
