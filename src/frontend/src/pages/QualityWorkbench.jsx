import React, { useState, useEffect } from "react";
import { AlertCircle } from "lucide-react";
import { API_BASE_URL } from "../config";

const QualityWorkbench = () => {
  const [alerts, setAlerts] = useState([]);
  const [loadingAlerts, setLoadingAlerts] = useState(true);

  useEffect(() => {
    fetchAlerts();
  }, []);

  const fetchAlerts = async () => {
    setLoadingAlerts(true);
    try {
      const response = await fetch(
        `${API_BASE_URL}/quality/alerts`
      );
      if (response.ok) {
        const data = await response.json();
        setAlerts(data);
      } else {
        console.error("Erro ao buscar alertas de qualidade");
      }
    } catch (error) {
      console.error("Erro de conexão ao buscar alertas:", error);
    } finally {
      setLoadingAlerts(false);
    }
  };

  // Função auxiliar para formatar data
  const formatTime = (isoString) => {
    if (!isoString) return "";
    return new Date(isoString).toLocaleTimeString("pt-BR", {
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  return (
    <div className="page-content max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <header className="mb-8">
        <h1 className="text-3xl font-bold text-slate-100 flex items-center gap-3">
          Sala de Controle de Qualidade 🛡️
        </h1>
        <p className="mt-2 text-slate-400 text-lg">
          Bem-vindo à Sala de Controle de Qualidade. Aqui você encontrará
          monitoramento de gargalos, auditorias de conformidade (incluindo
          manuais operacionais), e métricas para a melhoria contínua.
        </p>
      </header>

      {/* --- SEÇÃO DE ALERTAS ATIVOS --- */}
      <section className="mb-8">
        <h2 className="text-xl font-semibold text-slate-200 mb-4 flex items-center gap-2">
          <AlertCircle className="text-orange-400" size={24} />
          Alertas Ativos de Qualidade
        </h2>

        {loadingAlerts ? (
          <div className="text-slate-500 italic">Carregando alertas...</div>
        ) : alerts.length === 0 ? (
          <div className="bg-green-900/20 border border-green-800 p-4 rounded-lg text-green-300 flex items-center gap-3">
            <div className="bg-green-900/50 p-2 rounded-full">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={1.5}
                stroke="currentColor"
                className="w-6 h-6"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0z"
                />
              </svg>
            </div>
            <span>
              Nenhum alerta de qualidade ativo no momento. Tudo certo!
            </span>
          </div>
        ) : (
          <div className="grid gap-4">
            {alerts.map((alert, index) => (
              <div
                key={index}
                className="bg-red-900/20 border-l-4 border-red-500 p-4 rounded-r-lg flex justify-between items-start"
              >
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-red-400 font-bold text-sm uppercase tracking-wider">
                      {alert.category.replace("_", " ")}
                    </span>
                    <span className="text-slate-500 text-xs">
                      • {formatTime(alert.timestamp)}
                    </span>
                  </div>
                  <p className="text-slate-200">{alert.message}</p>
                </div>
                {alert.issue_number && (
                  <a
                    href={`https://github.com/andreylps/rag_sysrh/issues/${alert.issue_number}`}
                    target="_blank"
                    rel="noreferrer"
                    className="text-sm bg-slate-800 hover:bg-slate-700 text-slate-300 px-3 py-1 rounded transition-colors"
                  >
                    Ver Issue #{alert.issue_number}
                  </a>
                )}
              </div>
            ))}
          </div>
        )}
      </section>

      {/* Placeholder content for future widgets */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div className="card p-6 border border-slate-700 bg-slate-800/50 rounded-lg">
          <h3 className="text-xl font-semibold text-slate-200 mb-2">
            Monitoramento de Gargalos
          </h3>
          <p className="text-slate-500">
            Em breve: Visualização de gargalos no fluxo de trabalho.
          </p>
        </div>
        <div className="card p-6 border border-slate-700 bg-slate-800/50 rounded-lg">
          <h3 className="text-xl font-semibold text-slate-200 mb-2">
            Auditorias de Conformidade
          </h3>
          <p className="text-slate-500">
            Em breve: Relatórios de conformidade com manuais operacionais.
          </p>
        </div>
        <div className="card p-6 border border-slate-700 bg-slate-800/50 rounded-lg">
          <h3 className="text-xl font-semibold text-slate-200 mb-2">
            Métricas de Melhoria
          </h3>
          <p className="text-slate-500">
            Em breve: KPIs e indicadores de qualidade.
          </p>
        </div>
      </div>
    </div>
  );
};

export default QualityWorkbench;
