import React, { useState } from "react";
import { Bot, Play, AlertTriangle, CheckCircle, FileText } from "lucide-react";
import { API_BASE_URL } from "../config";

// Mock Data to send to API (same as Dashboard for consistency)
const currentIndicators = {
  mrr: "€ 45.000",
  tcv: "€ 120.000",
  ticket_medio: "€ 15.000",
  revenue_backlog: "€ 200.000",
  conversion_rate: "12%",
  win_rate: "18%",
  sales_cycle: "4.5 meses",
  lead_qualification_rate: "35%",
  cac: "€ 2.500",
  ltv: "€ 35.000",
  margin: "28%",
  churn_rate: "2.5%",
  nps: "72",
};

const CommercialAnalysis = () => {
  const [analysis, setAnalysis] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleRunAnalysis = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch(`${API_BASE_URL}/commercial/analyze`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(currentIndicators),
      });

      if (!response.ok) {
        throw new Error("Falha ao gerar análise");
      }

      const data = await response.json();
      setAnalysis(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-4xl mx-auto">
      <div className="bg-gray-800 rounded-lg border border-gray-700 p-6 mb-6">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h2 className="text-xl font-bold text-white flex items-center gap-2">
              <Bot className="text-purple-400" /> Agente Comercial IA
            </h2>
            <p className="text-gray-400 text-sm mt-1">
              Analisa seus indicadores atuais para gerar insights estratégicos e
              planos de ação.
            </p>
          </div>
          <button
            onClick={handleRunAnalysis}
            disabled={loading}
            className={`flex items-center gap-2 px-6 py-3 rounded-lg font-medium transition-colors ${
              loading
                ? "bg-gray-600 cursor-not-allowed text-gray-300"
                : "bg-purple-600 hover:bg-purple-700 text-white"
            }`}
          >
            {loading ? (
              "Analisando..."
            ) : (
              <>
                <Play size={18} /> Gerar Análise Estratégica
              </>
            )}
          </button>
        </div>

        {error && (
          <div className="bg-red-900/30 border border-red-800 text-red-200 p-4 rounded-lg flex items-center gap-2">
            <AlertTriangle size={20} />
            {error}
          </div>
        )}
      </div>

      {analysis && (
        <div className="space-y-6 animate-fade-in">
          {/* Resumo Executivo */}
          <div className="bg-gray-800 rounded-lg border border-gray-700 p-6">
            <h3 className="text-lg font-semibold text-white mb-3 flex items-center gap-2">
              <FileText className="text-blue-400" /> Resumo Executivo
            </h3>
            <p className="text-gray-300 leading-relaxed">
              {analysis.resumo_executivo}
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Pontos Fortes */}
            <div className="bg-gray-800 rounded-lg border border-green-900/50 p-6">
              <h3 className="text-lg font-semibold text-green-400 mb-4 flex items-center gap-2">
                <CheckCircle size={20} /> Pontos Fortes
              </h3>
              <ul className="space-y-2">
                {analysis.pontos_fortes.map((item, index) => (
                  <li
                    key={index}
                    className="flex items-start gap-2 text-gray-300"
                  >
                    <span className="mt-1.5 w-1.5 h-1.5 bg-green-500 rounded-full shrink-0" />
                    {item}
                  </li>
                ))}
              </ul>
            </div>

            {/* Pontos de Atenção */}
            <div className="bg-gray-800 rounded-lg border border-yellow-900/50 p-6">
              <h3 className="text-lg font-semibold text-yellow-400 mb-4 flex items-center gap-2">
                <AlertTriangle size={20} /> Pontos de Atenção
              </h3>
              <ul className="space-y-2">
                {analysis.pontos_atencao.map((item, index) => (
                  <li
                    key={index}
                    className="flex items-start gap-2 text-gray-300"
                  >
                    <span className="mt-1.5 w-1.5 h-1.5 bg-yellow-500 rounded-full shrink-0" />
                    {item}
                  </li>
                ))}
              </ul>
            </div>
          </div>

          {/* Análise Detalhada */}
          <div className="bg-gray-800 rounded-lg border border-gray-700 p-6">
            <h3 className="text-lg font-semibold text-white mb-3">
              Análise Detalhada
            </h3>
            <div className="prose prose-invert max-w-none text-gray-300">
              <p>{analysis.analise_detalhada}</p>
            </div>
          </div>

          {/* Recomendações */}
          <div className="bg-gradient-to-r from-purple-900/20 to-blue-900/20 rounded-lg border border-purple-500/30 p-6">
            <h3 className="text-lg font-semibold text-white mb-4">
              🚀 Plano de Ação Recomendado
            </h3>
            <div className="grid gap-4">
              {analysis.recomendacoes_acao.map((action, index) => (
                <div
                  key={index}
                  className="bg-gray-800/50 p-4 rounded border border-gray-700 flex gap-4"
                >
                  <div className="bg-purple-600/20 text-purple-400 w-8 h-8 rounded-full flex items-center justify-center font-bold shrink-0">
                    {index + 1}
                  </div>
                  <p className="text-gray-200">{action}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default CommercialAnalysis;
