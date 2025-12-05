import React, { useState } from "react";
import {
  Zap,
  AlertCircle,
  RefreshCw,
  Target,
  TrendingUp,
  Activity,
  DollarSign,
  Layers,
  CheckCircle2,
  Clock,
} from "lucide-react";

const AnalysisTab = ({ API_BASE_URL, selectedPeriod }) => {
  const [analysisData, setAnalysisData] = useState(null);
  const [analyzing, setAnalyzing] = useState(false);
  const [analysisError, setAnalysisError] = useState(null);

  const runAnalysis = async () => {
    setAnalyzing(true);
    setAnalysisError(null);
    try {
      const response = await fetch(`${API_BASE_URL}/dashboard/analysis`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ period: selectedPeriod }),
      });
      if (!response.ok) throw new Error("Falha ao gerar análise.");
      const data = await response.json();
      setAnalysisData(data);
    } catch (err) {
      setAnalysisError(err.message);
    } finally {
      setAnalyzing(false);
    }
  };

  if (!analysisData && !analyzing) {
    return (
      <div className="bg-slate-800/50 p-12 rounded-xl text-center border border-slate-700 shadow-lg animate-in fade-in zoom-in duration-500">
        <div className="max-w-md mx-auto">
          <div className="w-20 h-20 bg-indigo-900/30 rounded-full flex items-center justify-center mx-auto mb-6 border border-indigo-500/30">
            <Zap size={40} className="text-indigo-400" />
          </div>
          <h3 className="text-2xl font-bold text-slate-100 mb-3">
            Análise Inteligente
          </h3>
          <p className="text-slate-400 mb-8 leading-relaxed">
            O Agente de BI utilizará Inteligência Artificial para analisar todos
            os indicadores operacionais e financeiros, identificando padrões,
            riscos e oportunidades de melhoria.
          </p>
          <button
            onClick={runAnalysis}
            className="px-8 py-4 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl font-bold text-lg shadow-lg shadow-indigo-900/20 transition-all transform hover:scale-105 flex items-center justify-center gap-3 mx-auto"
          >
            <Zap size={24} />
            Gerar Relatório Executivo
          </button>
        </div>
      </div>
    );
  }

  if (analyzing) {
    return (
      <div className="flex flex-col items-center justify-center h-96 animate-in fade-in duration-500">
        <div className="relative w-24 h-24 mb-8">
          <div className="absolute inset-0 border-4 border-slate-700 rounded-full"></div>
          <div className="absolute inset-0 border-4 border-indigo-500 rounded-full border-t-transparent animate-spin"></div>
          <Zap
            size={32}
            className="absolute inset-0 m-auto text-indigo-400 animate-pulse"
          />
        </div>
        <h3 className="text-xl font-semibold text-slate-200 mb-2">
          Analisando Dados...
        </h3>
        <p className="text-slate-500 max-w-md text-center">
          O Agente está correlacionando métricas operacionais e financeiras para
          gerar insights estratégicos.
        </p>
      </div>
    );
  }

  if (analysisError) {
    return (
      <div className="bg-red-900/20 border border-red-900/50 p-8 rounded-xl text-center animate-in fade-in">
        <AlertCircle size={48} className="mx-auto text-red-400 mb-4" />
        <h3 className="text-xl font-bold text-red-400 mb-2">Erro na Análise</h3>
        <p className="text-red-200 mb-6">{analysisError}</p>
        <button
          onClick={runAnalysis}
          className="px-6 py-2 bg-red-900/50 hover:bg-red-900/70 text-red-100 rounded-lg font-medium transition-colors border border-red-800"
        >
          Tentar Novamente
        </button>
      </div>
    );
  }

  // Renderização do Relatório
  const {
    sumario_executivo = {},
    analise_operacional = {},
    analise_financeira = {},
    correlacao_op_fin = [],
    insights_estrategicos = [],
    recomendacoes = [],
    previsoes = {},
  } = analysisData;

  return (
    <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
      {/* Header do Relatório */}
      <div className="flex justify-between items-center bg-slate-800 p-6 rounded-xl border border-slate-700 shadow-lg">
        <div>
          <h2 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <Zap size={24} className="text-amber-400" />
            Relatório Executivo de IA
          </h2>
          <p className="text-slate-400 text-sm mt-1">
            Gerado em {new Date().toLocaleString()}
          </p>
        </div>
        <button
          onClick={runAnalysis}
          className="text-indigo-400 hover:text-indigo-300 text-sm font-medium flex items-center gap-1"
        >
          <RefreshCw size={16} /> Atualizar
        </button>
      </div>

      {/* 1. Sumário Executivo */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-indigo-900/20 p-6 rounded-xl border border-indigo-500/30">
          <h3 className="text-indigo-300 font-semibold mb-3 flex items-center gap-2">
            <Target size={18} /> Principais Achados
          </h3>
          <ul className="space-y-2">
            {(sumario_executivo.principais_achados || []).map((item, i) => (
              <li
                key={i}
                className="text-slate-300 text-sm flex items-start gap-2"
              >
                <span className="mt-1.5 w-1.5 h-1.5 bg-indigo-500 rounded-full shrink-0"></span>
                {item}
              </li>
            ))}
          </ul>
        </div>
        <div className="bg-red-900/20 p-6 rounded-xl border border-red-500/30">
          <h3 className="text-red-300 font-semibold mb-3 flex items-center gap-2">
            <AlertCircle size={18} /> Pontos Críticos
          </h3>
          <ul className="space-y-2">
            {(sumario_executivo.indicadores_criticos || []).map((item, i) => (
              <li
                key={i}
                className="text-slate-300 text-sm flex items-start gap-2"
              >
                <span className="mt-1.5 w-1.5 h-1.5 bg-red-500 rounded-full shrink-0"></span>
                {item}
              </li>
            ))}
          </ul>
        </div>
        <div className="bg-emerald-900/20 p-6 rounded-xl border border-emerald-500/30">
          <h3 className="text-emerald-300 font-semibold mb-3 flex items-center gap-2">
            <TrendingUp size={18} /> Oportunidades
          </h3>
          <ul className="space-y-2">
            {(sumario_executivo.oportunidades_ganho || []).map((item, i) => (
              <li
                key={i}
                className="text-slate-300 text-sm flex items-start gap-2"
              >
                <span className="mt-1.5 w-1.5 h-1.5 bg-emerald-500 rounded-full shrink-0"></span>
                {item}
              </li>
            ))}
          </ul>
        </div>
      </div>

      {/* 2. Análises Detalhadas */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-slate-800/50 p-6 rounded-xl border border-slate-700">
          <h3 className="text-lg font-bold text-slate-200 mb-4 flex items-center gap-2">
            <Activity size={20} className="text-blue-400" /> Análise Operacional
          </h3>
          <div className="space-y-4 text-slate-300 text-sm leading-relaxed">
            <div>
              <strong className="text-blue-300 block mb-1">
                Produtividade:
              </strong>
              {analise_operacional.produtividade}
            </div>
            <div>
              <strong className="text-blue-300 block mb-1">
                Eficiência de Fluxo:
              </strong>
              {analise_operacional.eficiencia_fluxo}
            </div>
            <div>
              <strong className="text-blue-300 block mb-1">
                Qualidade e Riscos:
              </strong>
              {analise_operacional.qualidade_riscos}
            </div>
          </div>
        </div>

        <div className="bg-slate-800/50 p-6 rounded-xl border border-slate-700">
          <h3 className="text-lg font-bold text-slate-200 mb-4 flex items-center gap-2">
            <DollarSign size={20} className="text-green-400" /> Análise
            Financeira
          </h3>
          <div className="space-y-4 text-slate-300 text-sm leading-relaxed">
            <div>
              <strong className="text-green-300 block mb-1">
                Receita e Margens:
              </strong>
              {analise_financeira.receita_margens}
            </div>
            <div>
              <strong className="text-green-300 block mb-1">
                Rentabilidade:
              </strong>
              {analise_financeira.rentabilidade_clientes}
            </div>
            <div>
              <strong className="text-green-300 block mb-1">
                Riscos Financeiros:
              </strong>
              <ul className="list-disc list-inside pl-2">
                {(analise_financeira.riscos_financeiros || []).map((r, i) => (
                  <li key={i}>{r}</li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </div>

      {/* 3. Correlação e Insights */}
      <div className="bg-slate-800/50 p-6 rounded-xl border border-slate-700">
        <h3 className="text-lg font-bold text-slate-200 mb-4 flex items-center gap-2">
          <Layers size={20} className="text-purple-400" /> Correlação e
          Estratégia
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div>
            <h4 className="text-purple-300 font-semibold mb-3">
              Correlação Operacional x Financeiro
            </h4>
            <ul className="space-y-2">
              {(correlacao_op_fin || []).map((item, i) => (
                <li
                  key={i}
                  className="text-slate-300 text-sm flex items-start gap-2"
                >
                  <span className="mt-1.5 w-1.5 h-1.5 bg-purple-500 rounded-full shrink-0"></span>
                  {item}
                </li>
              ))}
            </ul>
          </div>
          <div>
            <h4 className="text-purple-300 font-semibold mb-3">
              Insights Estratégicos
            </h4>
            <ul className="space-y-2">
              {(insights_estrategicos || []).map((item, i) => (
                <li
                  key={i}
                  className="text-slate-300 text-sm flex items-start gap-2"
                >
                  <span className="mt-1.5 w-1.5 h-1.5 bg-purple-500 rounded-full shrink-0"></span>
                  {item}
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>

      {/* 4. Recomendações */}
      <div>
        <h3 className="text-lg font-bold text-slate-200 mb-4 flex items-center gap-2">
          <CheckCircle2 size={20} className="text-teal-400" /> Plano de Ação
          Recomendado
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {(recomendacoes || []).map((rec, i) => (
            <div
              key={i}
              className="bg-slate-800 p-4 rounded-lg border border-slate-700 hover:border-teal-500/50 transition-colors"
            >
              <div className="flex justify-between items-start mb-2">
                <h4 className="font-bold text-slate-200">{rec.titulo}</h4>
                <span
                  className={`text-xs px-2 py-1 rounded font-bold ${
                    rec.prioridade === "Alta"
                      ? "bg-red-900/50 text-red-300 border border-red-800"
                      : rec.prioridade === "Média"
                      ? "bg-amber-900/50 text-amber-300 border border-amber-800"
                      : "bg-blue-900/50 text-blue-300 border border-blue-800"
                  }`}
                >
                  {rec.prioridade}
                </span>
              </div>
              <p className="text-slate-400 text-sm mb-3">{rec.descricao}</p>
              <div className="flex items-center gap-2 text-xs text-slate-500">
                <Clock size={12} /> Prazo: {rec.prazo}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default AnalysisTab;
